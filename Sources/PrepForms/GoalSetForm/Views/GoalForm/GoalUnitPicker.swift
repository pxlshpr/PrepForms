import SwiftUI
import SwiftUISugar
import SwiftHaptics
import PrepDataTypes
import PrepCoreDataStack

struct GoalUnitPicker: View {
    
    @Environment(\.dismiss) var dismiss
    
    @StateObject var biometricsModel = BiometricsModel()
    @ObservedObject var model: GoalModel
    @State var presentedSheet: Sheet? = nil
    
    @State var type: GoalType
    
    init(model: GoalModel) {
        self.model = model
        _type = State(initialValue: model.type)
    }
    
    var body: some View {
        quickForm
            .sheet(item: $presentedSheet) { sheet(for: $0) }
            .presentationDetents([.height(GoalFormHeight)])
            .onChange(of: type, perform: typeChanged)
    }
    
    func typeChanged(_ newValue: GoalType) {
        Haptics.feedback(style: .soft)
    }
    
    var trailingContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                Haptics.feedback(style: .soft)
                dismiss()
            } label: {
                CloseButtonLabel()
            }
        }
    }
    
    func didTapSave() {
        withAnimation {
            model.type = type
        }
        dismiss()
    }
    
    var hasRequiredParameters: Bool {
        
        func nutrientGoalTypeHasRequiredParameters(_ nutrientGoalType: NutrientGoalType) -> Bool {
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
                return true
            }
        case .macro(let nutrientGoalType, _):
            return nutrientGoalTypeHasRequiredParameters(nutrientGoalType)
        case .micro(let nutrientGoalType, _, _):
            return nutrientGoalTypeHasRequiredParameters(nutrientGoalType)
        }
    }
    
    var isDirty: Bool {
        model.type != type
    }
    
    var shouldDisableSaveButton: Bool {
        !hasRequiredParameters || !isDirty
    }
    
    var quickForm: some View {
        
        let saveAction = Binding<FormConfirmableAction?>(
            get: {
                FormConfirmableAction(
                    position: .bottomFilled,
                    confirmationButtonTitle: "Done",
                    isDisabled: shouldDisableSaveButton,
                    handler: didTapSave
                )
            },
            set: { _ in }
        )
        return QuickForm(
            title: "Change Unit",
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
            energyGoalButton
            perEnergyButton
            bodyMassButton
        }
    }
    
    @ViewBuilder
    func sheet(for sheet: Sheet) -> some View {
        switch sheet {
        case .tdee:
            TDEEForm()
        case .weight:
            WeightForm()
        case .leanBodyMass:
            LeanBodyMassForm(biometricsModel)
        case .energyGoal:
            energyGoalSheet
            
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
    
    @ViewBuilder
    var energyGoalSheet: some View {
        if let energyGoalModel = model.goalSetModel.energyGoal {
            GoalForm(goalModel: energyGoalModel)
        }
    }
    
    func appeared() {
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
    
    var isQuantityPerBodyMass: Bool {
        type.nutrientGoalType?.isQuantityPerBodyMass == true
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
            PickerLabel(type.pickerDiscription, systemImage: nil)
        }
        
        
        return Group {
            if model.goalSetType == .meal {
                mealPicker
            } else {
                dayPicker
            }
        }
    }
    
    var nutrientTypePicker: some View {
        
        let description = type.pickerDiscription
        
        @ViewBuilder
        var label: some View {
            if model.goalSetType == .meal {
                PickerLabel(description)
            } else {
                if type.usesEnergyGoal {
                    PickerLabel(
                        description,
                        systemImage: "chevron.up.chevron.down",
                        imageScale: .small
                    )
                } else {
                    PickerLabel(description)
                }
            }
        }
        
        return Button {
            present(model.isForMeal ? .mealNutrientPicker : .dayNutrientPicker)
        } label: {
            label
        }
    }

    var energyDelta: EnergyGoalDelta {
        type.energyDelta ?? .deficit
    }

    var bodyMassType: BodyMassType {
        type.bodyMassType ?? .weight
    }

    var bodyMassUnit: BodyMassUnit {
        type.bodyMassUnit ?? UserManager.bodyMassUnit
    }

    var workoutDurationUnit: WorkoutDurationUnit {
        type.workoutDurationUnit ?? .hour
    }
    
    var perEnergyValue: Double {
        type.perEnergyValue ?? 1000
    }

    @ViewBuilder
    var deltaPicker: some View {
        if shouldShowEnergyDeltaElements {
            Button {
                present(.deltaPicker)
            } label: {
                PickerLabel(
                    energyDelta.shortDescription,
                    prefixImage: energyDelta.systemImage
                )
            }
        }
    }
    
    @ViewBuilder
    var bodyMassUnitPicker: some View {
        if isQuantityPerBodyMass {
            Button {
                present(.bodyMassUnitPicker)
            } label: {
                PickerLabel(
                    bodyMassUnit.pickerDescription,
                    prefix: bodyMassUnit.pickerPrefix
                )
            }
        }
    }
    
    @ViewBuilder
    var bodyMassTypePicker: some View {
        if isQuantityPerBodyMass {
            Button {
                present(.bodyMassTypePicker)
            } label: {
                PickerLabel(
                    bodyMassType.pickerDescription,
                    prefix: bodyMassType.pickerPrefix
                )
            }
        }
    }
    
    @ViewBuilder
    var workoutDurationUnitPicker: some View {
        if type.nutrientGoalType?.isQuantityPerWorkoutDuration == true {
            Group {
                Button {
                    present(.workoutDurationUnitPicker)
                } label: {
                    PickerLabel(
                        workoutDurationUnit.menuDescriptionLong,
                        prefix: "per"
                    )
                }
            }
        }
    }
}

//MARK: - Enum PickerItem Extensions

extension BodyMassType {
    var pickerDetail: String {
        switch self {
        case .leanMass:
            return "Lean body mass is your weight minus your body fat"
        case .weight:
            return "Your body weight"
        }
    }

    static var pickerItems: [PickerItem] {
        allCases.map { $0.pickerItem }
    }
    
    var pickerTitle: String {
        switch self {
        case .weight:
            return "weight"
        case .leanMass:
            return "lean body mass"
        }
    }
    
    var pickerItem: PickerItem {
        PickerItem(
            id: "\(rawValue)",
            title: pickerTitle,
            secondaryDetail: pickerDetail
        )
    }
    
    init?(pickerItem: PickerItem) {
        guard let int16 = Int16(pickerItem.id) else { return nil }
        self.init(rawValue: int16)
    }
}

extension BodyMassUnit {
    var pickerDetail: String {
        switch self {
        case .kg:
            return "Kilograms"
        case .lb:
            return "Pounds"
        case .st:
            return "Stones"
        }
    }

    static var pickerItems: [PickerItem] {
        allCases.map { $0.pickerItem }
    }
    
    var pickerItem: PickerItem {
        PickerItem(
            id: "\(rawValue)",
            title: shortDescription,
            secondaryDetail: pickerDetail
        )
    }
    
    init?(pickerItem: PickerItem) {
        guard let int16 = Int16(pickerItem.id) else { return nil }
        self.init(rawValue: int16)
    }
}

extension WorkoutDurationUnit {
    var pickerDetail: String {
        switch self {
        case .hour:
            return "e.g. 600mg / hour of exercise"
        case .min:
            return "e.g. 0.5g / min of exercise"
        }
    }

    static var pickerItems: [PickerItem] {
        allCases.map { $0.pickerItem }
    }
    
    var pickerItem: PickerItem {
        PickerItem(
            id: "\(rawValue)",
            title: pickerDescription,
            secondaryDetail: pickerDetail
        )
    }
    
    init?(pickerItem: PickerItem) {
        guard let int16 = Int16(pickerItem.id) else { return nil }
        self.init(rawValue: int16)
    }
}

extension EnergyGoalDelta {
    static var pickerItems: [PickerItem] {
        allCases.map { $0.pickerItem }
    }
    
    var pickerItem: PickerItem {
        PickerItem(
            id: "\(rawValue)",
            title: shortDescription,
            secondaryDetail: pickerDetail,
            systemImage: systemImage
        )
    }
    
    var pickerDetail: String {
        switch self {
        case .deficit:
            return "e.g. 500 \(UserManager.energyUnit.shortDescription) deficit from your maintenance energy"
        case .surplus:
            return "e.g. 500 \(UserManager.energyUnit.shortDescription) surplus from your maintenance energy"
        case .deviation:
            return "e.g. within 200 \(UserManager.energyUnit.shortDescription) of your maintenance energy"
        }
    }
    
    init?(pickerItem: PickerItem) {
        guard let int16 = Int16(pickerItem.id) else {
            return nil
        }
        self.init(rawValue: int16)
    }
}

//MARK: - Picker Sheets
extension GoalUnitPicker {
    
    var dayEnergyPickerSheet: some View {
        nutrientPickerSheet(items: GoalType.dietEnergyPickerItems)
    }
    
    var dayNutrientPickerSheet: some View {
        nutrientPickerSheet(
            items: GoalType.dietNutrientPickerItems(
                with: nutrientUnit,
                nutrientType: type.nutrientType,
                macro: type.macro,
                includingEnergyDependentGoals: model.goalSetModel.energyGoal != nil
            )
        )
    }

    var mealNutrientPickerSheet: some View {
        nutrientPickerSheet(
            items: GoalType.mealNutrientPickerItems(
                with: nutrientUnit,
                nutrientType: type.nutrientType,
                macro: type.macro
            )
        )
    }

    func nutrientPickerSheet(items: [PickerItem]) -> some View {
        PickerSheet(
            title: "Choose a Goal Type",
            items: items,
            pickedItem: type.pickerItem,
            didPick: { type = type.applyingPickedTypeItem($0) }
        )
    }
    
    var deltaPickerSheet: some View {
        PickerSheet(
            title: "Choose Energy Difference",
            items: EnergyGoalDelta.pickerItems,
            pickedItem: energyDelta.pickerItem,
            didPick: { type = type.applyingPickedDeltaItem($0) }
        )
    }
    
    var bodyMassTypePickerSheet: some View {
        PickerSheet(
            title: "Choose Body Mass Type",
            items: BodyMassType.pickerItems,
            pickedItem: bodyMassType.pickerItem,
            didPick: { type = type.applyingPickedBodyMassTypeItem($0) }
        )
    }

    var bodyMassUnitPickerSheet: some View {
        PickerSheet(
            title: "Choose Body Mass Unit",
            items: BodyMassUnit.pickerItems,
            pickedItem: bodyMassUnit.pickerItem,
            didPick: { type = type.applyingPickedBodyMassUnitItem($0) }
        )
    }

    var workoutDurationUnitPickerSheet: some View {
        PickerSheet(
            title: "Choose Duration Unit",
            items: WorkoutDurationUnit.pickerItems,
            pickedItem: workoutDurationUnit.pickerItem,
            didPick: { type = type.applyingPickedWorkoutDurationUnitItem($0) }
        )
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
//                            imageColor: .green,
//                            backgroundColor: .green,
//                            foregroundColor: .green,
                            imageColor: HealthTopColor,
                            backgroundColor: HealthTopColor,
                            foregroundColor: HealthTopColor,

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
    
    var energyGoalButton: some View {
        var description: String {
            "energy goal"
        }
        
        return Group {
            if type.nutrientGoalType?.isPercentageOfEnergy == true {
                Button {
                    present(.energyGoal)
                } label: {
                    if model.goalSetModel.energyGoal?.isSynced == true {
                        PickerLabel(
                            description,
                            prefix: "of",
                            systemImage: "chevron.right",
                            imageColor: Color(hex: "F3DED7"),
                            backgroundGradientTop: HealthTopColor,
                            backgroundGradientBottom: HealthBottomColor,
                            foregroundColor: .white,
                            imageScale: .small
                        )
                    } else {
                        PickerLabel(
                            description,
                            prefix: "of",
                            systemImage: "chevron.right",
                            imageScale: .small
                        )
                    }
                }
            }
        }
    }
    
    var perEnergyButton: some View {
        var description: String {
             "\(perEnergyValue.cleanAmount) \(UserManager.energyUnit.shortDescription) of energy goal"
        }
        
        return Group {
            if type.nutrientGoalType?.isQuantityPerEnergy == true {
                Button {
                    present(.energyGoal)
                } label: {
                    if model.goalSetModel.energyGoal?.isSynced == true {
                        PickerLabel(
                            description,
                            prefix: "per",
                            systemImage: "chevron.right",
                            imageColor: Color(hex: "F3DED7"),
                            backgroundGradientTop: HealthTopColor,
                            backgroundGradientBottom: HealthBottomColor,
                            foregroundColor: .white,
                            imageScale: .small
                        )
                    } else {
                        PickerLabel(
                            description,
                            prefix: "per",
                            systemImage: "chevron.right",
                            imageScale: .small
                        )
                    }
                }
//                .disabled(true)
            }
        }
    }
    
    var bodyMassButton: some View {
        
        @ViewBuilder
        var label: some View {
            if haveBodyMass {
                if model.bodyMassIsSyncedWithHealth {
                    PickerLabel(
                        bodyMassFormattedWithUnit,
                        prefix: "\(bodyMassType.description)",
                        prefixImage: "figure.arms.open",
                        systemImage: "chevron.forward",
//                        imageColor: .green,
//                        backgroundColor: .green,
//                        foregroundColor: .green,
//                        prefixColor: .green,
                        imageColor: HealthTopColor,
                        backgroundColor: HealthTopColor,
                        foregroundColor: HealthTopColor,
                        prefixColor: HealthTopColor,
                        imageScale: .small
                    )
                } else {
                    PickerLabel(
                        bodyMassFormattedWithUnit,
                        prefix: "\(bodyMassType.description)",
                        prefixImage: "figure.arms.open",
                        systemImage: "chevron.forward",
                        imageScale: .small
                    )
                }
            } else {
                PickerLabel(
                    "\(bodyMassType.description)",
                    prefix: "set",
                    prefixImage: "figure.arms.open",
                    systemImage: "chevron.forward",
                    imageColor: Color.white.opacity(0.75),
                    backgroundColor: .accentColor,
                    foregroundColor: .white,
                    prefixColor: Color.white.opacity(0.75),
                    imageScale: .small
                )
            }
        }
        
        var button: some View {
            Button {
                Haptics.feedback(style: .soft)
                switch type.bodyMassType {
                case .leanMass:
                    present(.leanBodyMass)
                default:
                    present(.weight)
                }
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
    
    var haveBodyMass: Bool {
        switch bodyMassType {
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
        switch bodyMassType {
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
        case energyGoal
        
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

extension NutrientGoalType {
    func pickerDescription(nutrientUnit: NutrientUnit) -> String {
        switch self {
        case .fixed:
            return nutrientUnit.shortDescription
        case .quantityPerBodyMass(_, _):
            return nutrientUnit.shortDescription
        case .percentageOfEnergy:
//            return "% of energy"
            return "%"
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
    func flattenedType(
        with nutrientUnit: NutrientUnit = .g,
        nutrientType: NutrientType? = nil,
        macro: Macro? = nil
    ) -> FlattenedGoalType {
        switch self {
        case .fixed:
            return .nutrientFixed(nutrientUnit, nutrientType, macro)
        case .quantityPerBodyMass:
            return .nutrientPerBodyMass(nutrientUnit, nutrientType, macro)
        case .percentageOfEnergy:
            return .nutrientPercentageOfEnergy(nutrientUnit, nutrientType, macro)
        case .quantityPerEnergy:
            return .nutrientPerEnergy(nutrientUnit, nutrientType, macro)
        case .quantityPerWorkoutDuration:
            return .nutrientPerWorkoutDuration(nutrientUnit, nutrientType, macro)
        }
    }
}

enum FlattenedGoalType  {
    
    case energyFixed
    case energyFromMaintenance
    case energyPercentFromMaintenance
    case nutrientFixed(NutrientUnit, NutrientType?, Macro?)
    case nutrientPerBodyMass(NutrientUnit, NutrientType?, Macro?)
    case nutrientPerWorkoutDuration(NutrientUnit, NutrientType?, Macro?)
    case nutrientPerEnergy(NutrientUnit, NutrientType?, Macro?)
    case nutrientPercentageOfEnergy(NutrientUnit, NutrientType?, Macro?)
    
    var title: String {
        switch self {
        case .energyFixed:
            return UserManager.energyUnit.shortDescription
        case .energyFromMaintenance:
            return "\(UserManager.energyUnit.shortDescription) from maintenance"
        case .energyPercentFromMaintenance:
            return "% from maintenance"
        case .nutrientFixed(let unit, _, _):
            return "\(unit.shortDescription)"
        case .nutrientPerBodyMass(let unit, _, _):
            return "\(unit.shortDescription) / body mass"
        case .nutrientPerWorkoutDuration(let unit, _, _):
            return "\(unit) / workout duration"
        case .nutrientPerEnergy(let unit, _, _):
            return "\(unit) / 1000 \(UserManager.energyUnit.shortDescription) of energy goal"
        case .nutrientPercentageOfEnergy:
            return "% of energy goal"
        }
    }
    
    var detail: String? {
        func nutrient(_ nutrientType: NutrientType?, _ macro: Macro?) -> String {
            let description = nutrientType?.description ?? macro?.description ?? ""
            return description.lowercased()
        }
        
        switch self {
//        case .energyFixed:
//            return "Use this to specify the goal in exact \(energyName) values."
//        case .energyFromMaintenance:
//            return "Use this to specify the goal in \(energyName) values relative to your maintenance."
//        case .energyPercentFromMaintenance:
//            return "Use this to specify the goal in percentage values relative to your maintenance."
//        case .nutrientFixed(let unit):
//            return "Use this to specify the goal in exact \(unit.shortDescription) values."
//        case .nutrientPerBodyMass(_, let n, let m):
//            return "Scales this \(nutrient(n, m)) goal with your body mass."
//        case .nutrientPerWorkoutDuration(_, let n, let m):
//            return "Scales this \(nutrient(n, m)) goal with your workout duration."
//        case .nutrientPerEnergy(_, let n, let m):
//            return "Scales this \(nutrient(n, m)) goal with your energy goal."
//        case .nutrientPercentageOfEnergy(_, let n, let m):
//            return "Scales this \(nutrient(n, m)) goal with your energy goal."
        default:
            return nil
        }
    }
    
    var secondaryDetail: String? {
        func nutrient(_ nutrientType: NutrientType?, _ macro: Macro?) -> String {
            let description = nutrientType?.description ?? macro?.description ?? ""
            return description.lowercased()
        }
        
        let energyUnit = UserManager.energyUnit.shortDescription
        
        switch self {
        case .energyFixed:
            return "e.g. 2000 \(energyUnit)"
        case .energyFromMaintenance:
            return "e.g. 500 \(energyUnit) below maintenance"
        case .energyPercentFromMaintenance:
            return "e.g. 10% within maintenance"
        case .nutrientFixed(let unit, let n, let m):
            return "e.g. 20\(unit.shortDescription) of \(nutrient(n, m))"
        case .nutrientPerBodyMass(let unit, let n, let m):
            return "e.g. 1\(unit.shortDescription) of \(nutrient(n, m)) / \(UserManager.bodyMassUnit.shortDescription) of weight or lean body mass"
        case .nutrientPerWorkoutDuration(let unit, let n, let m):
            return "e.g. 600\(unit) / hour working out of \(nutrient(n, m))"
        case .nutrientPerEnergy(let unit, let n, let m):
            return "e.g. 10\(unit.shortDescription) \(nutrient(n, m)) / 1000 \(energyUnit) of energy goal"
        case .nutrientPercentageOfEnergy(_, let n, let m):
            return "e.g. 30% of energy goal from \(nutrient(n, m))"
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
    
    static func dietNutrientTypes(
        with nutrientUnit: NutrientUnit,
        nutrientType: NutrientType? = nil,
        macro: Macro? = nil,
        includingEnergyDependentGoals: Bool
        
    ) -> [FlattenedGoalType] {
        var types: [FlattenedGoalType] = [
            .nutrientFixed(nutrientUnit, nutrientType, macro),
            .nutrientPerBodyMass(nutrientUnit, nutrientType, macro)
        ]
        
        if includingEnergyDependentGoals {
            types.append(contentsOf: [
                .nutrientPerEnergy(nutrientUnit, nutrientType, macro),
                .nutrientPercentageOfEnergy(nutrientUnit, nutrientType, macro)
            ])
        }
        return types
    }

    static var mealEnergyTypes: [FlattenedGoalType] {
        [.energyFixed]
    }
    
    static func mealNutrientTypes(with nutrientUnit: NutrientUnit, nutrientType: NutrientType? = nil, macro: Macro? = nil) -> [FlattenedGoalType] {
        [
            .nutrientFixed(nutrientUnit, nutrientType, macro),
            .nutrientPerBodyMass(nutrientUnit, nutrientType, macro),
            .nutrientPerWorkoutDuration(nutrientUnit, nutrientType, macro)
        ]
    }
}

extension FlattenedGoalType: RawRepresentable {

    public typealias RawValue = String

    /// Failable Initalizer
    public init?(rawValue: RawValue) {
        switch rawValue {
        case "energyFixed": self = .energyFixed
        case "energyFromMaintenance": self = .energyFromMaintenance
        case "energyPercentFromMaintenance": self = .energyPercentFromMaintenance
        case "nutrientFixed": self = .nutrientFixed(.g, nil, nil)
        case "nutrientPerBodyMass": self = .nutrientPerBodyMass(.g, nil, nil)
        case "nutrientPerWorkoutDuration": self = .nutrientPerWorkoutDuration(.g, nil, nil)
        case "nutrientPerEnergy": self = .nutrientPerEnergy(.g, nil, nil)
        case "nutrientPercentageOfEnergy": self = .nutrientPercentageOfEnergy(.g, nil, nil)
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
    
    static func dietNutrientPickerItems(
        with nutrientUnit: NutrientUnit,
        nutrientType: NutrientType? = nil,
        macro: Macro? = nil,
        includingEnergyDependentGoals: Bool
    ) -> [PickerItem] {
        
        FlattenedGoalType.dietNutrientTypes(
            with: nutrientUnit,
            nutrientType: nutrientType,
            macro: macro,
            includingEnergyDependentGoals: includingEnergyDependentGoals
        )
        .map { $0.pickerItem }
    }
    
    static func mealNutrientPickerItems(
        with nutrientUnit: NutrientUnit,
        nutrientType: NutrientType? = nil,
        macro: Macro? = nil
    ) -> [PickerItem] {
        
        FlattenedGoalType.mealNutrientTypes(
            with: nutrientUnit,
            nutrientType: nutrientType,
            macro: macro
        )
        .map { $0.pickerItem }
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
    
    var bodyMassType: BodyMassType? {
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

    func applyingPickedDeltaItem(_ pickerItem: PickerItem) -> GoalType {
        guard let pickedDelta = EnergyGoalDelta(pickerItem: pickerItem) else {
            return self
        }
        
        switch self {
        case .energy(let energyGoalType):
            switch energyGoalType {
            case .fromMaintenance(let energyUnit, _):
                return .energy(.fromMaintenance(energyUnit, pickedDelta))
            case .percentFromMaintenance(_):
                return .energy(.percentFromMaintenance(pickedDelta))
            default:
                return self
            }
        default:
            return self
        }
    }
    
    func applyingPickedBodyMassTypeItem(_ pickerItem: PickerItem) -> GoalType {
        guard let pickedBodyMassType = BodyMassType(pickerItem: pickerItem) else {
            return self
        }
        
        switch self {
        case .macro(let type, let macro):
            switch type {
            case .quantityPerBodyMass(_, let bodyMassUnit):
                return .macro(.quantityPerBodyMass(pickedBodyMassType, bodyMassUnit), macro)
            default:
                return self
            }
        case .micro(let type, let nutrientType, let nutrientUnit):
            switch type {
            case .quantityPerBodyMass(_, let bodyMassUnit):
                return .micro(.quantityPerBodyMass(pickedBodyMassType, bodyMassUnit), nutrientType, nutrientUnit)
            default:
                return self
            }
        default:
            return self
        }
    }

    func applyingPickedBodyMassUnitItem(_ pickerItem: PickerItem) -> GoalType {
        guard let pickedBodyMassUnit = BodyMassUnit(pickerItem: pickerItem) else {
            return self
        }
        switch self {
        case .macro(let type, let macro):
            switch type {
            case .quantityPerBodyMass(let bodyMassType, _):
                return .macro(.quantityPerBodyMass(bodyMassType, pickedBodyMassUnit), macro)
            default:
                return self
            }
        case .micro(let type, let nutrientType, let nutrientUnit):
            switch type {
            case .quantityPerBodyMass(let bodyMassType, _):
                return .micro(.quantityPerBodyMass(bodyMassType, pickedBodyMassUnit), nutrientType, nutrientUnit)
            default:
                return self
            }
        default:
            return self
        }
    }
    
    func applyingPickedWorkoutDurationUnitItem(_ pickerItem: PickerItem) -> GoalType {
        guard let pickedWorkoutDurationUnit = WorkoutDurationUnit(pickerItem: pickerItem) else {
            return self
        }
        switch self {
        case .macro(let type, let macro):
            switch type {
            case .quantityPerWorkoutDuration:
                return .macro(.quantityPerWorkoutDuration(pickedWorkoutDurationUnit), macro)
            default:
                return self
            }
        case .micro(let type, let nutrientType, let nutrientUnit):
            switch type {
            case .quantityPerWorkoutDuration:
                return .micro(.quantityPerWorkoutDuration(pickedWorkoutDurationUnit), nutrientType, nutrientUnit)
            default:
                return self
            }
        default:
            return self
        }
    }
    
    func applyingPickedTypeItem(_ pickerItem: PickerItem) -> GoalType {
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
