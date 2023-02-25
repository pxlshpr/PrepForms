import SwiftUI
import SwiftUISugar
import SwiftHaptics
import PrepDataTypes

struct NutrientGoalForm: View {
    
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var goalSet: GoalSetViewModel
    @ObservedObject var goal: GoalViewModel

    let nutrientUnit: NutrientUnit
    
    @State var pickedMealNutrientGoal: MealNutrientGoal
    @State var pickedDietNutrientGoal: DietNutrientGoal
    @State var pickedBodyMassType: NutrientGoalBodyMassType
    @State var pickedBodyMassUnit: WeightUnit
    
    @State var energyValue: Double = 1000
    @State var pickedEnergyUnit: EnergyUnit = .kcal
    
    @State var pickedWorkoutDurationUnit: WorkoutDurationUnit
    
    @State var showingLeanMassForm: Bool = false
    @State var showingWeightForm: Bool = false
    
    @State var shouldResignFocus = false
    
    let didTapDelete: (GoalViewModel) -> ()

    init(goal: GoalViewModel, didTapDelete: @escaping ((GoalViewModel) -> ())) {
        
        self.goal = goal
        
        self.nutrientUnit = goal.nutrientUnit ?? .g
        
        let pickedMealNutrientGoal = MealNutrientGoal(goalViewModel: goal) ?? .fixed
        let pickedDietNutrientGoal = DietNutrientGoal(goalViewModel: goal) ?? .fixed
        let bodyMassType = goal.bodyMassType ?? .weight
        let bodyMassUnit = goal.bodyMassUnit ?? .kg // TODO: User's default unit here
        let workoutDurationUnit = goal.workoutDurationUnit ?? .min
        _pickedMealNutrientGoal = State(initialValue: pickedMealNutrientGoal)
        _pickedDietNutrientGoal = State(initialValue: pickedDietNutrientGoal)
        _pickedBodyMassType = State(initialValue: bodyMassType)
        _pickedBodyMassUnit = State(initialValue: bodyMassUnit)
        _pickedWorkoutDurationUnit = State(initialValue: workoutDurationUnit)
     
        self.didTapDelete = didTapDelete
    }
    
    var body: some View {
        FormStyledScrollView {
            HStack(spacing: 0) {
                lowerBoundSection
                swapValuesButton
                upperBoundSection
            }
            unitSection
            bodyMassSection
            equivalentSection
        }
        .navigationTitle(goal.description)
        .navigationBarTitleDisplayMode(.large)
        .toolbar { trailingContent }
        .sheet(isPresented: $showingWeightForm) { weightForm }
        .sheet(isPresented: $showingLeanMassForm) { leanMassForm }
        .onDisappear(perform: disappeared)
        .scrollDismissesKeyboard(.interactively)
    }
    
    func disappeared() {
        goal.validateNutrient()
        goalSet.createImplicitGoals()
    }
    
    //MARK: - Sections
    
    var unitSection: some View {
        FormStyledSection(footer: unitsFooter, horizontalPadding: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    typePicker
                    bodyMassUnitPicker
                    bodyMassTypePicker
                    workoutDurationUnitPicker
                    energyButton
                    Spacer()
                }
                .padding(.horizontal, 17)
            }
            .frame(maxWidth: .infinity)
//            .frame(height: 50)
        }
    }
    
    var lowerBoundSection: some View {
        let binding = Binding<Double?>(
            get: { goal.lowerBound },
            set: { newValue in
                withAnimation {
                    goal.lowerBound = newValue
                }
            }
        )
        var header: some View {
            Text(goal.haveBothBounds ? "From" : "At least")
        }
        return FormStyledSection(header: header) {
            HStack {
                DoubleTextField(
                    double: binding,
                    placeholder: "Optional",
                    shouldResignFocus: $shouldResignFocus
                )
            }
        }
    }
    
    var equivalentSection: some View {
        @ViewBuilder
        var header: some View {
            if isDynamic {
                Text("Currently Equals")
            } else {
                Text("Equals")
            }
        }
        
        return Group {
            if goal.haveEquivalentValues {
                FormStyledSection(header: header) {
                    goal.equivalentTextHStack
                }
            }
        }
    }
    
    var upperBoundSection: some View {
        let binding = Binding<Double?>(
            get: { goal.upperBound },
            set: { newValue in
                withAnimation {
                    goal.upperBound = newValue
                }
            }
        )
        var header: some View {
            Text(goal.haveBothBounds ? "To" : "At most")
        }
        return FormStyledSection(header: header) {
            HStack {
                DoubleTextField(
                    double: binding,
                    placeholder: "Optional",
                    shouldResignFocus: $shouldResignFocus
                )
            }
        }
    }
    
    var bodyMassSection: some View {
        
        var footer: some View {
            Text("Your \(pickedBodyMassType.description) is being used to calculate this goal.")
        }
        return Group {
            if isQuantityPerBodyMass {
                FormStyledSection(header: Text("with"), footer: footer) {
                    HStack {
                        bodyMassButton
                        Spacer()
                    }
                }
            }
        }
    }
    
    //MARK: - Decorator Views

    var trailingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            dynamicIndicator
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
    }
    
    @ViewBuilder
    var dynamicIndicator: some View {
        if isDynamic {
            appleHealthBolt
            Text("Dynamic")
                .font(.footnote)
                .textCase(.uppercase)
                .foregroundColor(Color(.tertiaryLabel))
        }
    }

    var unitsFooter: some View {
        var component: String {
            switch nutrientGoalType {
            case .quantityPerBodyMass(let bodyMass, _):
                return bodyMass.description
            case .percentageOfEnergy:
                return "maintenance energy (which your energy goal is based on)"
            default:
                return ""
            }
        }
        return Group {
            if isDynamic {
                Text("Your \(component) is synced with the Health App. This goal will automatically adjust when it changes.")
            } else {
                switch nutrientGoalType {
                case .fixed:
                    EmptyView()
                case .percentageOfEnergy:
                    Text("Your energy goal is being used to calculate this goal.")
                case .quantityPerBodyMass:
                    EmptyView()
                case .quantityPerWorkoutDuration(_):
                    Text("Your planned workout duration will be used to calculate this goal. You can specify it when creating a meal with this type.")
                    /**
                     Text("Use this when you want to create a dynamic goal based on how long you workout for.")
                     Text("For e.g., you could create an \"intra-workout\" meal type that has a 0.5g/min carb goal.")
                     Text("You can then set or use your last workout time when creating a meal with this type.")
                     */
                default:
                    EmptyView()
                }
            }
        }
    }
    
    //MARK: - Sheets
    
    var weightForm: some View {
        NutrientWeightForm(existingProfile: goalSet.bodyProfile, didTapSave: { bodyProfile in
            goalSet.setBodyProfile(bodyProfile)
        }, didTapClose: {
            goalSet.resetNutrientTDEEFormViewModel()
        })
        .environmentObject(goalSet.nutrientTDEEFormViewModel)
    }
    
    var leanMassForm: some View {
        NutrientLeanBodyMassForm(existingProfile: goalSet.bodyProfile, didTapSave: { bodyProfile in
            goalSet.setBodyProfile(bodyProfile)
        }, didTapClose: {
            goalSet.resetNutrientTDEEFormViewModel()
        })
        .environmentObject(goalSet.nutrientTDEEFormViewModel)
    }

    //MARK: - Convenience

    var nutrientGoalType: NutrientGoalType? {
        if goal.goalSetType == .meal {
            
            switch pickedMealNutrientGoal {
            case .fixed:
                return .fixed
            case .quantityPerWorkoutDuration:
                return .quantityPerWorkoutDuration(pickedWorkoutDurationUnit)
            case .quantityPerBodyMass:
                return .quantityPerBodyMass(pickedBodyMassType, pickedBodyMassUnit)
            }
            
        } else {
            switch pickedDietNutrientGoal {
            case .fixed:
                return .fixed
            case .quantityPerBodyMass:
                return .quantityPerBodyMass(pickedBodyMassType, pickedBodyMassUnit)
            case .percentageOfEnergy:
                return .percentageOfEnergy
            case .quantityPerEnergy:
                return .quantityPerEnergy(energyValue, pickedEnergyUnit)
            }
        }
    }
    
    var haveBodyMass: Bool {
        switch pickedBodyMassType {
        case .weight:
            return goalSet.bodyProfile?.hasWeight == true
        case .leanMass:
            return goalSet.bodyProfile?.hasLBM == true
        }
    }
    
    var isDynamic: Bool {
        goal.isDynamic
    }

    var bodyMassFormattedWithUnit: String {
        guard let bodyProfile = goalSet.bodyProfile else { return "" }
        switch pickedBodyMassType {
        case .weight:
            guard let weight = bodyProfile.weight else { return "" }
            return weight.rounded(toPlaces: 1).cleanAmount + " \(bodyProfile.weightUnit.shortDescription)"
        case .leanMass:
            guard let lbm = bodyProfile.lbm else { return "" }
            return lbm.rounded(toPlaces: 1).cleanAmount + " \(bodyProfile.weightUnit.shortDescription)"
        }
    }
    
    //MARK: - Buttons
    
    @ViewBuilder
    var energyButton: some View {
        if pickedDietNutrientGoal == .quantityPerEnergy {
            Button {
                
            } label: {
                PickerLabel(
                    energyValue.cleanAmount + " " + pickedEnergyUnit.shortDescription,
                    prefix: "per",
                    systemImage: "flame.fill",
                    imageScale: .small
                )
            }
        }
    }
    
    @ViewBuilder
    var bodyMassButton: some View {
        Button {
            Haptics.feedback(style: .soft)
            shouldResignFocus.toggle()
            switch pickedBodyMassType {
            case .weight:
                showingWeightForm = true
            case .leanMass:
                showingLeanMassForm = true
            }
        } label: {
            if haveBodyMass {
                if goal.bodyMassIsSyncedWithHealth {
                    PickerLabel(
                        bodyMassFormattedWithUnit,
                        prefix: "\(pickedBodyMassType.description)",
                        systemImage: "figure.arms.open",
                        imageColor: Color(hex: "F3DED7"),
                        backgroundGradientTop: Color(hex: AppleHealthTopColorHex),
                        backgroundGradientBottom: Color(hex: AppleHealthBottomColorHex),
                        foregroundColor: .white,
                        prefixColor: Color(hex: "F3DED7"),
                        imageScale: .medium
                    )
                } else {
                    PickerLabel(
                        bodyMassFormattedWithUnit,
                        prefix: "\(pickedBodyMassType.description)",
                        systemImage: "figure.arms.open",
                        imageColor: Color(.tertiaryLabel),
                        imageScale: .medium
                    )
                }
            } else {
                PickerLabel(
                    "\(pickedBodyMassType.description)",
                    prefix: "set",
                    systemImage: "figure.arms.open",
                    imageColor: Color.white.opacity(0.75),
                    backgroundColor: .accentColor,
                    foregroundColor: .white,
                    prefixColor: Color.white.opacity(0.75),
                    imageScale: .medium
                )
            }
        }
    }

    var swapValuesButton: some View {
        VStack(spacing: 7) {
            Text("")
            if goal.lowerBound != nil, goal.upperBound == nil {
                Button {
                    Haptics.feedback(style: .rigid)
                    goal.upperBound = goal.lowerBound
                    goal.lowerBound = nil
                } label: {
                    Image(systemName: "rectangle.righthalf.inset.filled.arrow.right")
                        .foregroundColor(.accentColor)
                }
            } else if goal.upperBound != nil, goal.lowerBound == nil {
                Button {
                    Haptics.feedback(style: .rigid)
                    goal.lowerBound = goal.upperBound
                    goal.upperBound = nil
                } label: {
                    Image(systemName: "rectangle.lefthalf.inset.filled.arrow.left")
                        .foregroundColor(.accentColor)
                }
            }
        }
        .padding(.top, 10)
        .frame(width: 16, height: 20)
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
        let binding = Binding<MealNutrientGoal>(
            get: { pickedMealNutrientGoal },
            set: { newType in
                withAnimation {
                    self.pickedMealNutrientGoal = newType
                }
                self.goal.nutrientGoalType = nutrientGoalType
            }
        )
        return Menu {
            Picker(selection: binding, label: EmptyView()) {
                ForEach(MealNutrientGoal.allCases, id: \.self) {
                    Text($0.menuDescription(nutrientUnit: nutrientUnit)).tag($0)
                }
            }
        } label: {
            PickerLabel(
                pickedDietNutrientGoal.pickerDescription(nutrientUnit: nutrientUnit)
            )
        }
        .animation(.none, value: pickedMealNutrientGoal)
        .simultaneousGesture(TapGesture().onEnded {
            Haptics.feedback(style: .soft)
        })
    }

    var dietTypePicker: some View {
        let binding = Binding<DietNutrientGoal>(
            get: { pickedDietNutrientGoal },
            set: { newType in
                withAnimation {
                    self.pickedDietNutrientGoal = newType
                }
                self.goal.nutrientGoalType = nutrientGoalType
            }
        )
        
        return Menu {
            Picker(selection: binding, label: EmptyView()) {
                ForEach(DietNutrientGoal.allCases, id: \.self) {
                    Text($0.menuDescription(nutrientUnit: nutrientUnit)).tag($0)
                }
            }
        } label: {
            if pickedDietNutrientGoal == .percentageOfEnergy {
                if goalSet.energyGoal?.isDynamic == true {
                    PickerLabel(
                        pickedDietNutrientGoal.pickerDescription(nutrientUnit: nutrientUnit),
                        systemImage: "flame.fill",
                        imageColor: Color(hex: "F3DED7"),
                        backgroundGradientTop: Color(hex: AppleHealthTopColorHex),
                        backgroundGradientBottom: Color(hex: AppleHealthBottomColorHex),
                        foregroundColor: .white,
                        imageScale: .small
                    )
                } else {
                    PickerLabel(
                        pickedDietNutrientGoal.pickerDescription(nutrientUnit: nutrientUnit),
                        systemImage: "flame.fill"
                    )
                }

            } else {
                PickerLabel(pickedDietNutrientGoal.pickerDescription(nutrientUnit: nutrientUnit))
            }
        }
        .animation(.none, value: pickedDietNutrientGoal)
        .simultaneousGesture(TapGesture().onEnded {
            Haptics.feedback(style: .soft)
        })
    }
    
    var isQuantityPerBodyMass: Bool {
        pickedDietNutrientGoal == .quantityPerBodyMass || pickedMealNutrientGoal == .quantityPerBodyMass
    }
    
    var bodyMassTypePicker: some View {
        let binding = Binding<NutrientGoalBodyMassType>(
            get: { pickedBodyMassType },
            set: { newBodyMassType in
                withAnimation {
                    self.pickedBodyMassType = newBodyMassType
                }
                self.goal.nutrientGoalType = nutrientGoalType
            }
        )
        return Group {
            if isQuantityPerBodyMass {
                Menu {
                    Picker(selection: binding, label: EmptyView()) {
                        ForEach(NutrientGoalBodyMassType.allCases, id: \.self) {
                            Text($0.menuDescription).tag($0)
                        }
                    }
                } label: {
                    PickerLabel(
                        pickedBodyMassType.pickerDescription,
                        prefix: pickedBodyMassType.pickerPrefix
                    )
                }
                .animation(.none, value: pickedBodyMassType)
                .simultaneousGesture(TapGesture().onEnded {
                    Haptics.feedback(style: .soft)
                })
            }
        }
    }
    
    var workoutDurationUnitPicker: some View {
        let binding = Binding<WorkoutDurationUnit>(
            get: { pickedWorkoutDurationUnit },
            set: { newUnit in
                withAnimation {
                    self.pickedWorkoutDurationUnit = newUnit
                }
                self.goal.nutrientGoalType = nutrientGoalType
            }
        )
        return Group {
            if goal.goalSetType == .meal, pickedMealNutrientGoal == .quantityPerWorkoutDuration {
                Menu {
                    Picker(selection: binding, label: EmptyView()) {
                        ForEach(WorkoutDurationUnit.allCases, id: \.self) {
                            Text($0.pickerDescription).tag($0)
                        }
                    }
                } label: {
                    PickerLabel(
                        pickedWorkoutDurationUnit.menuDescription,
                        prefix: "per"
                    )
                }
                .animation(.none, value: pickedWorkoutDurationUnit)
                .simultaneousGesture(TapGesture().onEnded {
                    Haptics.feedback(style: .soft)
                })
                Text("of working out")
                    .foregroundColor(Color(.secondaryLabel))
            }
        }
    }
    
    var bodyMassUnitPicker: some View {
        let binding = Binding<WeightUnit>(
            get: { pickedBodyMassUnit },
            set: { newWeightUnit in
                withAnimation {
                    self.pickedBodyMassUnit = newWeightUnit
                }
                self.goal.nutrientGoalType = nutrientGoalType
            }
        )
        return Group {
            if isQuantityPerBodyMass {
                Menu {
                    Picker(selection: binding, label: EmptyView()) {
                        ForEach([WeightUnit.kg, WeightUnit.lb], id: \.self) {
                            Text($0.menuDescription).tag($0)
                        }
                    }
                } label: {
                    PickerLabel(
                        pickedBodyMassUnit.pickerDescription,
                        prefix: pickedBodyMassUnit.pickerPrefix
                    )
                }
                .animation(.none, value: pickedBodyMassUnit)
                .simultaneousGesture(TapGesture().onEnded {
                    Haptics.feedback(style: .soft)
                })
            }
        }
    }
}

extension GoalViewModel {
    @ViewBuilder
    var equivalentTextHStack: some View {
        if let equivalentUnitString {
            HStack(alignment: haveBothBounds ? .center : .firstTextBaseline) {
                Image(systemName: EqualSymbol)
                    .foregroundColor(Color(.tertiaryLabel))
                    .imageScale(.large)
                Spacer()
                if let lower = equivalentLowerBound {
                    if equivalentUpperBound == nil {
                        equivalentAccessoryText("at least")
                    }
                    HStack(spacing: 3) {
                        equivalentValueText(lower.formattedEnergy)
                        if equivalentUpperBound == nil {
                            equivalentUnitText(equivalentUnitString)
                        }
                    }
                }
                if let upper = equivalentUpperBound {
                    equivalentAccessoryText(equivalentLowerBound == nil ? "at most" : "to")
                    HStack(spacing: 3) {
                        equivalentValueText(upper.formattedEnergy)
                        equivalentUnitText(equivalentUnitString)
                    }
                }
            }
        }
    }
}

func equivalentAccessoryText(_ string: String) -> some View {
    Text(string)
//        .font(.system(.callout, design: .rounded, weight: .regular))
//        .foregroundColor(Color(.tertiaryLabel))
        .font(.system(.title3, design: .rounded, weight: .regular))
        .foregroundColor(Color(.tertiaryLabel))
}

func equivalentUnitText(_ string: String) -> some View {
    Text(string)
//        .font(.system(.subheadline, design: .rounded, weight: .regular))
//        .foregroundColor(Color(.tertiaryLabel))
        .font(.system(.body, design: .rounded, weight: .regular))
        .foregroundColor(Color(.tertiaryLabel))
}

func equivalentValueText(_ string: String) -> some View {
    Text(string)
        .monospacedDigit()
//        .font(.system(.body, design: .rounded, weight: .regular))
//        .foregroundColor(.secondary)
        .font(.system(.title2, design: .rounded, weight: .regular))
        .foregroundColor(.secondary)
}


extension BodyProfile {
    static func mock(
        restingEnergy: Double? = nil,
        restingEnergySource: RestingEnergySource = .userEntered,
        restingEnergyFormula: RestingEnergyFormula? = nil,
        activeEnergy: Double? = nil,
        activeEnergySource: ActiveEnergySource = .userEntered,
        weight: Double? = nil,
        lbm: Double? = nil
    ) -> BodyProfile {
        BodyProfile(
            energyUnit: .kcal,
            weightUnit: .kg,
            heightUnit: .cm,
            restingEnergy: restingEnergy,
            restingEnergySource: restingEnergySource,
            restingEnergyFormula: restingEnergyFormula,
            activeEnergy: activeEnergy,
            activeEnergySource: activeEnergySource,
            lbm: lbm,
            lbmSource: .userEntered,
            weight: weight,
            weightSource: .userEntered
        )
    }
}
