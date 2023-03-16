import SwiftUI
import SwiftUISugar
import SwiftHaptics
import PrepDataTypes
import PrepCoreDataStack

struct EnergyGoalForm_New: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    @EnvironmentObject var model: GoalSetForm.Model
    @ObservedObject var goal: GoalModel
    @State var pickedMealEnergyGoalType: MealEnergyTypeOption
    @State var pickedDietEnergyGoalType: DietEnergyTypeOption
    @State var pickedDelta: EnergyDeltaOption
    
    @State var showingTDEEForm: Bool = false
    
    @State var refreshBool = false
    @State var shouldResignFocus = false
    
    let didTapDelete: (GoalModel) -> ()
    
    init(goal: GoalModel, didTapDelete: @escaping ((GoalModel) -> ())) {
        self.goal = goal
        //TODO: This isn't being updated after creating it and going back to the GoalSetForm
        // We may need to use a binding to the goal here instead and have bindings on the `GoalModel` that set and return the picker options (like MealEnergyGoalTypePickerOption). That would also make things cleaner and move it to the view model.
        let mealEnergyGoalType = MealEnergyTypeOption(goalModel: goal) ?? .fixed
        let dietEnergyGoalType = DietEnergyTypeOption(goalModel: goal) ?? .fixed
        let delta = EnergyDeltaOption(goalModel: goal) ?? .below
        _pickedMealEnergyGoalType = State(initialValue: mealEnergyGoalType)
        _pickedDietEnergyGoalType = State(initialValue: dietEnergyGoalType)
        _pickedDelta = State(initialValue: delta)
        
        self.didTapDelete = didTapDelete
    }
    
    //MARK: - Views
    
    var body: some View {
        navigationStack
    }
    
    var navigationStack: some View {
        NavigationStack {
            FormStyledScrollView {
                valuesSection
                unitSection
                infoSection
            }
            .navigationTitle("Energy")
            .navigationBarTitleDisplayMode(.large)
//            .toolbar { trailingContent }
            .onChange(of: pickedMealEnergyGoalType, perform: mealEnergyGoalChanged)
            .onChange(of: pickedDietEnergyGoalType, perform: dietEnergyGoalChanged)
            .onChange(of: pickedDelta, perform: deltaChanged)
            .onAppear(perform: appeared)
            .onDisappear(perform: disappeared)
            .sheet(isPresented: $showingTDEEForm) { tdeeForm }
        }
    }
    
    var valuesSection: some View {
        let valuesBinding = Binding<GoalValues>(
            get: {
                .init(lower: goal.lowerBound, upper: goal.upperBound)
            },
            set: { newPair in
                goal.lowerBound = newPair.lower
                goal.upperBound = newPair.upper
            }
        )
        
        let equivalentValuesBinding = Binding<GoalValues>(
            get: { .init(lower: goal.equivalentLowerBound, upper: goal.equivalentUpperBound) },
            set: { _ in }
        )
        
        let usesSingleValueBinding = Binding<Bool>(
            get: { goal.energyGoalType?.delta == .deviation },
            set: { _ in }
        )
        
        let unitStringBinding = Binding<String>(
            get: { goal.unitString },
            set: { _ in }
        )
        
        //TODO: Maybe just give it the GoalModel, which it can manipulate and return back to us
        return GoalValuesSection(
            values: valuesBinding,
            equivalentValues: equivalentValuesBinding,
            usesSingleValue: usesSingleValueBinding,
            unitString: unitStringBinding,
            equivalentUnitString: goal.equivalentUnitString
        )
    }
    
    @ViewBuilder
    var infoSection: some View {
        if let unitsFooterString {
            Text(unitsFooterString)
                .multilineTextAlignment(.leading)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .foregroundColor(
                            Color(.quaternarySystemFill)
                                .opacity(colorScheme == .dark ? 0.5 : 1)
                        )
                )
                .cornerRadius(10)
                .padding(.bottom, 10)
                .padding(.horizontal, 17)
        }
    }
    var trailingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            syncedIndicator
            menu
        }
    }
    
    var menu: some View {
        Menu {
            Button(role: .destructive) {
                Haptics.warningFeedback()
                didTapDelete(goal)
            } label: {
                Label("Remove Goal", systemImage: "minus.circle")
            }
        } label: {
            Image(systemName: "ellipsis")
        }
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture().onEnded {
            Haptics.feedback(style: .soft)
        })
    }
    
    @ViewBuilder
    var syncedIndicator: some View {
        if isSynced {
            appleHealthBolt
            Text("Synced")
                .font(.footnote)
                .textCase(.uppercase)
                .foregroundColor(Color(.tertiaryLabel))
        }
    }
    
    var unitsFooterString: String? {
        guard isSynced else {
            return nil
        }
        return "Your maintenance \(UserManager.energyDescription.lowercased()) is synced with the Health App, so this goal will adjust automatically to any changes."
    }
    
    var unitSection: some View {
        var contents: some View {
            Group {
                typePicker
                deltaPicker
                tdeeButton
            }
        }
        var horizontalScrollView: some View {
            FormStyledSection(horizontalPadding: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        contents
                    }
                    .padding(.horizontal, 17)
                }
                .frame(maxWidth: .infinity)
            }
        }
        
        var flowView: some View {
            FormStyledSection {
                FlowView(alignment: .center, spacing: 10, padding: 37) {
                    contents
                }
            }
        }
        
        return Group {
//            horizontalScrollView
            flowView
        }
    }
    
    var tdeeForm: some View {
        TDEEForm()
    }
    
    @ViewBuilder
    var tdeeButton: some View {
        if shouldShowEnergyDeltaElements {
            Button {
                shouldResignFocus.toggle()
                Haptics.feedback(style: .soft)
                showingTDEEForm = true
            } label: {
                if let formattedTDEE = UserManager.biometrics.formattedTDEEWithUnit {
                    if UserManager.biometrics.syncsMaintenanceEnergy {
                        PickerLabel(
                            formattedTDEE,
                            prefix: "maintenance",
                            systemImage: "flame.fill",
                            imageColor: Color(hex: "F3DED7"),
                            backgroundGradientTop: HealthTopColor,
                            backgroundGradientBottom: HealthBottomColor,
                            foregroundColor: .white,
                            imageScale: .small
                        )
                    } else {
                        PickerLabel(
                            formattedTDEE,
                            prefix: "maintenance",
                            systemImage: "flame.fill",
                            imageColor: Color(.tertiaryLabel),
                            imageScale: .small
                        )
                    }
                } else {
                    PickerLabel(
                        "maintenance",
                        prefix: "set",
                        systemImage: "flame.fill",
                        imageColor: Color.white.opacity(0.75),
                        backgroundColor: .accentColor,
                        foregroundColor: .white,
                        prefixColor: Color.white.opacity(0.75),
                        imageScale: .small
                    )
                }
            }
        }
    }
    
    var unitView: some View {
        HStack {
            Text(goal.energyGoalType?.description ?? "")
                .foregroundColor(Color(.tertiaryLabel))
            if let difference = goal.energyGoalDelta {
                Spacer()
                Text(difference.description)
                    .foregroundColor(Color(.quaternaryLabel))
            }
        }
    }
    
    //MARK: - Pickers
    
    @ViewBuilder
    var typePicker: some View {
        if goal.goalSetType == .meal {
            mealTypePicker
        } else {
            dietTypePicker
        }
    }
    
    var mealTypePicker: some View {
        PickerLabel(
            pickedMealEnergyGoalType.description(energyUnit: UserManager.energyUnit),
            systemImage: nil
        )
        .animation(.none, value: pickedMealEnergyGoalType)
//        Menu {
//            Picker(selection: $pickedMealEnergyGoalType, label: EmptyView()) {
//                ForEach(MealEnergyTypeOption.allCases, id: \.self) {
//                    Text($0.description(userEnergyUnit: .kcal)).tag($0)
//                }
//            }
//        } label: {
//            PickerLabel(pickedMealEnergyGoalType.description(userEnergyUnit: .kcal))
//                .animation(.none, value: pickedMealEnergyGoalType)
//        }
//        .contentShape(Rectangle())
//        .simultaneousGesture(TapGesture().onEnded {
//            Haptics.feedback(style: .soft)
//        })
    }
    
    var dietTypePicker: some View {
        let binding = Binding<DietEnergyTypeOption>(
            get: { pickedDietEnergyGoalType },
            set: { newType in
                withAnimation {
                    Haptics.feedback(style: .soft)
                    pickedDietEnergyGoalType = newType
                }
            }
        )
        return Menu {
            Picker(selection: binding, label: EmptyView()) {
                ForEach(DietEnergyTypeOption.allCases, id: \.self) {
                    Text($0.description(energyUnit: UserManager.energyUnit)).tag($0)
                }
            }
        } label: {
            PickerLabel(pickedDietEnergyGoalType.shortDescription(energyUnit: UserManager.energyUnit))
        }
        .animation(.none, value: pickedDietEnergyGoalType)
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture().onEnded {
            Haptics.feedback(style: .soft)
        })
    }

    @ViewBuilder
    var deltaPicker: some View {
        if shouldShowEnergyDeltaElements {
            HStack {
                Menu {
                    Picker(selection: $pickedDelta, label: EmptyView()) {
                        ForEach(EnergyDeltaOption.allCases, id: \.self) {
                            Label($0.description, systemImage: $0.systemImage)
                                .tag($0)
                        }
                    }
                } label: {
                    PickerLabel(pickedDelta.description)
                }
                .animation(.none, value: pickedDelta)
                .contentShape(Rectangle())
                .simultaneousGesture(TapGesture().onEnded {
                    Haptics.feedback(style: .soft)
                })
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    //MARK: - Actions
    
    func disappeared() {
        goal.validateEnergy()
        model.createImplicitGoals()
    }

    func appeared() {
        pickedMealEnergyGoalType = MealEnergyTypeOption(goalModel: goal) ?? .fixed
        pickedDietEnergyGoalType = DietEnergyTypeOption(goalModel: goal) ?? .fixed
        pickedDelta = EnergyDeltaOption(goalModel: goal) ?? .below
        refreshBool.toggle()
    }
    
    func dietEnergyGoalChanged(_ newValue: DietEnergyTypeOption) {
        goal.energyGoalType = self.energyGoalType
    }
    
    func mealEnergyGoalChanged(_ newValue: MealEnergyTypeOption) {
        goal.energyGoalType = self.energyGoalType
    }
    
    func deltaChanged(to newValue: EnergyDeltaOption) {
        goal.energyGoalType = self.energyGoalType
    }
    
    //MARK: - Convenience
    
    var isSynced: Bool {
        goal.isSynced
    }
    
    var energyUnit: EnergyUnit {
        goal.energyUnit ?? .kcal
    }
    
    var energyDelta: EnergyGoalDelta {
        switch pickedDelta {
        case .below:
            return .deficit
        case .above:
            return .surplus
        case .around:
            return .deviation
        }
    }
    
    var energyGoalType: EnergyGoalType? {
        if goal.goalSetType == .meal {
            switch pickedMealEnergyGoalType {
            case .fixed:
                return .fixed(energyUnit)
            }
        } else {
            switch pickedDietEnergyGoalType {
            case .fixed:
                return .fixed(energyUnit)
            case .fromMaintenance:
                return .fromMaintenance(energyUnit, energyDelta)
            case .percentageFromMaintenance:
                return .percentFromMaintenance(energyDelta)
            }
        }
    }
    
    var shouldShowEnergyDeltaElements: Bool {
        goal.goalSetType != .meal  && pickedDietEnergyGoalType != .fixed
    }
}
