import SwiftUI
import SwiftUISugar
import SwiftHaptics
import PrepDataTypes
import PrepCoreDataStack

public struct GoalSetForm: View {
        
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @StateObject var model: Model
//    @StateObject var model: Model
    
    @State var showingNutrientsPicker: Bool = false
    @State var showingEmojiPicker = false
    
    @State var showingEquivalentValuesToggle: Bool
    @State var showingEquivalentValues = false

    @FocusState var isFocused: Bool
    
    @State var showingSaveButton: Bool

    let didTapSave: (GoalSet, Biometrics?, Bool) -> ()

    @State var showingNameForm: Bool = false
    
    @State var showingEditConfirmation: Bool = false
    @State var numberOfPreviousUses: Int = 0
    @State var showingDuplicateAlert = false
    
    //TODO: Use user's units here
    public init(
        type: GoalSetType,
        existingGoalSet: GoalSet? = nil,
        isDuplicating: Bool = false,
        userUnits: UserOptions.Units,
        biometrics: Biometrics? = nil,
        didTapSave: @escaping (GoalSet, Biometrics?, Bool) -> ()
    ) {
        let model = Model(
            userUnits: userUnits,
            type: type,
            existingGoalSet: existingGoalSet,
            isDuplicating: isDuplicating,
            biometrics: biometrics
        )
        _model = StateObject(wrappedValue: model)
        _showingEquivalentValuesToggle = State(initialValue: model.containsGoalWithEquivalentValues)
        self.didTapSave = didTapSave
        
        _showingSaveButton = State(initialValue: isDuplicating)
    }
    
    public var body: some View {
        NavigationStack(path: $model.path) {
            content
            .background(Color(.systemGroupedBackground))
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar { trailingContent }
            .navigationDestination(for: GoalSetFormRoute.self, destination: navigationDestination)
            .scrollDismissesKeyboard(.interactively)
            .onAppear(perform: appeared)
            .onChange(of: model.containsGoalWithEquivalentValues, perform: containsGoalWithEquivalentValuesChanged)
            .onChange(of: canBeSaved, perform: canBeSavedChanged)
            .onChange(of: model.singleGoalModelToPushTo, perform: singleGoalModelToPushTo)
            .confirmationDialog(
                editConfirmationTitle,
                isPresented: $showingEditConfirmation,
                titleVisibility: .visible,
                actions: editConfirmationActions
            )
            .alert(isPresented: $showingDuplicateAlert) { duplicateAlert }
            .sheet(isPresented: $showingNutrientsPicker) { nutrientsPicker }
            .sheet(isPresented: $showingEmojiPicker) { emojiPicker }
            .sheet(isPresented: $showingNameForm) { nameForm }
        }
    }
    
    var duplicateAlert: Alert {
        Alert(
            title: Text("Existing \(model.type.description)"),
            message: Text("Please choose a different name than ‘\(model.name)’, as this one has already been used."),
            dismissButton: .default(Text("OK"))
        )
    }
    
    var editConfirmationTitle: String {
        "This \(model.type.description) has been used \(numberOfPreviousUses) times. Are you sure you want to modify all of them?"
    }
    
    @ViewBuilder
    func editConfirmationActions() -> some View {
        Button("Save") {
            saveAndDismiss()
        }
//        Button("Past and Future Uses") {
//            saveAndDismiss(overwritingPreviousUses: true)
//        }
    }

    var nameForm: some View {
        NameForm(name: $model.name )
    }
    
    func singleGoalModelToPushTo(to goalModel: GoalModel?) {
        guard let goalModel else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isFocused = false
            model.path.append(.goal(goalModel))
        }
    }
    
    func canBeSavedChanged(to newValue: Bool) {
        withAnimation {
            showingSaveButton = newValue
        }
    }

    func containsGoalWithEquivalentValuesChanged(to newValue: Bool) {
        withAnimation {
            showingEquivalentValuesToggle = newValue
        }
    }
    
    @ViewBuilder
    func navigationDestination(for route: GoalSetFormRoute) -> some View {
        switch route {
        case .goal(let goalModel):
            goalForm(for: goalModel)
        }
    }
    
    var title: String {
        let typeName = model.type.description
        let prefix: String
        if model.existingGoalSet == nil {
            prefix = "New"
        } else {
            prefix = model.isDuplicating ? "New" : "Edit"
        }
        return "\(prefix) \(typeName)"
    }
    
    var content: some View {
        ZStack {
            scrollView
            buttonLayer
            wizardLayer
        }
    }
    
    @ViewBuilder
    var wizardLayer: some View {
        Wizard(
            isPresented: $model.showingWizard,
            type: model.type,
            tapHandler: tappedWizardButton
        )
    }
    
    func tappedWizardButton(_ action: Wizard.Action) {
        switch action {
        case .template(let goalSet):
            withAnimation {
                fillTemplate(goalSet)
            }
            Haptics.successFeedback()
            break
        case .empty, .background:
            break
        case .dismiss:
            dismiss()
            return
        }
        
        dismissWizard()
    }
    
    func fillTemplate(_ goalSet: GoalSet) {
        model.name = goalSet.name
        model.emoji = goalSet.emoji
        model.goalModels = goalSet.goals.map {
            GoalModel(
                goalSet: model,
                goalSetType: model.type,
                type: $0.type,
                lowerBound: $0.lowerBound,
                upperBound: $0.upperBound
            )
        }
    }
    
    @ViewBuilder
    var overlay: some View {
        if model.showingWizardOverlay {
            Color(.quaternarySystemFill)
                .opacity(model.showingWizardOverlay ? 0.3 : 0)
        }
    }

    func dismissWizard() {
        withAnimation(WizardAnimation) {
            model.showingWizard = false
        }
        withAnimation(.easeOut(duration: 0.1)) {
            model.showingWizardOverlay = false
        }
        model.formDisabled = false
    }

    func appeared() {
        if model.shouldShowWizard {
            withAnimation(WizardAnimation) {
                model.formDisabled = true
                model.showingWizard = true
                model.shouldShowWizard = false
            }
        } else {
            model.showingWizard = false
            model.showingWizardOverlay = false
            model.formDisabled = false
        }
    }
    
    var scrollView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                detailsCell
                titleCell("Goals")
                emptyContent
                energyCell
                macroCells
                microCells
                footerInfoContent
            }
            .padding(.horizontal, 20)
        }
        .safeAreaInset(edge: .bottom) { safeAreaInset }
        .overlay(overlay)
        .blur(radius: model.showingWizardOverlay ? 5 : 0)
        .disabled(model.formDisabled)
    }
    
    @ViewBuilder
    var safeAreaInset: some View {
        if showingSaveButton {
            Spacer()
                .frame(height: 100)
        }
    }

    var addHeroButton: some View {
        var label: some View {
            Image(systemName: "plus")
                .font(.system(size: 25))
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(
                    ZStack {
                        Circle()
                            .foregroundStyle(Color.accentColor.gradient)
                    }
                    .shadow(color: Color(.black).opacity(0.2), radius: 3, x: 0, y: 3)
                )
        }
        
        var button: some View {
            Button {
                Haptics.feedback(style: .soft)
                presentNutrientsPicker()
            } label: {
                label
            }
        }
        
        return ZStack {
            label
            button
        }
    }

    var buttonLayer: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                if !model.goalModels.isEmpty {
                    addHeroButton
                        .transition(.move(edge: .trailing))
                }
            }
            .padding(.horizontal, 20)
            if showingSaveButton {
                saveButton
                    .transition(.move(edge: .bottom))
            }
        }
        .padding(.bottom, 34)
        .edgesIgnoringSafeArea(.bottom)
    }
    
    var canBeSaved: Bool {
        model.shouldShowSaveButton
    }
    
    func tappedSave() {
        
        if !model.isEditing || model.isDuplicating {
            guard !DataManager.shared.hasGoalSet(named: model.name, type: model.type) else {
                showingDuplicateAlert = true
                return
            }
        }
        
        if model.isEditing,
           let existing = model.existingGoalSet
        {
            self.numberOfPreviousUses = DataManager.shared.numberOfNonDeletedUsesForGoalSet(existing)
            if numberOfPreviousUses > 0 {
                Haptics.warningFeedback()
                showingEditConfirmation = true
            } else {
                saveAndDismiss()
            }
        } else {
            saveAndDismiss()
        }
    }
    
    func saveAndDismiss(overwritingPreviousUses: Bool = false) {
        didTapSave(model.goalSet, model.biometrics, overwritingPreviousUses)
        dismiss()
    }

    var saveButton: some View {
        var saveButton: some View {
            FormPrimaryButton(title: "Save") {
                tappedSave()
            }
        }
        
        return VStack(spacing: 0) {
            Divider()
            VStack {
                saveButton
                    .padding(.vertical)
            }
        }
        .background(.thinMaterial)
    }
    
    
    @ViewBuilder
    var energyCell: some View {
        if let goal = model.energyGoal {
            cell(for: goal)
        } else if let index = model.implicitEnergyGoalIndex {
            cell(for: model.implicitGoals[index], isButton: false)
        }
    }

    @ViewBuilder
    var carbCell: some View {
        if let goal = model.carbGoal {
            cell(for: goal)
        } else if let index = model.implicitMacroGoalIndex(for: .carb) {
            cell(for: model.implicitGoals[index], isButton: false)
        }
    }
    @ViewBuilder
    var fatCell: some View {
        if let goal = model.fatGoal {
            cell(for: goal)
        } else if let index = model.implicitMacroGoalIndex(for: .fat) {
            cell(for: model.implicitGoals[index], isButton: false)
        }
    }
    @ViewBuilder
    var proteinCell: some View {
        if let goal = model.proteinGoal {
            cell(for: goal)
        } else if let index = model.implicitMacroGoalIndex(for: .protein) {
            cell(for: model.implicitGoals[index], isButton: false)
        }
    }

    
    func cell(for goalModel: GoalModel, isButton: Bool = true) -> some View {
        var label: some View {
            GoalCell(
                goal: goalModel,
                showingEquivalentValues: $showingEquivalentValues
            )
        }
        return Group {
            if isButton {
                Button {
                    isFocused = false
                    model.path.append(.goal(goalModel))
                } label: {
                    label
                }
            } else {
                label
            }
        }
    }
        
    @ViewBuilder
    var macroCells: some View {
        if !model.macroGoals.isEmpty {
            Group {
                subtitleCell("Macros")
                carbCell
                fatCell
                proteinCell
//                ForEach(model.macroGoals, id: \.self) {
//                    cell(for: $0)
//                }
            }
        }
    }
    
    @ViewBuilder
    var microCells: some View {
        if !model.microGoals.isEmpty {
            Group {
                subtitleCell("Micronutrients")
                ForEach(model.microGoals, id: \.self) {
                    cell(for: $0)
                }
            }
        }
    }
    
    var detailsCell: some View {
        var label: some View {
            HStack {
                emojiButton
                Group {
                    if model.name.isEmpty {
                        Text("Enter a name")
                            .foregroundColor(Color(.tertiaryLabel))
                    } else {
                        Text(model.name)
                            .foregroundColor(.primary)
                    }
                }
                .font(.title3)
                .multilineTextAlignment(.leading)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 13)
            .padding(.top, 13)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(10)
            .padding(.bottom, 10)
        }
        
        return Button {
            Haptics.feedback(style: .soft)
            showingNameForm = true
        } label: {
            label
        }
    }
    
    var footerInfoContent: some View {
        
        var dynamicGoalsString: String {
            let prefix = model.dynamicGoalsCount == 1 ? "This is a dynamic goal" : "These are dynamic goals"
            return "\(prefix) and will automatically update when new data is synced from the Health App."
        }
        
        var containsFooterContent: Bool {
            model.containsDynamicGoal || model.containsImplicitGoal
        }

        return Group {
            if containsFooterContent {
                VStack(alignment: .leading, spacing: 10) {
                    if model.containsDynamicGoal {
                        HStack(alignment: .firstTextBaseline) {
                            appleHealthBolt
                                .imageScale(.small)
                                .frame(width: 25)
                            Text(dynamicGoalsString)
                        }
                    }
                    if let implicitGoalName = model.implicitGoalName {
                        HStack(alignment: .firstTextBaseline) {
                            Image(systemName: "sparkles")
                                .imageScale(.medium)
                                .frame(width: 25)
                            Text("Your \(implicitGoalName.lowercased()) goal has been automatically generated based on your other goals. You can still create a different goal to use instead of this.")
                        }
                    }
                }
                .font(.footnote)
                .foregroundColor(Color(.secondaryLabel))
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.bottom, 13)
                .padding(.top, 13)
                .background(Color(.secondarySystemGroupedBackground).opacity(0))
                .cornerRadius(10)
                .padding(.bottom, 10)
            }
        }
    }

    var emojiButton: some View {
        Button {
            Haptics.feedback(style: .soft)
            showingEmojiPicker = true
        } label: {
            Text(model.emoji)
                .font(.system(size: 50))
        }
    }
    
    @ViewBuilder
    var nameTextField: some View {
        TextField("Enter a Name", text: $model.name)
            .font(.title3)
            .multilineTextAlignment(.leading)
            .focused($isFocused)
    }

    func titleCell(_ title: String) -> some View {
        Group {
            Spacer().frame(height: 15)
            HStack {
                Spacer().frame(width: 3)
                Text(title)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.primary)
                Spacer()
                equivalentValuesToggle
            }
            Spacer().frame(height: 7)
        }
    }
    
    var equivalentValuesToggle: some View {
        let binding = Binding<Bool>(
            get: { showingEquivalentValues },
            set: { newValue in
                Haptics.feedback(style: .rigid)
                withAnimation {
                    showingEquivalentValues = newValue
                }
            }
        )
        return Group {
            if showingEquivalentValuesToggle {
                Toggle(isOn: binding) {
                    Label("Calculated Goals", systemImage: "equal.square")
//                    Text("Calculated Goals")
                        .font(.subheadline)
                }
                .toggleStyle(.button)
            } else {
                Spacer()
            }
        }
        .frame(height: 28)
    }
//    var calculatedButton: some View {
//        Button {
//            Haptics.feedback(style: .rigid)
//            withAnimation {
//                showingEquivalentValues.toggle()
//            }
//        } label: {
//            Image(systemName: "equal.square\(showingEquivalentValues ? ".fill" : "")")
//        }
//    }
    func subtitleCell(_ title: String) -> some View {
        Group {
            Spacer().frame(height: 5)
            HStack {
                Spacer().frame(width: 3)
                Text(title)
                    .font(.headline)
//                    .bold()
                    .foregroundColor(.secondary)
                Spacer()
            }
            Spacer().frame(height: 7)
        }
    }
}

import SwiftUI

public enum GoalSetFormRoute: Hashable {
    case goal(GoalModel)
}

//extension GoalSetForm {
//    public class Model: ObservableObject {
//        @Published var nutrientTDEEFormModel: BiometricsModel
//        @Published var path: [GoalSetFormRoute] = []
//        let existingGoalSet: GoalSet?
//
//        init(
//            userOptions: UserUnits,
//            biometrics: Biometrics?,
//            presentedGoalId: UUID? = nil,
//            existingGoalSet: GoalSet?
//        ) {
//            self.existingGoalSet = existingGoalSet
//
//            self.nutrientTDEEFormModel = BiometricsModel(
//                existingProfile: biometrics,
//                userOptions: userOptions
//            )
//
//            self.path = []
//            //TODO: Bring this back
////            if let presentedGoalId, let goalModel = goals.first(where: { $0.id == presentedGoalId }) {
////                self.path = [.goal(goalModel)]
////            }
//        }
//    }
//
//    func resetNutrientTDEEFormModel() {
//        setNutrientTDEEFormModel(with: biometrics)
//    }
//
//    func setNutrientTDEEFormModel(with biometrics: Biometrics?) {
//        nutrientTDEEFormModel = BiometricsModel(existingProfile: biometrics, userOptions: userOptions)
//    }
//
//    func setBiometrics(_ biometrics: Biometrics) {
//        /// in addition to setting the current body Profile, we also update the view model (BiometricsModel) we have  in GoalSetForm.Model (or at least the relevant fields for weight and lbm)
//        self.biometrics = biometrics
//        setNutrientTDEEFormModel(with: biometrics)
//    }
//}

extension GoalSet {
    func equals(_ other: GoalSet) -> Bool {
        emoji == other.emoji
        && name == other.name
        && goals == other.goals
    }
}
