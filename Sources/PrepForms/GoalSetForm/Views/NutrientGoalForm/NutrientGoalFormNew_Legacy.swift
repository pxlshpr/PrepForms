//import SwiftUI
//import SwiftUISugar
//import SwiftHaptics
//import PrepDataTypes
//import PrepCoreDataStack
//
//public struct NutrientGoalForm_New_Legacy: View {
//
//    @Environment(\.dismiss) var dismiss
//    @Environment(\.colorScheme) var colorScheme
//
//    @EnvironmentObject var goalSet: GoalSetForm.Model
//    @ObservedObject var goal: GoalModel
//
//    let nutrientUnit: NutrientUnit
//
//    @State var pickedMealNutrientGoal: MealNutrientGoal
//    @State var pickedDietNutrientGoal: DietNutrientGoal
//    @State var pickedBodyMassType: BodyMassType
//    @State var pickedBodyMassUnit: BodyMassUnit
//
//    @State var energyValue: Double = 1000
//    @State var pickedEnergyUnit: EnergyUnit = .kcal
//
//    @State var pickedWorkoutDurationUnit: WorkoutDurationUnit
//
//    @State var showingLeanMassForm: Bool = false
//    @State var showingWeightForm: Bool = false
//
//    @State var shouldResignFocus = false
//
//    let didTapDelete: (GoalModel) -> ()
//
//    @StateObject var biometricsModel = BiometricsModel()
//
//    let didUpdateBiometrics = NotificationCenter.default.publisher(for: .didUpdateBiometrics)
//
//    public init(goal: GoalModel, didTapDelete: @escaping ((GoalModel) -> ())) {
//
//        self.goal = goal
//
//        self.nutrientUnit = goal.nutrientUnit ?? .g
//
//        let pickedDietNutrientGoal: DietNutrientGoal
//        let pickedMealNutrientGoal: MealNutrientGoal
//        if goal.goalSetType == .day {
//            pickedDietNutrientGoal = DietNutrientGoal(goalModel: goal) ?? .fixed
//            pickedMealNutrientGoal = .fixed
//        } else {
//            pickedMealNutrientGoal = MealNutrientGoal(goalModel: goal) ?? .fixed
//            pickedDietNutrientGoal = .fixed
//        }
//
//        let bodyMassType = goal.bodyMassType ?? .weight
//        let bodyMassUnit = goal.bodyMassUnit ?? .kg // TODO: User's default unit here
//        let workoutDurationUnit = goal.workoutDurationUnit ?? .min
//        _pickedMealNutrientGoal = State(initialValue: pickedMealNutrientGoal)
//        _pickedDietNutrientGoal = State(initialValue: pickedDietNutrientGoal)
//        _pickedBodyMassType = State(initialValue: bodyMassType)
//        _pickedBodyMassUnit = State(initialValue: bodyMassUnit)
//        _pickedWorkoutDurationUnit = State(initialValue: workoutDurationUnit)
//
//        self.didTapDelete = didTapDelete
//    }
//
//    public var body: some View {
//        navigationStack
//    }
//
//    enum Sheet: String, Identifiable {
//        case weightForm
//        case leanMassForm
//        case lowerBoundForm
//        case upperBoundForm
//        var id: String { rawValue }
//    }
//
//    var navigationStack: some View {
//        NavigationStack {
//            FormStyledScrollView {
//                valuesSection
//                unitSection
//                infoSection
//            }
//            .navigationTitle(goal.description)
//            .navigationBarTitleDisplayMode(.large)
//            .onDisappear(perform: disappeared)
//            .onReceive(didUpdateBiometrics, perform: didUpdateBiometrics)
////            .sheet(isPresented: $showingWeightForm) { weightForm }
////            .sheet(isPresented: $showingLeanMassForm) { leanMassForm }
//        }
//    }
//
//    var valuesSection: some View {
//
//        let valuesBinding = Binding<GoalValues>(
//            get: {
//                .init(lower: goal.lowerBound, upper: goal.upperBound)
//            },
//            set: { newPair in
//                goal.lowerBound = newPair.lower
//                goal.upperBound = newPair.upper
//            }
//        )
//
//        let equivalentValuesBinding = Binding<GoalValues>(
//            get: { .init(lower: goal.equivalentLowerBound, upper: goal.equivalentUpperBound) },
//            set: { _ in }
//        )
//
//        let unitStringsBinding = Binding<(String, String?)>(
//            get: { goal.unitStrings },
//            set: { _ in }
//        )
//
////        return GoalValuesSection(
////            values: valuesBinding,
////            equivalentValues: equivalentValuesBinding,
////            unitStrings: unitStringsBinding,
////            equivalentUnitString: goal.equivalentUnitString
////        )
//
//        return GoalValuesSection(goalModel: goal)
//    }
//
//    func disappeared() {
//        goal.validateNutrient()
//        goalSet.createImplicitGoals()
//    }
//
//    func didUpdateBiometrics(notification: Notification) {
//        withAnimation {
//            biometricsModel.load(UserManager.biometrics)
//        }
//    }
//
//    //MARK: - Sections
//
//    var unitSection: some View {
//
//        var contents: some View {
//            Group {
//                typePicker
//                bodyMassUnitPicker
//                bodyMassTypePicker
//                workoutDurationUnitPicker
//                energyButton
//                bodyMassButton
//            }
//        }
//
//        var scrollView: some View {
//            ScrollView(.horizontal, showsIndicators: false) {
//                HStack {
//                    contents
//                    Spacer()
//                }
//                .padding(.horizontal, 17)
//            }
//        }
//
//        var flowView: some View {
//            FlowView(alignment: .center, spacing: 10, padding: 37) {
//                contents
//            }
//            .padding(.horizontal, 17)
//        }
//
//        return FormStyledSection(horizontalPadding: 0) {
////            scrollView
//            flowView
//                .frame(maxWidth: .infinity)
//        }
//    }
//
//    var lowerBoundSection: some View {
//        let binding = Binding<Double?>(
//            get: { goal.lowerBound },
//            set: { newValue in
//                withAnimation {
//                    goal.lowerBound = newValue
//                }
//            }
//        )
//        var header: some View {
//            Text(goal.haveBothBounds ? "From" : "At least")
//        }
//        return FormStyledSection(header: header) {
//            HStack {
//                DoubleTextField(
//                    double: binding,
//                    placeholder: "Optional",
//                    shouldResignFocus: $shouldResignFocus
//                )
//            }
//        }
//    }
//
//    var equivalentSection: some View {
//        @ViewBuilder
//        var header: some View {
//            if isSynced {
//                Text("Currently Equals")
//            } else {
//                Text("Equals")
//            }
//        }
//
//        return Group {
//            if goal.haveEquivalentValues {
//                FormStyledSection(header: header) {
//                    goal.equivalentTextHStack
//                }
//            }
//        }
//    }
//
//    var upperBoundSection: some View {
//        let binding = Binding<Double?>(
//            get: { goal.upperBound },
//            set: { newValue in
//                withAnimation {
//                    goal.upperBound = newValue
//                }
//            }
//        )
//        var header: some View {
//            Text(goal.haveBothBounds ? "To" : "At most")
//        }
//        return FormStyledSection(header: header) {
//            HStack {
//                DoubleTextField(
//                    double: binding,
//                    placeholder: "Optional",
//                    shouldResignFocus: $shouldResignFocus
//                )
//            }
//        }
//    }
//
//    var bodyMassSection: some View {
//
//        return Group {
//            if isQuantityPerBodyMass {
////                FormStyledSection(header: Text("with")) {
//                FormStyledSection {
//                    HStack {
//                        Spacer()
//                        bodyMassButton
//                        Spacer()
//                    }
//                }
//            }
//        }
//    }
//
//    //MARK: - Decorator Views
//
//    var trailingContent: some ToolbarContent {
//        ToolbarItemGroup(placement: .navigationBarTrailing) {
//            syncedIndicator
//            menu
//        }
//    }
//
//    var menu: some View {
//        Menu {
//            Button(role: .destructive) {
//                Haptics.warningFeedback()
//                didTapDelete(goal)
//            } label: {
//                Label("Remove Goal", systemImage: "minus.circle")
//            }
//        } label: {
//            Image(systemName: "ellipsis")
//        }
//        .contentShape(Rectangle())
//        .simultaneousGesture(TapGesture().onEnded {
//            Haptics.feedback(style: .soft)
//        })
//    }
//
//    @ViewBuilder
//    var syncedIndicator: some View {
//        if isSynced {
//            appleHealthBolt
//            Text("Synced")
//                .font(.footnote)
//                .textCase(.uppercase)
//                .foregroundColor(Color(.tertiaryLabel))
//        }
//    }
//
//    var unitsFooterString: String? {
//
//        guard !isSynced else {
//            var component: String {
//                switch nutrientGoalType {
//                case .quantityPerBodyMass(let bodyMass, _):
//                    return bodyMass.description
//                case .percentageOfEnergy:
//                    return "maintenance energy (which your energy goal is based on)"
//                default:
//                    return ""
//                }
//            }
//
//            return "Your \(component) is synced with the Health App. This goal will automatically adjust when it changes."
//        }
//
//        switch nutrientGoalType {
//        case .percentageOfEnergy:
//            return "Your energy goal is being used to calculate this goal."
//        case .quantityPerWorkoutDuration(_):
//            return "Your planned workout duration will be used to calculate this goal. You can specify it when setting this type on a meal."
//        case .quantityPerBodyMass:
//            return nil
//        case .quantityPerEnergy:
//            return nil
//        case .fixed:
//            return nil
//        default:
//            return nil
//        }
//    }
//
//    @ViewBuilder
//    var unitsFooter: some View {
//        if let unitsFooterString {
//            Text(unitsFooterString)
//        } else {
//            EmptyView()
//        }
//    }
//
//    //MARK: - Sheets
//
//    var weightForm: some View {
//        NutrientWeightForm()
//            .environmentObject(biometricsModel)
//    }
//
//    var leanMassForm: some View {
//        NutrientLeanBodyMassForm()
//            .environmentObject(biometricsModel)
//    }
//
//    //MARK: - Convenience
//
//    var nutrientGoalType: NutrientGoalType? {
//        if goal.goalSetType == .meal {
//
//            switch pickedMealNutrientGoal {
//            case .fixed:
//                return .fixed
//            case .quantityPerWorkoutDuration:
//                return .quantityPerWorkoutDuration(pickedWorkoutDurationUnit)
//            case .quantityPerBodyMass:
//                return .quantityPerBodyMass(pickedBodyMassType, pickedBodyMassUnit)
//            }
//
//        } else {
//            switch pickedDietNutrientGoal {
//            case .fixed:
//                return .fixed
//            case .quantityPerBodyMass:
//                return .quantityPerBodyMass(pickedBodyMassType, pickedBodyMassUnit)
//            case .percentageOfEnergy:
//                return .percentageOfEnergy
//            case .quantityPerEnergy:
//                return .quantityPerEnergy(energyValue, pickedEnergyUnit)
//            }
//        }
//    }
//
//    var haveBodyMass: Bool {
//        switch pickedBodyMassType {
//        case .weight:
//            return UserManager.biometrics.hasWeight == true
//        case .leanMass:
//            return UserManager.biometrics.hasLBM == true
//        }
//    }
//
//    var isSynced: Bool {
//        goal.isSynced
//    }
//
//    var bodyMassFormattedWithUnit: String {
//        switch pickedBodyMassType {
//        case .weight:
//            guard let amount = UserManager.biometrics.weight?.amount,
//                  let unit = UserManager.biometrics.weight?.unit
//            else { return "" }
//            return amount.rounded(toPlaces: 1).cleanAmount + " \(unit.shortDescription)"
//
//        case .leanMass:
//            guard let amount = UserManager.biometrics.leanBodyMass?.amount,
//                  let unit = UserManager.biometrics.leanBodyMass?.unit
//            else { return "" }
//            return amount.rounded(toPlaces: 1).cleanAmount + " \(unit.shortDescription)"
//        }
//    }
//
//    //MARK: - Buttons
//
//    @ViewBuilder
//    var energyButton: some View {
//        if pickedDietNutrientGoal == .quantityPerEnergy {
//            Button {
//
//            } label: {
//                PickerLabel(
//                    energyValue.cleanAmount + " " + pickedEnergyUnit.shortDescription,
//                    prefix: "per",
//                    systemImage: "flame.fill",
////                    backgroundColor: Color(.tertiaryLabel),
//                    imageScale: .small
//                )
//            }
//            .disabled(true)
//        }
//    }
//
//    var bodyMassButton: some View {
//
//        @ViewBuilder
//        var label: some View {
//            if haveBodyMass {
//                if goal.bodyMassIsSyncedWithHealth {
//                    PickerLabel(
//                        bodyMassFormattedWithUnit,
//                        prefix: "\(pickedBodyMassType.description)",
//                        systemImage: "figure.arms.open",
//                        imageColor: Color(hex: "F3DED7"),
//                        backgroundGradientTop: HealthTopColor,
//                        backgroundGradientBottom: HealthBottomColor,
//                        foregroundColor: .white,
//                        prefixColor: Color(hex: "F3DED7"),
//                        imageScale: .medium
//                    )
//                } else {
//                    PickerLabel(
//                        bodyMassFormattedWithUnit,
//                        prefix: "\(pickedBodyMassType.description)",
//                        systemImage: "figure.arms.open",
////                        imageColor: Color(.tertiaryLabel),
//                        imageColor: .accentColor,
//                        backgroundColor: .accentColor,
//                        foregroundColor: .accentColor,
//                        imageScale: .medium
//                    )
//                }
//            } else {
//                PickerLabel(
//                    "\(pickedBodyMassType.description)",
//                    prefix: "set",
//                    systemImage: "figure.arms.open",
//                    imageColor: Color.white.opacity(0.75),
//                    backgroundColor: .accentColor,
//                    foregroundColor: .white,
//                    prefixColor: Color.white.opacity(0.75),
//                    imageScale: .medium
//                )
//            }
//        }
//
//        var button: some View {
//            Button {
//                Haptics.feedback(style: .soft)
//                shouldResignFocus.toggle()
//                switch pickedBodyMassType {
//                case .weight:
//                    showingWeightForm = true
//                case .leanMass:
//                    showingLeanMassForm = true
//                }
//            } label: {
//                label
//            }
//        }
//
//        return Group {
//            if isQuantityPerBodyMass {
//                button
//            }
//        }
//    }
//
//    var swapValuesButton: some View {
//        VStack(spacing: 7) {
//            Text("")
//            if goal.lowerBound != nil, goal.upperBound == nil {
//                Button {
//                    Haptics.feedback(style: .rigid)
//                    goal.upperBound = goal.lowerBound
//                    goal.lowerBound = nil
//                } label: {
//                    Image(systemName: "rectangle.righthalf.inset.filled.arrow.right")
//                        .foregroundColor(.accentColor)
//                }
//            } else if goal.upperBound != nil, goal.lowerBound == nil {
//                Button {
//                    Haptics.feedback(style: .rigid)
//                    goal.lowerBound = goal.upperBound
//                    goal.upperBound = nil
//                } label: {
//                    Image(systemName: "rectangle.lefthalf.inset.filled.arrow.left")
//                        .foregroundColor(.accentColor)
//                }
//            }
//        }
//        .padding(.top, 10)
//        .frame(width: 16, height: 20)
//    }
//
//    //MARK: - Pickers
//
//    @ViewBuilder
//    var typePicker: some View {
//        if goal.goalSetType == .meal {
//            mealTypePicker
//        } else {
//            dietTypePicker
//        }
//    }
//
//    var mealTypePicker: some View {
//        let binding = Binding<MealNutrientGoal>(
//            get: { pickedMealNutrientGoal },
//            set: { newType in
//                withAnimation {
//                    self.pickedMealNutrientGoal = newType
//                }
//                self.goal.nutrientGoalType = nutrientGoalType
//            }
//        )
//        return Menu {
//            Picker(selection: binding, label: EmptyView()) {
//                ForEach(MealNutrientGoal.allCases, id: \.self) {
//                    Text($0.menuDescription(nutrientUnit: nutrientUnit)).tag($0)
//                }
//            }
//        } label: {
//            defaultPickerLabel(
//                pickedDietNutrientGoal.pickerDescription(nutrientUnit: nutrientUnit)
//            )
//        }
//        .animation(.none, value: pickedMealNutrientGoal)
//        .contentShape(Rectangle())
//        .simultaneousGesture(TapGesture().onEnded {
//            Haptics.feedback(style: .soft)
//        })
//    }
//
//    var dietTypePicker: some View {
//        let binding = Binding<DietNutrientGoal>(
//            get: { pickedDietNutrientGoal },
//            set: { newType in
//                withAnimation {
//                    self.pickedDietNutrientGoal = newType
//                    self.goal.nutrientGoalType = nutrientGoalType
//                }
//            }
//        )
//
//        return Menu {
//            Picker(selection: binding, label: EmptyView()) {
//                ForEach(DietNutrientGoal.allCases, id: \.self) {
//                    Text($0.menuDescription(nutrientUnit: nutrientUnit)).tag($0)
//                }
//            }
//        } label: {
//            if pickedDietNutrientGoal == .percentageOfEnergy {
//                if goalSet.energyGoal?.isSynced == true {
//                    PickerLabel(
//                        pickedDietNutrientGoal.pickerDescription(nutrientUnit: nutrientUnit),
//                        systemImage: "flame.fill",
//                        imageColor: Color(hex: "F3DED7"),
//                        backgroundGradientTop: HealthTopColor,
//                        backgroundGradientBottom: HealthBottomColor,
//                        foregroundColor: .white,
//                        imageScale: .small
//                    )
//                } else {
//                    defaultPickerLabel(
//                        pickedDietNutrientGoal.pickerDescription(nutrientUnit: nutrientUnit),
//                        systemImage: "flame.fill"
//                    )
//                }
//
//            } else {
//                defaultPickerLabel(pickedDietNutrientGoal.pickerDescription(nutrientUnit: nutrientUnit))
//            }
//        }
//        .animation(.none, value: pickedDietNutrientGoal)
//        .contentShape(Rectangle())
//        .simultaneousGesture(TapGesture().onEnded {
//            Haptics.feedback(style: .soft)
//        })
//    }
//
//    var isQuantityPerBodyMass: Bool {
//        pickedDietNutrientGoal == .quantityPerBodyMass
//        || pickedMealNutrientGoal == .quantityPerBodyMass
//    }
//
//    var bodyMassTypePicker: some View {
//        let binding = Binding<BodyMassType>(
//            get: { pickedBodyMassType },
//            set: { newBodyMassType in
//                withAnimation {
//                    self.pickedBodyMassType = newBodyMassType
//                }
//                self.goal.nutrientGoalType = nutrientGoalType
//            }
//        )
//        return Group {
//            if isQuantityPerBodyMass {
//                Menu {
//                    Picker(selection: binding, label: EmptyView()) {
//                        ForEach(BodyMassType.allCases, id: \.self) {
//                            Text($0.menuDescription).tag($0)
//                        }
//                    }
//                } label: {
//                    defaultPickerLabel(
//                        pickedBodyMassType.pickerDescription,
//                        prefix: pickedBodyMassType.pickerPrefix
//                    )
//                }
//                .animation(.none, value: pickedBodyMassType)
//                .contentShape(Rectangle())
//                .simultaneousGesture(TapGesture().onEnded {
//                    Haptics.feedback(style: .soft)
//                })
//            }
//        }
//    }
//
//    var workoutDurationUnitPicker: some View {
//        let binding = Binding<WorkoutDurationUnit>(
//            get: { pickedWorkoutDurationUnit },
//            set: { newUnit in
//                withAnimation {
//                    self.pickedWorkoutDurationUnit = newUnit
//                }
//                self.goal.nutrientGoalType = nutrientGoalType
//            }
//        )
//        return Group {
//            if goal.goalSetType == .meal, pickedMealNutrientGoal == .quantityPerWorkoutDuration {
//                Menu {
//                    Picker(selection: binding, label: EmptyView()) {
//                        ForEach(WorkoutDurationUnit.allCases, id: \.self) {
//                            Text($0.pickerDescription).tag($0)
//                        }
//                    }
//                } label: {
//                    defaultPickerLabel(
//                        pickedWorkoutDurationUnit.menuDescription,
//                        prefix: "per"
//                    )
//                }
//                .animation(.none, value: pickedWorkoutDurationUnit)
//                .contentShape(Rectangle())
//                .simultaneousGesture(TapGesture().onEnded {
//                    Haptics.feedback(style: .soft)
//                })
//                Text("of working out")
//                    .foregroundColor(Color(.secondaryLabel))
//            }
//        }
//    }
//
//    var bodyMassUnitPicker: some View {
//        let binding = Binding<BodyMassUnit>(
//            get: { pickedBodyMassUnit },
//            set: { newWeightUnit in
//                withAnimation {
//                    self.pickedBodyMassUnit = newWeightUnit
//                }
//                self.goal.nutrientGoalType = nutrientGoalType
//            }
//        )
//        return Group {
//            if isQuantityPerBodyMass {
//                Menu {
//                    Picker(selection: binding, label: EmptyView()) {
//                        ForEach(BodyMassUnit.allCases, id: \.self) {
//                            Text($0.menuDescription).tag($0)
//                        }
//                    }
//                } label: {
//                    defaultPickerLabel(
//                        pickedBodyMassUnit.pickerDescription,
//                        prefix: pickedBodyMassUnit.pickerPrefix
//                    )
//                }
//                .animation(.none, value: pickedBodyMassUnit)
//                .contentShape(Rectangle())
//                .simultaneousGesture(TapGesture().onEnded {
//                    Haptics.feedback(style: .soft)
//                })
//            }
//        }
//    }
//
//    func defaultPickerLabel(
//        _ string: String,
//        prefix: String? = nil,
//        systemImage: String? = "chevron.up.chevron.down"
//    ) -> some View {
//        PickerLabel(
//            string,
//            prefix: prefix,
//            systemImage: systemImage
////            backgroundColor: .accentColor,
////            foregroundColor: .accentColor
//        )
//    }
//
//    @ViewBuilder
//    var infoSection: some View {
//        if let unitsFooterString {
//            Text(unitsFooterString)
//                .multilineTextAlignment(.leading)
//                .foregroundColor(.secondary)
//                .frame(maxWidth: .infinity)
//                .padding(.vertical, 15)
//                .padding(.horizontal, 16)
//                .background(
//                    RoundedRectangle(cornerRadius: 20, style: .continuous)
//                        .foregroundColor(
//                            Color(.quaternarySystemFill)
//                                .opacity(colorScheme == .dark ? 0.5 : 1)
//                        )
//                )
//                .cornerRadius(10)
//                .padding(.bottom, 10)
//                .padding(.horizontal, 17)
//        }
//    }
//}
