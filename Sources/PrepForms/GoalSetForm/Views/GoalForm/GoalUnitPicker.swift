import SwiftUI
import SwiftUISugar
import SwiftHaptics
import PrepDataTypes
import PrepCoreDataStack

struct GoalUnitPicker: View {
    
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject var model: GoalModel
    @State var presentedSheet: Sheet? = nil
    
    @State var type: GoalType
    
    //TODO: Replace all these
    @State var pickedMealEnergyGoalType: MealEnergyTypeOption
    @State var pickedDelta: EnergyDeltaOption
    @State var pickedMealNutrientGoal: MealNutrientGoal
    @State var pickedDietNutrientGoal: DietNutrientGoal
    @State var pickedBodyMassType: NutrientGoalBodyMassType
    @State var pickedBodyMassUnit: BodyMassUnit
    @State var pickedEnergyUnit: EnergyUnit = .kcal
    @State var pickedWorkoutDurationUnit: WorkoutDurationUnit
    @State var energyValue: Double = 1000
    
    init(model: GoalModel) {
        self.model = model
        _type = State(initialValue: model.type)
        
        let mealEnergyGoalType = MealEnergyTypeOption(goalModel: model) ?? .fixed
        let dietEnergyGoalType = DietEnergyTypeOption(goalModel: model) ?? .fixed
        let delta = EnergyDeltaOption(goalModel: model) ?? .below
        _pickedMealEnergyGoalType = State(initialValue: mealEnergyGoalType)
        _pickedDelta = State(initialValue: delta)
        
        
        let pickedDietNutrientGoal: DietNutrientGoal
        let pickedMealNutrientGoal: MealNutrientGoal
        if model.goalSetType == .day {
            pickedDietNutrientGoal = DietNutrientGoal(goalModel: model) ?? .fixed
            pickedMealNutrientGoal = .fixed
        } else {
            pickedMealNutrientGoal = MealNutrientGoal(goalModel: model) ?? .fixed
            pickedDietNutrientGoal = .fixed
        }
        let bodyMassType = model.bodyMassType ?? .weight
        let bodyMassUnit = model.bodyMassUnit ?? .kg // TODO: User's default unit here
        let workoutDurationUnit = model.workoutDurationUnit ?? .min
        _pickedMealNutrientGoal = State(initialValue: pickedMealNutrientGoal)
        _pickedDietNutrientGoal = State(initialValue: pickedDietNutrientGoal)
        _pickedBodyMassType = State(initialValue: bodyMassType)
        _pickedBodyMassUnit = State(initialValue: bodyMassUnit)
        _pickedWorkoutDurationUnit = State(initialValue: workoutDurationUnit)
        
    }
    
    var body: some View {
        quickForm
            .onChange(of: pickedMealEnergyGoalType) { _ in changed() }
            .onChange(of: pickedDelta) { _ in changed() }
            .onChange(of: pickedMealNutrientGoal) { _ in changed() }
            .onChange(of: pickedDietNutrientGoal) { _ in changed() }
            .onChange(of: pickedBodyMassType) { _ in changed() }
            .onChange(of: pickedBodyMassUnit) { _ in changed() }
            .onChange(of: pickedWorkoutDurationUnit) { _ in changed() }
            .sheet(item: $presentedSheet) { sheet(for: $0) }
            .presentationDetents([.height(300)])
    }
    
    func changed() {
        Haptics.feedback(style: .soft)
    }
    
    var trailingContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                Haptics.feedback(style: .soft)
                dismiss()
            } label: {
                CloseButtonLabel(forNavigationBar: true)
            }
        }
    }
    
    func didTapSave() {
        withAnimation {
            model.type = type
        }
        dismiss()
    }
    
    var hasParameters: Bool {
        
        func nutrientGoalTypeHasParameters(_ nutrientGoalType: NutrientGoalType) -> Bool {
            switch nutrientGoalType {
            case .quantityPerBodyMass(let bodyMassType, _):
                switch bodyMassType {
                case .weight:
                    return UserManager.biometrics.hasWeight
                case .leanMass:
                    return UserManager.biometrics.hasLBM
                }
            case .quantityPerEnergy, .percentageOfEnergy:
                return model.goalSetModel.energyGoal != nil
            default:
                return true
            }
        }
        
        switch type {
        case .energy(let energyGoalType):
            switch energyGoalType {
            case .fromMaintenance, .percentFromMaintenance:
                return true
            default:
                return false
            }
        case .macro(let nutrientGoalType, _):
            return nutrientGoalTypeHasParameters(nutrientGoalType)
        case .micro(let nutrientGoalType, _, _):
            return nutrientGoalTypeHasParameters(nutrientGoalType)
        }
    }
    
    var quickForm: some View {
        
        let saveAction = Binding<FormConfirmableAction?>(
            get: {
                FormConfirmableAction(
                    position: .bottomFilled,
                    confirmationButtonTitle: "Done",
                    isDisabled: !hasParameters,
                    handler: didTapSave
                )
            },
            set: { _ in }
        )
        return QuickForm(
            title: "Unit",
            saveAction: saveAction
        ) {
            pickerSection
            Spacer()
        }
    }
    
    var navigationStack: some View {
        var contents: some View {
            VStack {
                pickerSection
                Spacer()
                largeDoneButton
            }
            .background(FormBackground().edgesIgnoringSafeArea(.all))
            .frame(maxHeight: .infinity)
        }
        
        return NavigationStack {
            contents
                .navigationTitle("Unit")
                .navigationBarTitleDisplayMode(.inline)
            //                .toolbar { doneButtonToolbarContent }
        }
    }
    
    var pickerSection: some View {
        FormStyledSection {
            FlowView(alignment: .leading, spacing: 10, padding: 37) {
                pickers
            }
        }
    }
    
    var doneButton: some View {
        FormInlineDoneButton(disabled: false) {
            dismiss()
        }
    }
    
    var largeDoneButton: some View {
        var shadowOpacity: CGFloat { 0 }
        var buttonHeight: CGFloat { 52 }
        var buttonCornerRadius: CGFloat { 10 }
        var shadowSize: CGFloat { 2 }
        var foregroundColor: Color {
            //            (colorScheme == .light && saveIsDisabled) ? .black : .white
            .white
        }
        
        return Button {
            Haptics.feedback(style: .soft)
            dismiss()
        } label: {
            Text("Done")
                .bold()
                .foregroundColor(foregroundColor)
                .frame(height: buttonHeight)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: buttonCornerRadius)
                        .foregroundStyle(Color.accentColor.gradient)
                        .shadow(color: Color(.black).opacity(shadowOpacity), radius: shadowSize, x: 0, y: shadowSize)
                )
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 20)
        //        .position(x: xPosition, y: yPosition)
        //        .disabled(saveIsDisabled)
        //        .opacity(saveIsDisabled ? (colorScheme == .light ? 0.2 : 0.2) : 1)
    }
    
    @ViewBuilder
    var pickers: some View {
        if model.type.isEnergy {
            energyPickers
        } else {
            nutrientPickers
        }
    }
    
    var energyPickers: some View {
        Group {
            energyTypePicker
            deltaPicker
            tdeeButton
        }
    }
    
    var nutrientPickers: some View {
        Group {
            nutrientTypePicker
            bodyMassUnitPicker
            bodyMassTypePicker
            workoutDurationUnitPicker
            energyButton
            bodyMassButton
        }
    }
    
    @ViewBuilder
    func sheet(for sheet: Sheet) -> some View {
        switch sheet {
        case .tdee:
            EmptyView()
        case .weight:
            EmptyView()
        case .leanBodyMass:
            EmptyView()
            
        case .deltaPicker:
            deltaPickerSheet
        case .dayEnergyPicker:
            dayEnergyPickerSheet
        case .dayNutrientPicker:
            dayNutrientPickerSheet
        case .mealEnergyPicker:
            EmptyView()
        case .mealNutrientPicker:
            mealNutrientPickerSheet
        case .bodyMassTypePicker:
            bodyMassTypePickerSheet
        case .bodyMassUnitPicker:
            bodyMassUnitPickerSheet
        case .workoutDurationUnitPicker:
            workoutDurationUnitPickerSheet
        }
    }
    
    func appeared() {
    }
    
    func dietEnergyGoalChanged(_ newValue: DietEnergyTypeOption) {
        //        model.energyGoalType = self.energyGoalType
    }
    
    func mealEnergyGoalChanged(_ newValue: MealEnergyTypeOption) {
        //        model.energyGoalType = self.energyGoalType
    }
    
    func deltaChanged(to newValue: EnergyDeltaOption) {
        //        model.energyGoalType = self.energyGoalType
    }
    
    func present(_ sheet: Sheet) {
        
        func present() {
            Haptics.feedback(style: .soft)
            presentedSheet = sheet
        }
        
        func delayedPresent() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                present()
            }
        }
        
        if presentedSheet != nil {
            presentedSheet = nil
            delayedPresent()
        } else {
            present()
        }
    }
    
    var shouldShowEnergyDeltaElements: Bool {
        model.goalSetType == .day  && type.usesEnergyDelta
    }
    
    var energyUnit: EnergyUnit {
        model.energyUnit ?? .kcal
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
    
    var isQuantityPerBodyMass: Bool {
        pickedDietNutrientGoal == .quantityPerBodyMass
        || pickedMealNutrientGoal == .quantityPerBodyMass
    }
}

//MARK: - Picker Buttons
extension GoalUnitPicker {
    
    var energyTypePicker: some View {
        var dayPicker: some View {
            Button {
                present(.dayEnergyPicker)
            } label: {
                PickerLabel(type.pickerDiscription)
            }
        }
        
        var mealPicker: some View {
            /// We don't have any options so we're leaving this here as a placeholder for now
            PickerLabel(
                pickedMealEnergyGoalType.description(energyUnit: UserManager.energyUnit),
                systemImage: nil
            )
            .animation(.none, value: pickedMealEnergyGoalType)
        }
        
        
        return Group {
            if model.goalSetType == .meal {
                mealPicker
            } else {
                dayPicker
            }
        }
    }
    
    var nutrientTypePicker_new: some View {
        
        @ViewBuilder
        var label: some View {
            if model.goalSetType == .meal {
                defaultPickerLabel(
                    pickedDietNutrientGoal.pickerDescription(nutrientUnit: nutrientUnit)
                )
            } else {
                if pickedDietNutrientGoal == .percentageOfEnergy {
                    if model.goalSetModel.energyGoal?.isSynced == true {
                        PickerLabel(
                            pickedDietNutrientGoal.pickerDescription(nutrientUnit: nutrientUnit),
                            systemImage: "flame.fill",
                            imageColor: Color(hex: "F3DED7"),
                            backgroundGradientTop: HealthTopColor,
                            backgroundGradientBottom: HealthBottomColor,
                            foregroundColor: .white,
                            imageScale: .small
                        )
                    } else {
                        defaultPickerLabel(
                            pickedDietNutrientGoal.pickerDescription(nutrientUnit: nutrientUnit),
                            systemImage: "flame.fill"
                        )
                    }
                    
                } else {
                    defaultPickerLabel(pickedDietNutrientGoal.pickerDescription(nutrientUnit: nutrientUnit))
                }
            }
        }
        
        return Button {
            present(model.isForMeal ? .mealNutrientPicker : .dayNutrientPicker)
        } label: {
            label
        }
    }
    
    var nutrientTypePicker: some View {
        var dayPicker: some View {
            
            @ViewBuilder
            var label: some View {
                if pickedDietNutrientGoal == .percentageOfEnergy {
                    if model.goalSetModel.energyGoal?.isSynced == true {
                        PickerLabel(
                            pickedDietNutrientGoal.pickerDescription(nutrientUnit: nutrientUnit),
                            systemImage: "flame.fill",
                            imageColor: Color(hex: "F3DED7"),
                            backgroundGradientTop: HealthTopColor,
                            backgroundGradientBottom: HealthBottomColor,
                            foregroundColor: .white,
                            imageScale: .small
                        )
                    } else {
                        defaultPickerLabel(
                            pickedDietNutrientGoal.pickerDescription(nutrientUnit: nutrientUnit),
                            systemImage: "flame.fill"
                        )
                    }
                    
                } else {
                    defaultPickerLabel(pickedDietNutrientGoal.pickerDescription(nutrientUnit: nutrientUnit))
                }
            }
            
            return Button {
                present(.dayNutrientPicker)
            } label: {
                label
            }
        }
        
        var mealPicker: some View {
            Button {
                present(.mealNutrientPicker)
            } label: {
                defaultPickerLabel(
                    pickedDietNutrientGoal.pickerDescription(nutrientUnit: nutrientUnit)
                )
            }
        }
        
        
        return Group {
            if model.goalSetType == .meal {
                mealPicker
            } else {
                dayPicker
            }
        }
    }
    
    @ViewBuilder
    var deltaPicker: some View {
        if shouldShowEnergyDeltaElements {
            Button {
                present(.deltaPicker)
            } label: {
                PickerLabel(
                    pickedDelta.description,
                    prefixImage: pickedDelta.systemImage
                )
            }
        }
    }
    
    @ViewBuilder
    var bodyMassTypePicker: some View {
        if isQuantityPerBodyMass {
            Button {
                present(.bodyMassUnitPicker)
            } label: {
                defaultPickerLabel(
                    pickedBodyMassUnit.pickerDescription,
                    prefix: pickedBodyMassUnit.pickerPrefix
                )
            }
        }
    }
    
    @ViewBuilder
    var bodyMassUnitPicker: some View {
        if isQuantityPerBodyMass {
            Button {
                present(.bodyMassTypePicker)
            } label: {
                defaultPickerLabel(
                    pickedBodyMassType.pickerDescription,
                    prefix: pickedBodyMassType.pickerPrefix
                )
            }
        }
    }
    
    @ViewBuilder
    var workoutDurationUnitPicker: some View {
        if model.goalSetType == .meal, pickedMealNutrientGoal == .quantityPerWorkoutDuration {
            Button {
                present(.workoutDurationUnitPicker)
            } label: {
                defaultPickerLabel(
                    pickedWorkoutDurationUnit.menuDescription,
                    prefix: "per"
                )
            }
        }
    }
}

//MARK: - Picker Sheets
extension GoalUnitPicker {
    
    var deltaPickerSheet: some View {
        EmptyView()
//        PickerSheet<EnergyDeltaOption>(
//            title: "Relative Energy",
//            items: EnergyDeltaOption.allCases,
//            pickedItem: $pickedDelta,
//            didPick: { pickedItem in
//                self.pickedDelta = pickedItem
//            }
//        )
    }
    
    var dayEnergyPickerSheet: some View {
        
        let items: [PickerItem] = GoalType.dietEnergyPickerItems
        
        let binding = Binding<PickerItem>(
            get: { type.pickerItem },
            set: { _ in }
        )
        
        return PickerSheet(
            title: "Choose a Goal Type",
            items: items,
            pickedItem: binding,
            didPick: {
                self.type = type.applyingPickedItem($0)
            }
        )
    }
    
    var dayNutrientPickerSheet: some View {
        
        let items = GoalType.dietNutrientPickerItems(with: nutrientUnit)

        let binding = Binding<PickerItem>(
            get: { type.pickerItem },
            set: { _ in }
        )

        return PickerSheet(
            title: "Choose a Goal Type",
            items: items,
            pickedItem: binding,
            didPick: {
                self.type = type.applyingPickedItem($0)
            }
        )
    }

    var mealNutrientPickerSheet: some View {
        EmptyView()
//        PickerSheet<MealNutrientGoal>(
//            title: "Nutrient Goal Type",
//            items: MealNutrientGoal.allCases,
//            pickedItem: $pickedMealNutrientGoal,
//            didPick: { pickedItem in
//                self.pickedMealNutrientGoal = pickedItem
//            }
//        )
    }

    var bodyMassTypePickerSheet: some View {
        EmptyView()
//        PickerSheet<NutrientGoalBodyMassType>(
//            title: "Choose a body mass type",
//            items: NutrientGoalBodyMassType.allCases,
//            pickedItem: $pickedBodyMassType,
//            didPick: { pickedItem in
//                self.pickedBodyMassType = pickedItem
//            }
//        )
    }

    var bodyMassUnitPickerSheet: some View {
        EmptyView()
//        PickerSheet<BodyMassUnit>(
//            title: "Choose a body mass unit",
//            items: BodyMassUnit.allCases,
//            pickedItem: $pickedBodyMassUnit,
//            didPick: { pickedItem in
//                self.pickedBodyMassUnit = pickedItem
//            }
//        )
    }

    var workoutDurationUnitPickerSheet: some View {
        EmptyView()
//        PickerSheet<WorkoutDurationUnit>(
//            title: "Workout Duration in",
//            items: WorkoutDurationUnit.allCases,
//            pickedItem: $pickedWorkoutDurationUnit,
//            didPick: { pickedItem in
//                self.pickedWorkoutDurationUnit = pickedItem
//            }
//        )
    }
    
    func defaultPickerLabel(
        _ string: String,
        prefix: String? = nil,
        systemImage: String? = "chevron.up.chevron.down"
    ) -> some View {
        PickerLabel(string, prefix: prefix, systemImage: systemImage)
    }
    
    //MARK: Biometric Buttons
    
    @ViewBuilder
    var tdeeButton: some View {
        if shouldShowEnergyDeltaElements {
            Button {
                Haptics.feedback(style: .soft)
                present(.tdee)
            } label: {
                if let formattedTDEE = UserManager.biometrics.formattedTDEEWithUnit {
                    if UserManager.biometrics.syncsMaintenanceEnergy {
                        PickerLabel(
                            formattedTDEE,
                            prefix: "maintenance",
                            prefixImage: "flame.fill",
                            systemImage: "chevron.forward",
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
                            prefixImage: "flame.fill",
                            systemImage: "chevron.forward",
                            imageColor: Color(.tertiaryLabel),
                            imageScale: .small
                        )
                    }
                } else {
                    PickerLabel(
                        "maintenance",
                        prefix: "set",
                        prefixImage: "flame.fill",
                        systemImage: "chevron.forward",
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
    
    @ViewBuilder
    var energyButton: some View {
        if pickedDietNutrientGoal == .quantityPerEnergy {
            Button {
                
            } label: {
                PickerLabel(
                    energyValue.cleanAmount + " " + pickedEnergyUnit.shortDescription,
                    prefix: "per",
                    systemImage: "flame.fill",
//                    backgroundColor: Color(.tertiaryLabel),
                    imageScale: .small
                )
            }
            .disabled(true)
        }
    }
    
    var bodyMassButton: some View {
        
        @ViewBuilder
        var label: some View {
            if haveBodyMass {
                if model.bodyMassIsSyncedWithHealth {
                    PickerLabel(
                        bodyMassFormattedWithUnit,
                        prefix: "\(pickedBodyMassType.description)",
                        systemImage: "figure.arms.open",
                        imageColor: Color(hex: "F3DED7"),
                        backgroundGradientTop: HealthTopColor,
                        backgroundGradientBottom: HealthBottomColor,
                        foregroundColor: .white,
                        prefixColor: Color(hex: "F3DED7"),
                        imageScale: .medium
                    )
                } else {
                    PickerLabel(
                        bodyMassFormattedWithUnit,
                        prefix: "\(pickedBodyMassType.description)",
                        systemImage: "figure.arms.open",
                        //                        imageColor: Color(.tertiaryLabel),
                        imageColor: .accentColor,
                        backgroundColor: .accentColor,
                        foregroundColor: .accentColor,
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
        
        var button: some View {
            Button {
                //                Haptics.feedback(style: .soft)
                //                shouldResignFocus.toggle()
                //                switch pickedBodyMassType {
                //                case .weight:
                //                    showingWeightForm = true
                //                case .leanMass:
                //                    showingLeanMassForm = true
                //                }
            } label: {
                label
            }
        }
        
        return Group {
            if isQuantityPerBodyMass {
                button
            }
        }
    }
    
    var nutrientGoalType: NutrientGoalType? {
        if model.goalSetType == .meal {
            
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
            return UserManager.biometrics.hasWeight == true
        case .leanMass:
            return UserManager.biometrics.hasLBM == true
        }
    }
    
    var isSynced: Bool {
        model.isSynced
    }
    
    var nutrientUnit: NutrientUnit {
        model.nutrientUnit ?? .g
    }
    
    var bodyMassFormattedWithUnit: String {
        switch pickedBodyMassType {
        case .weight:
            guard let amount = UserManager.biometrics.weight?.amount,
                  let unit = UserManager.biometrics.weight?.unit
            else { return "" }
            return amount.rounded(toPlaces: 1).cleanAmount + " \(unit.shortDescription)"
            
        case .leanMass:
            guard let amount = UserManager.biometrics.leanBodyMass?.amount,
                  let unit = UserManager.biometrics.leanBodyMass?.unit
            else { return "" }
            return amount.rounded(toPlaces: 1).cleanAmount + " \(unit.shortDescription)"
        }
    }
    
    enum Sheet: String, Identifiable {
        case tdee
        case leanBodyMass
        case weight
        
        case dayEnergyPicker
        case dayNutrientPicker
        case deltaPicker
        case mealEnergyPicker
        case mealNutrientPicker
        case bodyMassTypePicker
        case bodyMassUnitPicker
        case workoutDurationUnitPicker

        var id: String { rawValue }
    }
}

extension EnergyDeltaOption: PickableItem {

    var pickerTitle: String {
        switch self {
        case .above:
            return "above"
        case .below:
            return "below"
        case .around:
            return "within"
        }
    }

    var pickerSystemImage: String? {
        self.systemImage
    }

    var pickerDetail: String? {
        switch self {
        case .below:
            return "Use this to specify a deficit from your maintenance."
        case .above:
            return "Use this to specify a surplus from your maintenance."
        case .around:
            return "Use this to specify a range around your maintenace."
        }
    }
}

extension WorkoutDurationUnit: PickableItem {
    public var pickerTitle: String {
        switch self {
        case .hour:
            return "hour"
        case .min:
            return "minute"
        }
    }

    public var pickerSystemImage: String? {
        nil
    }

    public var pickerDetail: String? {
        switch self {
        case .hour:
            return "Hours of exercise."
        case .min:
            return "Minutes of exercise."
        }
    }
}

extension NutrientGoalBodyMassType: PickableItem {

    public var pickerTitle: String {
        switch self {
        case .leanMass:
            return "lean body mass"
        case .weight:
            return "body weight"
        }
    }

    public var pickerDetail: String? {
        switch self {
        case .leanMass:
            return "Lean body mass is the weight of your body minus your body fat (adipose tissue)."
        case .weight:
            return "The weight of your body."
        }
    }
}

extension BodyMassUnit: PickableItem {
    public var pickerTitle: String {
        switch self {
        case .kg:
            return "kg"
        case .lb:
            return "lb"
        case .st:
            return "st"
        }
    }

    public var pickerDetail: String? {
        switch self {
        case .kg:
            return "Kilograms"
        case .lb:
            return "Pounds"
        case .st:
            return "Stones"
        }
    }
}

//extension DietNutrientGoal: PickableItem {
//    public var pickerTitle: String {
//        switch self {
//        case .fixed:
//            return ""
//        case .percentageOfEnergy:
//            return ""
//        case .quantityPerEnergy:
//            return ""
//        case .quantityPerBodyMass:
//            return ""
//        }
//    }
//
//    public var pickerSystemImage: String? {
//        switch self {
//        case .fixed:
//            return ""
//        case .percentageOfEnergy:
//            return ""
//        case .quantityPerEnergy:
//            return ""
//        case .quantityPerBodyMass:
//            return ""
//        }
//    }
//
//    public var pickerDetail: String? {
//        switch self {
//        case .fixed:
//            return "Use this when you want to specify exact values."
//        case .percentageOfEnergy:
//            return ""
//        case .quantityPerEnergy:
//            return ""
//        case .quantityPerBodyMass:
//            return ""
//        }
//    }
//}
//
//extension MealNutrientGoal: PickableItem {
//    public var pickerTitle: String {
//        switch self {
//        case .fixed:
//            return ""
//        case .quantityPerBodyMass:
//            return ""
//        case .quantityPerWorkoutDuration:
//            return ""
//        }
//    }
//
//    public var pickerSystemImage: String? {
//        switch self {
//        case .fixed:
//            return ""
//        case .quantityPerBodyMass:
//            return ""
//        case .quantityPerWorkoutDuration:
//            return ""
//        }
//    }
//
//    public var pickerDetail: String? {
//        switch self {
//        case .fixed:
//            return ""
//        case .quantityPerBodyMass:
//            return ""
//        case .quantityPerWorkoutDuration:
//            return ""
//        }
//    }
//}

extension NutrientGoalType {
    func pickerDescription(nutrientUnit: NutrientUnit) -> String {
        switch self {
        case .fixed:
            return nutrientUnit.shortDescription
        case .quantityPerBodyMass(_, _):
            return nutrientUnit.shortDescription
        case .percentageOfEnergy:
            return "% of energy"
        case .quantityPerEnergy:
            return nutrientUnit.shortDescription
        case .quantityPerWorkoutDuration(_):
            return nutrientUnit.shortDescription
        }
    }
}

extension GoalType {
    var pickerDiscription: String {
        switch self {
        case .energy(let energyGoalType):
            return energyGoalType.description
        case .macro(let nutrientGoalType, _):
            return nutrientGoalType.pickerDescription(nutrientUnit: .g)
        case .micro(let nutrientGoalType, _, let nutrientUnit):
            return nutrientGoalType.pickerDescription(nutrientUnit: nutrientUnit)
        }
    }
}

extension GoalType {
    
    var flattenedType: FlattenedGoalType {
        switch self {
        case .energy(let energyGoalType):
            return energyGoalType.flattenedType
        case .macro(let nutrientGoalType, _):
            return nutrientGoalType.flattenedType()
        case .micro(let nutrientGoalType, _, let nutrientUnit):
            return nutrientGoalType.flattenedType(with: nutrientUnit)
        }
    }
}

extension EnergyGoalType {
    var flattenedType: FlattenedGoalType {
        switch self {
        case .fixed:
            return .energyFixed
        case .fromMaintenance:
            return .energyFromMaintenance
        case .percentFromMaintenance:
            return .energyPercentFromMaintenance
        }
    }
}

extension NutrientGoalType {
    func flattenedType(with nutrientUnit: NutrientUnit = .g) -> FlattenedGoalType {
        switch self {
        case .fixed:
            return .nutrientFixed(nutrientUnit)
        case .quantityPerBodyMass:
            return .nutrientPerBodyMass(nutrientUnit)
        case .percentageOfEnergy:
            return .nutrientPercentageOfEnergy(nutrientUnit)
        case .quantityPerEnergy:
            return .nutrientPerEnergy(nutrientUnit)
        case .quantityPerWorkoutDuration:
            return .nutrientPerWorkoutDuration(nutrientUnit)
        }
    }
}

enum FlattenedGoalType  {
    
    case energyFixed
    case energyFromMaintenance
    case energyPercentFromMaintenance
    case nutrientFixed(NutrientUnit)
    case nutrientPerBodyMass(NutrientUnit)
    case nutrientPerWorkoutDuration(NutrientUnit)
    case nutrientPerEnergy(NutrientUnit)
    case nutrientPercentageOfEnergy(NutrientUnit)
    
    var title: String {
        switch self {
        case .energyFixed:
            return UserManager.energyUnit.shortDescription
        case .energyFromMaintenance:
            return "\(UserManager.energyUnit.shortDescription) from maintenance"
        case .energyPercentFromMaintenance:
            return "% from maintenance"
        case .nutrientFixed(let unit):
            return "\(unit.shortDescription)"
        case .nutrientPerBodyMass(let unit):
            return "\(unit.shortDescription) / body mass"
        case .nutrientPerWorkoutDuration(let unit):
            return "\(unit) / workout duration"
        case .nutrientPerEnergy(let unit):
            return "\(unit) / 1000 \(UserManager.energyUnit.shortDescription) of energy goal"
        case .nutrientPercentageOfEnergy:
            return "% of energy goal"
        }
    }
    
    var detail: String? {
        return nil
        
//        var energyName: String {
//            UserManager.energyUnit == .kcal ? "caloric" : "energy"
//        }
//
//        switch self {
//        case .energyFixed:
//            return "Use this to specify the goal in exact \(energyName) values."
//        case .energyFromMaintenance:
//            return "Use this to specify the goal in \(energyName) values relative to your maintenance."
//        case .energyPercentFromMaintenance:
//            return "Use this to specify the goal in percentage values relative to your maintenance."
//        case .nutrientFixed(let unit):
//            return "Use this to specify the goal in exact \(unit.shortDescription) values."
//        case .nutrientPerBodyMass(let unit):
//            return "Use this to specify the goal in \(unit.shortDescription) per \(UserManager.bodyMassUnit.shortDescription) of weight or lean body mass."
//        case .nutrientPerWorkoutDuration(let unit):
//            return "Use this to specify the goal in \(unit.shortDescription) per minute or hour of your workout durations."
//        case .nutrientPerEnergy(let unit):
//            return "Use this to specify the goal in \(unit.shortDescription) per 1000 \(UserManager.energyUnit.shortDescription) of your energy goal."
//        case .nutrientPercentageOfEnergy:
//            return "Use this to specify the goal in percentage values of your energy goal."
//        }
    }
    
    var secondaryDetail: String? {
        switch self {
        case .energyFixed:
            return "e.g. 2000 kcal"
        case .energyFromMaintenance:
            return "e.g. 500 kcal below maintenance"
        case .energyPercentFromMaintenance:
            return "e.g. 10% within maintenance"
        case .nutrientFixed(let unit):
            return "e.g. 20g"
        case .nutrientPerBodyMass(let unit):
            return "e.g. 1g/lb of lean body mass"
        case .nutrientPerWorkoutDuration(let unit):
            return "e.g. 600mg/hour of exercise"
        case .nutrientPerEnergy(let unit):
            return "e.g. 10g/1000 \(UserManager.energyUnit.shortDescription) of energy"
        case .nutrientPercentageOfEnergy:
            return "e.g. 30% of energy goal"
        }
    }
    
    var systemImage: String? {
        switch self {
        case .nutrientFixed:
            return nil
        case .nutrientPerBodyMass:
            return nil
        case .nutrientPerWorkoutDuration:
            return nil
        case .nutrientPerEnergy:
            return nil
        case .nutrientPercentageOfEnergy:
            return nil
        default:
            return nil
        }
    }
    
    var pickerItem: PickerItem {
        return .init(
            id: self.rawValue,
            title: title,
            detail: detail,
            secondaryDetail: secondaryDetail,
            systemImage: systemImage
        )
    }
    
    static var dietEnergyTypes: [FlattenedGoalType] {
        [.energyFixed, .energyFromMaintenance, .energyPercentFromMaintenance]
    }
    
    static func dietNutrientTypes(with nutrientUnit: NutrientUnit) -> [FlattenedGoalType] {
        [
            .nutrientFixed(nutrientUnit),
            .nutrientPerBodyMass(nutrientUnit),
            .nutrientPerEnergy(nutrientUnit),
            .nutrientPercentageOfEnergy(nutrientUnit)
        ]
    }

    static var mealEnergyTypes: [FlattenedGoalType] {
        [.energyFixed]
    }
    
//    static var mealNutrientTypes: [FlattenedGoalType] {
//        [.nutrientFixed, .nutrientPerBodyMass, .nutrientPerWorkoutDuration]
//    }
}

extension FlattenedGoalType: RawRepresentable {

    public typealias RawValue = String

    /// Failable Initalizer
    public init?(rawValue: RawValue) {
        switch rawValue {
        case "energyFixed": self = .energyFixed
        case "energyFromMaintenance": self = .energyFromMaintenance
        case "energyPercentFromMaintenance": self = .energyPercentFromMaintenance
        case "nutrientFixed": self = .nutrientFixed(.g)
        case "nutrientPerBodyMass": self = .nutrientPerBodyMass(.g)
        case "nutrientPerWorkoutDuration": self = .nutrientPerWorkoutDuration(.g)
        case "nutrientPerEnergy": self = .nutrientPerEnergy(.g)
        case "nutrientPercentageOfEnergy": self = .nutrientPercentageOfEnergy(.g)
        default:
            return nil
        }
    }

    /// Backing raw value
    public var rawValue: RawValue {
        switch self {
        case .energyFixed: return "energyFixed"
        case .energyFromMaintenance: return "energyFromMaintenance"
        case .energyPercentFromMaintenance: return "energyPercentFromMaintenance"
        case .nutrientFixed: return "nutrientFixed"
        case .nutrientPerBodyMass: return "nutrientPerBodyMass"
        case .nutrientPerWorkoutDuration: return "nutrientPerWorkoutDuration"
        case .nutrientPerEnergy: return "nutrientPerEnergy"
        case .nutrientPercentageOfEnergy: return "nutrientPercentageOfEnergy"
        }
    }
}

extension GoalType {
    var pickerItem: PickerItem {
        PickerItem(
            id: flattenedType.rawValue,
            title: pickerDiscription,
            detail: "detail",
            systemImage: "questionmark.app.dashed"
        )
    }
    
    static var dietEnergyPickerItems: [PickerItem] {
        FlattenedGoalType.dietEnergyTypes.map { $0.pickerItem }
    }
    
    static func dietNutrientPickerItems(with nutrientUnit: NutrientUnit) -> [PickerItem] {
        FlattenedGoalType.dietNutrientTypes(with: nutrientUnit).map { $0.pickerItem }
    }
}

extension GoalType {
    var energyUnit: EnergyUnit? {
        switch self {
        case .energy(let energyGoalType):
            switch energyGoalType {
            case .fixed(let energyUnit):
                return energyUnit
            case .fromMaintenance(let energyUnit, _):
                return energyUnit
            case .percentFromMaintenance:
                return nil
            }
        default:
            return nil
        }
    }
    
    var energyDelta: EnergyGoalDelta? {
        energyGoalType?.delta
    }
    
    var bodyMassType: NutrientGoalBodyMassType? {
        nutrientGoalType?.bodyMassType
    }
    
    var bodyMassUnit: BodyMassUnit? {
        nutrientGoalType?.bodyMassUnit
    }
    
    var workoutDurationUnit: WorkoutDurationUnit? {
        nutrientGoalType?.workoutDurationUnit
    }
    
    var perEnergyValue: Double? {
        nutrientGoalType?.perEnergyValue
    }
    
    func applyingPickedItem(_ pickerItem: PickerItem) -> GoalType {
        guard let flattenedType = FlattenedGoalType(rawValue: pickerItem.id) else {
            return self
        }
        
        let energyUnit = self.energyUnit ?? UserManager.energyUnit
        let energyDelta = self.energyDelta ?? .deficit
        
        let bodyMassType = self.bodyMassType ?? .weight
        let bodyMassUnit = self.bodyMassUnit ?? UserManager.bodyMassUnit
        let workoutDurationUnit = self.workoutDurationUnit ?? .hour
        let perEnergyValue = self.perEnergyValue ?? 1000
        
        switch flattenedType {
        case .energyFixed:
            return .energy(.fixed(energyUnit))
        case .energyFromMaintenance:
            return .energy(.fromMaintenance(energyUnit, energyDelta))
        case .energyPercentFromMaintenance:
            return .energy(.percentFromMaintenance(energyDelta))
            
        case .nutrientFixed:
            switch self {
            case .macro(_, let macro):
                return .macro(.fixed, macro)
            case .micro(_, let nutrientType, let nutrientUnit):
                return .micro(.fixed, nutrientType, nutrientUnit)
            default:
                return self
            }
        case .nutrientPerBodyMass:
            switch self {
            case .macro(_, let macro):
                return .macro(.quantityPerBodyMass(bodyMassType, bodyMassUnit), macro)
            case .micro(_, let nutrientType, let nutrientUnit):
                return .micro(.quantityPerBodyMass(bodyMassType, bodyMassUnit), nutrientType, nutrientUnit)
            default:
                return self
            }
        case .nutrientPerWorkoutDuration:
            switch self {
            case .macro(_, let macro):
                return .macro(.quantityPerWorkoutDuration(workoutDurationUnit), macro)
            case .micro(_, let nutrientType, let nutrientUnit):
                return .micro(.quantityPerWorkoutDuration(workoutDurationUnit), nutrientType, nutrientUnit)
            default:
                return self
            }
        case .nutrientPerEnergy:
            switch self {
            case .macro(_, let macro):
                return .macro(.quantityPerEnergy(perEnergyValue, energyUnit), macro)
            case .micro(_, let nutrientType, let nutrientUnit):
                return .micro(.quantityPerEnergy(perEnergyValue, energyUnit), nutrientType, nutrientUnit)
            default:
                return self
            }
        case .nutrientPercentageOfEnergy:
            switch self {
            case .macro(_, let macro):
                return .macro(.percentageOfEnergy, macro)
            case .micro(_, let nutrientType, let nutrientUnit):
                return .micro(.percentageOfEnergy, nutrientType, nutrientUnit)
            default:
                return self
            }
        }
    }
}
