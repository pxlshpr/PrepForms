import SwiftUI
import SwiftUISugar
import SwiftHaptics
import PrepDataTypes
import PrepCoreDataStack

public struct GoalSetForm: View {
        
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @StateObject var goalSetViewModel: GoalSetViewModel
//    @StateObject var viewModel: ViewModel
    
    @State var showingNutrientsPicker: Bool = false
    @State var showingEmojiPicker = false
    
    @State var showingEquivalentValuesToggle: Bool
    @State var showingEquivalentValues = false

    @FocusState var isFocused: Bool
    
    @State var showingSaveButton: Bool

    let didTapSave: (GoalSet, BodyProfile?, Bool) -> ()

    @State var showingNameForm: Bool = false
    
    @State var showingEditConfirmation: Bool = false
    @State var numberOfPreviousUses: Int = 0
    @State var showingDuplicateAlert = false
    
    //TODO: Use user's units here
    public init(
        type: GoalSetType,
        existingGoalSet: GoalSet? = nil,
        isDuplicating: Bool = false,
        bodyProfile: BodyProfile? = nil,
        didTapSave: @escaping (GoalSet, BodyProfile?, Bool) -> ()
    ) {
        let goalSetViewModel = GoalSetViewModel(
            userUnits: .standard,
            type: type,
            existingGoalSet: existingGoalSet,
            isDuplicating: isDuplicating,
            bodyProfile: bodyProfile
        )
        _goalSetViewModel = StateObject(wrappedValue: goalSetViewModel)
        _showingEquivalentValuesToggle = State(initialValue: goalSetViewModel.containsGoalWithEquivalentValues)
        self.didTapSave = didTapSave
        
        _showingSaveButton = State(initialValue: isDuplicating)
    }
    
    public var body: some View {
        NavigationStack(path: $goalSetViewModel.path) {
            content
            .background(Color(.systemGroupedBackground))
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar { trailingContent }
            .sheet(isPresented: $showingNutrientsPicker) { nutrientsPicker }
            .sheet(isPresented: $showingEmojiPicker) { emojiPicker }
            .navigationDestination(for: GoalSetFormRoute.self, destination: navigationDestination)
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: goalSetViewModel.containsGoalWithEquivalentValues, perform: containsGoalWithEquivalentValuesChanged)
            .onChange(of: canBeSaved, perform: canBeSavedChanged)
            .onChange(of: goalSetViewModel.singleGoalViewModelToPushTo, perform: singleGoalViewModelToPushTo)
            .sheet(isPresented: $showingNameForm) { nameForm }
            .confirmationDialog(
                editConfirmationTitle,
                isPresented: $showingEditConfirmation,
                titleVisibility: .visible,
                actions: editConfirmationActions
            )
            .alert(isPresented: $showingDuplicateAlert) { duplicateAlert }
        }
    }
    
    var duplicateAlert: Alert {
        Alert(
            title: Text("Existing \(goalSetViewModel.type.description)"),
            message: Text("Please choose a different name than ‘\(goalSetViewModel.name)’, as this one has already been used."),
            dismissButton: .default(Text("OK"))
        )
    }
    
    var editConfirmationTitle: String {
        "This \(goalSetViewModel.type.description) has been used \(numberOfPreviousUses) times. Are you sure you want to modify all of them?"
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
        NameForm(name: $goalSetViewModel.name )
    }
    
    func singleGoalViewModelToPushTo(to goalViewModel: GoalViewModel?) {
        guard let goalViewModel else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isFocused = false
            goalSetViewModel.path.append(.goal(goalViewModel))
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
        case .goal(let goalViewModel):
            goalForm(for: goalViewModel)
        }
    }
    
    var title: String {
        let typeName = goalSetViewModel.type.description
        let prefix: String
        if goalSetViewModel.existingGoalSet == nil {
            prefix = "New"
        } else {
            prefix = goalSetViewModel.isDuplicating ? "New" : "Edit"
        }
        return "\(prefix) \(typeName)"
    }
    
    var content: some View {
        ZStack {
            scrollView
            buttonLayer
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
                if !goalSetViewModel.goalViewModels.isEmpty {
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
        goalSetViewModel.shouldShowSaveButton
    }
    
    func tappedSave() {
        
        if !goalSetViewModel.isEditing || goalSetViewModel.isDuplicating {
            guard !DataManager.shared.hasGoalSet(named: goalSetViewModel.name, type: goalSetViewModel.type) else {
                showingDuplicateAlert = true
                return
            }
        }
        
        if goalSetViewModel.isEditing,
           let existing = goalSetViewModel.existingGoalSet
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
        didTapSave(goalSetViewModel.goalSet, goalSetViewModel.bodyProfile, overwritingPreviousUses)
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
        if let goal = goalSetViewModel.energyGoal {
            cell(for: goal)
        } else if let index = goalSetViewModel.implicitEnergyGoalIndex {
            cell(for: goalSetViewModel.implicitGoals[index], isButton: false)
        }
    }

    @ViewBuilder
    var carbCell: some View {
        if let goal = goalSetViewModel.carbGoal {
            cell(for: goal)
        } else if let index = goalSetViewModel.implicitMacroGoalIndex(for: .carb) {
            cell(for: goalSetViewModel.implicitGoals[index], isButton: false)
        }
    }
    @ViewBuilder
    var fatCell: some View {
        if let goal = goalSetViewModel.fatGoal {
            cell(for: goal)
        } else if let index = goalSetViewModel.implicitMacroGoalIndex(for: .fat) {
            cell(for: goalSetViewModel.implicitGoals[index], isButton: false)
        }
    }
    @ViewBuilder
    var proteinCell: some View {
        if let goal = goalSetViewModel.proteinGoal {
            cell(for: goal)
        } else if let index = goalSetViewModel.implicitMacroGoalIndex(for: .protein) {
            cell(for: goalSetViewModel.implicitGoals[index], isButton: false)
        }
    }

    
    func cell(for goalViewModel: GoalViewModel, isButton: Bool = true) -> some View {
        var label: some View {
            GoalCell(
                goal: goalViewModel,
                showingEquivalentValues: $showingEquivalentValues
            )
        }
        return Group {
            if isButton {
                Button {
                    isFocused = false
                    goalSetViewModel.path.append(.goal(goalViewModel))
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
        if !goalSetViewModel.macroGoals.isEmpty {
            Group {
                subtitleCell("Macros")
                carbCell
                fatCell
                proteinCell
//                ForEach(goalSetViewModel.macroGoals, id: \.self) {
//                    cell(for: $0)
//                }
            }
        }
    }
    
    @ViewBuilder
    var microCells: some View {
        if !goalSetViewModel.microGoals.isEmpty {
            Group {
                subtitleCell("Micronutrients")
                ForEach(goalSetViewModel.microGoals, id: \.self) {
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
                    if goalSetViewModel.name.isEmpty {
                        Text("Enter a name")
                            .foregroundColor(Color(.tertiaryLabel))
                    } else {
                        Text(goalSetViewModel.name)
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
            let prefix = goalSetViewModel.dynamicGoalsCount == 1 ? "This is a dynamic goal" : "These are dynamic goals"
            return "\(prefix) and will automatically update when new data is synced from the Health App."
        }
        
        var containsFooterContent: Bool {
            goalSetViewModel.containsDynamicGoal || goalSetViewModel.containsImplicitGoal
        }

        return Group {
            if containsFooterContent {
                VStack(alignment: .leading, spacing: 10) {
                    if goalSetViewModel.containsDynamicGoal {
                        HStack(alignment: .firstTextBaseline) {
                            appleHealthBolt
                                .imageScale(.small)
                                .frame(width: 25)
                            Text(dynamicGoalsString)
                        }
                    }
                    if let implicitGoalName = goalSetViewModel.implicitGoalName {
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
            Text(goalSetViewModel.emoji)
                .font(.system(size: 50))
        }
    }
    
    @ViewBuilder
    var nameTextField: some View {
        TextField("Enter a Name", text: $goalSetViewModel.name)
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

//MARK: - 👁‍🗨 Previews

struct DietForm_Previews: PreviewProvider {
    static var previews: some View {
        DietPreview()
    }
}

struct MealTypeForm_Previews: PreviewProvider {
    static var previews: some View {
        MealTypePreview()
    }
}


struct EnergyForm_Previews: PreviewProvider {
    
    static var previews: some View {
        EnergyFormPreview()
    }
}

struct MacroForm_Previews: PreviewProvider {
    
    static var previews: some View {
        MacroFormPreview()
    }
}


//MARK: Energy Form Preview

struct EnergyFormPreview: View {
    
    @StateObject var viewModel: GoalSetViewModel
    @StateObject var goalViewModel: GoalViewModel
    
    init() {
        let goalSetViewModel = GoalSetViewModel(
            userUnits:.standard,
            type: .day,
            existingGoalSet: nil,
            bodyProfile: BodyProfile(
                energyUnit: .kcal,
                weightUnit: .kg,
                heightUnit: .cm,
                restingEnergy: 2000,
                restingEnergySource: .userEntered,
                activeEnergy: 1100,
                activeEnergySource: .userEntered
            )
        )
        let goalViewModel = GoalViewModel(
            goalSet: goalSetViewModel,
            goalSetType: .day,
            type: .energy(.fromMaintenance(.kcal, .deficit)),
            lowerBound: 500
//            , upperBound: 750
        )
        _viewModel = StateObject(wrappedValue: goalSetViewModel)
        _goalViewModel = StateObject(wrappedValue: goalViewModel)
    }
    
    var body: some View {
        NavigationView {
            EnergyGoalForm(goal: goalViewModel, didTapDelete: { _ in
                
            })
            .environmentObject(viewModel)
        }
    }
}

//MARK: Macro Form

struct MacroFormPreview: View {
    
    @StateObject var goalSet: GoalSetViewModel
    @StateObject var goal: GoalViewModel
    
    init() {
        let goalSet = GoalSetViewModel(
            userUnits: .standard,
            type: .day,
            existingGoalSet: GoalSet(
                name: "Bulking",
                emoji: "",
                goals: [
                    Goal(type: .energy(.fromMaintenance(.kcal, .surplus)), lowerBound: 500, upperBound: 1500)
                ]
            ),
            bodyProfile: .mock(
                restingEnergy: 1000,
                lbm: 77
            )
        )
        let goal = GoalViewModel(
            goalSet: goalSet,
            goalSetType: .day,
            type: .macro(.percentageOfEnergy, .carb),
            lowerBound: 20,
            upperBound: 30
        )
        _goalSet = StateObject(wrappedValue: goalSet)
        _goal = StateObject(wrappedValue: goal)
    }
    
    var body: some View {
        NavigationView {
            NutrientGoalForm(goal: goal, didTapDelete: { _ in
                
            })
                .environmentObject(goalSet)
        }
    }
}

//MARK: - GoalSet Form Preview
public struct DietPreview: View {
    
    static let energyGoal = Goal(
        type: .energy(.fromMaintenance(.kcal, .deficit))
        , lowerBound: 500
        , upperBound: 750
    )

    static let energyGoalFixedUpper = Goal(
        type: .energy(.fixed(.kcal))
        , lowerBound: 1250
        , upperBound: 1500
    )

    static let fatGoalPerBodyMass = Goal(
        type: .macro(.quantityPerBodyMass(.leanMass, .kg), .fat),
        upperBound: 1
    )

    static let fatGoalPerEnergy = Goal(
        type: .macro(.percentageOfEnergy, .fat),
        upperBound: 20
    )

    static let fatGoalFixed = Goal(
        type: .macro(.fixed, .fat),
        lowerBound: 55,
        upperBound: 90
    )

    static let carbGoalFixed = Goal(
        type: .macro(.fixed, .carb),
        upperBound: 200
    )

    static let highCarbGoalFixed = Goal(
        type: .macro(.fixed, .carb),
        upperBound: 500
    )

    static let proteinGoalFixed = Goal(
        type: .macro(.fixed, .protein),
        lowerBound: 176,
        upperBound: 245
    )

    static let proteinGoalPerBodyMass = Goal(
        type: .macro(.quantityPerBodyMass(.weight, .kg), .protein),
        lowerBound: 1.1,
        upperBound: 2.5
    )

    static let magnesiumGoal = Goal(
        type: .micro(.fixed, .magnesium, .mg),
        lowerBound: 400
    )

    static let sugarGoal = Goal(
        type: .micro(.percentageOfEnergy, .sugars, .g),
        upperBound: 10
    )

    static let goalSet = GoalSet(
        type: .day,
        name: "Cutting",
        emoji: "🫃🏽",
        goals: [
//            energyGoal,
            energyGoalFixedUpper,
//            proteinGoalPerBodyMass,
            proteinGoalFixed,
//            fatGoalPerEnergy,
//            fatGoalPerBodyMass,
            fatGoalFixed,
//            carbGoalFixed,
//            highCarbGoalFixed,
//            magnesiumGoal,
//            sugarGoal
        ]
    )
    
    public init() { }
    
    public var body: some View {
        GoalSetForm(
            type: .day,
            existingGoalSet: Self.goalSet,
            bodyProfile: BodyProfile.mockBodyProfile
        ) { goalSet, bodyProfile, overwritingPastUses in
            
        }
    }
}

public struct MealTypePreview: View {
    
    static let energyGoal = Goal(
        type: .energy(.fixed(.kcal)),
        lowerBound: 250,
        upperBound: 350
    )
    
    static let proteinGoal = Goal(
        type: .macro(.fixed, .protein),
        lowerBound: 20
    )

    static let carbGoal = Goal(
        type: .macro(.quantityPerWorkoutDuration(.min), .carb),
        lowerBound: 0.5
    )

    static let sodiumGoal = Goal(
        type: .micro(.quantityPerWorkoutDuration(.hour), .sodium, .mg),
        lowerBound: 300,
        upperBound: 600
    )

    static let goalSet = GoalSet(
        type: .meal,
        name: "Workout Fuel",
        emoji: "🚴🏽",
        goals: [
            energyGoal,
//            proteinGoal,
//            carbGoal,
            sodiumGoal
        ]
    )
    
    public init() { }
    
    public var body: some View {
        GoalSetForm(
            type: .meal,
            existingGoalSet: Self.goalSet,
            bodyProfile: BodyProfile.mockBodyProfile
        ) { goalSet, bodyProfile, overwritingPastUses in
            
        }
    }
}

extension BodyProfile {
    static let mockBodyProfile = BodyProfile.mock(
        restingEnergy: 2000,
        activeEnergy: 1000,
        weight: 98,
        lbm: 65
    )
}

public enum GoalSetFormRoute: Hashable {
    case goal(GoalViewModel)
}

//extension GoalSetForm {
//    public class ViewModel: ObservableObject {
//        @Published var nutrientTDEEFormViewModel: TDEEForm.ViewModel
//        @Published var path: [GoalSetFormRoute] = []
//        let existingGoalSet: GoalSet?
//
//        init(
//            userUnits: UserUnits,
//            bodyProfile: BodyProfile?,
//            presentedGoalId: UUID? = nil,
//            existingGoalSet: GoalSet?
//        ) {
//            self.existingGoalSet = existingGoalSet
//
//            self.nutrientTDEEFormViewModel = TDEEForm.ViewModel(
//                existingProfile: bodyProfile,
//                userUnits: userUnits
//            )
//
//            self.path = []
//            //TODO: Bring this back
////            if let presentedGoalId, let goalViewModel = goals.first(where: { $0.id == presentedGoalId }) {
////                self.path = [.goal(goalViewModel)]
////            }
//        }
//    }
//
//    func resetNutrientTDEEFormViewModel() {
//        setNutrientTDEEFormViewModel(with: bodyProfile)
//    }
//
//    func setNutrientTDEEFormViewModel(with bodyProfile: BodyProfile?) {
//        nutrientTDEEFormViewModel = TDEEForm.ViewModel(existingProfile: bodyProfile, userUnits: userUnits)
//    }
//
//    func setBodyProfile(_ bodyProfile: BodyProfile) {
//        /// in addition to setting the current body Profile, we also update the view model (TDEEForm.ViewModel) we have  in GoalSetViewModel (or at least the relevant fields for weight and lbm)
//        self.bodyProfile = bodyProfile
//        setNutrientTDEEFormViewModel(with: bodyProfile)
//    }
//}

extension GoalSet {
    func equals(_ other: GoalSet) -> Bool {
        emoji == other.emoji
        && name == other.name
        && goals == other.goals
    }
}
