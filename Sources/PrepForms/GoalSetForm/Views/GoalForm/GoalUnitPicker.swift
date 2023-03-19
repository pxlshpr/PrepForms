import SwiftUI
import SwiftUISugar
import SwiftHaptics
import PrepDataTypes
import PrepCoreDataStack

struct GoalUnitPicker: View {
    
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject var model: GoalModel

    /// Energy
    @State var pickedMealEnergyGoalType: MealEnergyTypeOption
    @State var pickedDietEnergyGoalType: DietEnergyTypeOption
    @State var pickedDelta: EnergyDeltaOption

    /// Nutrients
    @State var pickedMealNutrientGoal: MealNutrientGoal
    @State var pickedDietNutrientGoal: DietNutrientGoal
    @State var pickedBodyMassType: NutrientGoalBodyMassType
    @State var pickedBodyMassUnit: BodyMassUnit
    @State var pickedEnergyUnit: EnergyUnit = .kcal
    @State var pickedWorkoutDurationUnit: WorkoutDurationUnit
    @State var energyValue: Double = 1000

    @State var presentedSheet: Sheet? = nil
    
    init(model: GoalModel) {
        self.model = model
        
        let mealEnergyGoalType = MealEnergyTypeOption(goalModel: model) ?? .fixed
        let dietEnergyGoalType = DietEnergyTypeOption(goalModel: model) ?? .fixed
        let delta = EnergyDeltaOption(goalModel: model) ?? .below
        _pickedMealEnergyGoalType = State(initialValue: mealEnergyGoalType)
        _pickedDietEnergyGoalType = State(initialValue: dietEnergyGoalType)
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
//        navigationStack
        quickForm
//        .onChange(of: pickedMealEnergyGoalType, perform: mealEnergyGoalChanged)
//        .onChange(of: pickedDietEnergyGoalType, perform: dietEnergyGoalChanged)
//        .onChange(of: pickedDelta, perform: deltaChanged)
        .sheet(item: $presentedSheet) { sheet(for: $0) }
        .presentationDetents([.height(250)])
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
            if model.type.isEnergy {
                model.energyGoalType = energyGoalType
            } else {
                model.nutrientGoalType = nutrientGoalType
            }
        }
        dismiss()
    }

    var hasParameters: Bool {
        if let energyGoalType {
            switch energyGoalType {
            case .fromMaintenance, .percentFromMaintenance:
                return UserManager.biometrics.hasTDEE
            default:
                return true
            }
        } else if let nutrientGoalType {
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
        return false
    }
    
    var quickForm: some View {
        
        let saveAction = Binding<FormConfirmableAction?>(
            get: {
                FormConfirmableAction(
                    position: .bottomFilled,
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
        }
    }

    func appeared() {
//        pickedMealEnergyGoalType = MealEnergyTypeOption(goalModel: model) ?? .fixed
//        pickedDietEnergyGoalType = DietEnergyTypeOption(goalModel: model) ?? .fixed
//        pickedDelta = EnergyDeltaOption(goalModel: model) ?? .below
    }
    
    func dietEnergyGoalChanged(_ newValue: DietEnergyTypeOption) {
        model.energyGoalType = self.energyGoalType
    }
    
    func mealEnergyGoalChanged(_ newValue: MealEnergyTypeOption) {
        model.energyGoalType = self.energyGoalType
    }
    
    func deltaChanged(to newValue: EnergyDeltaOption) {
        model.energyGoalType = self.energyGoalType
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
        model.goalSetType != .meal  && pickedDietEnergyGoalType != .fixed
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
    
    var energyGoalType: EnergyGoalType? {
        if model.goalSetType == .meal {
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
    
    //MARK: - Energy Pickers
    
    @ViewBuilder
    var energyTypePicker: some View {
        if model.goalSetType == .meal {
            mealTypePicker
        } else {
            dietTypePicker
        }
    }
    
    var mealTypePicker: some View {
        /// We don't have any options so we're leaving this here as a placeholder for now
        PickerLabel(
            pickedMealEnergyGoalType.description(energyUnit: UserManager.energyUnit),
            systemImage: nil
        )
        .animation(.none, value: pickedMealEnergyGoalType)
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
    
    //MARK: - Nutrient Type Pickers
    
    @ViewBuilder
    var nutrientTypePicker: some View {
        if model.goalSetType == .meal {
            nutrientMealTypePicker
        } else {
            nutrientDietTypePicker
        }
    }
    
    var nutrientMealTypePicker: some View {
        let binding = Binding<MealNutrientGoal>(
            get: { pickedMealNutrientGoal },
            set: { newType in
                withAnimation {
                    self.pickedMealNutrientGoal = newType
                }
//                self.model.nutrientGoalType = nutrientGoalType
            }
        )
        return Menu {
            Picker(selection: binding, label: EmptyView()) {
                ForEach(MealNutrientGoal.allCases, id: \.self) {
                    Text($0.menuDescription(nutrientUnit: nutrientUnit)).tag($0)
                }
            }
        } label: {
            defaultPickerLabel(
                pickedDietNutrientGoal.pickerDescription(nutrientUnit: nutrientUnit)
            )
        }
        .animation(.none, value: pickedMealNutrientGoal)
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture().onEnded {
            Haptics.feedback(style: .soft)
        })
    }

    var nutrientDietTypePicker: some View {
        let binding = Binding<DietNutrientGoal>(
            get: { pickedDietNutrientGoal },
            set: { newType in
                withAnimation {
                    self.pickedDietNutrientGoal = newType
                }
//                self.model.nutrientGoalType = nutrientGoalType
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
        .animation(.none, value: pickedDietNutrientGoal)
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture().onEnded {
            Haptics.feedback(style: .soft)
        })
    }
    
    var isQuantityPerBodyMass: Bool {
        pickedDietNutrientGoal == .quantityPerBodyMass
        || pickedMealNutrientGoal == .quantityPerBodyMass
    }
    
    var bodyMassTypePicker: some View {
        let binding = Binding<NutrientGoalBodyMassType>(
            get: { pickedBodyMassType },
            set: { newBodyMassType in
                withAnimation {
                    self.pickedBodyMassType = newBodyMassType
                }
//                self.model.nutrientGoalType = nutrientGoalType
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
                    defaultPickerLabel(
                        pickedBodyMassType.pickerDescription,
                        prefix: pickedBodyMassType.pickerPrefix
                    )
                }
                .animation(.none, value: pickedBodyMassType)
                .contentShape(Rectangle())
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
//                self.model.nutrientGoalType = nutrientGoalType
            }
        )
        return Group {
            if model.goalSetType == .meal, pickedMealNutrientGoal == .quantityPerWorkoutDuration {
                Menu {
                    Picker(selection: binding, label: EmptyView()) {
                        ForEach(WorkoutDurationUnit.allCases, id: \.self) {
                            Text($0.pickerDescription).tag($0)
                        }
                    }
                } label: {
                    defaultPickerLabel(
                        pickedWorkoutDurationUnit.menuDescription,
                        prefix: "per"
                    )
                }
                .animation(.none, value: pickedWorkoutDurationUnit)
                .contentShape(Rectangle())
                .simultaneousGesture(TapGesture().onEnded {
                    Haptics.feedback(style: .soft)
                })
                Text("of working out")
                    .foregroundColor(Color(.secondaryLabel))
            }
        }
    }
    
    var bodyMassUnitPicker: some View {
        let binding = Binding<BodyMassUnit>(
            get: { pickedBodyMassUnit },
            set: { newWeightUnit in
                withAnimation {
                    self.pickedBodyMassUnit = newWeightUnit
                }
//                self.model.nutrientGoalType = nutrientGoalType
            }
        )
        return Group {
            if isQuantityPerBodyMass {
                Menu {
                    Picker(selection: binding, label: EmptyView()) {
                        ForEach(BodyMassUnit.allCases, id: \.self) {
                            Text($0.menuDescription).tag($0)
                        }
                    }
                } label: {
                    defaultPickerLabel(
                        pickedBodyMassUnit.pickerDescription,
                        prefix: pickedBodyMassUnit.pickerPrefix
                    )
                }
                .animation(.none, value: pickedBodyMassUnit)
                .contentShape(Rectangle())
                .simultaneousGesture(TapGesture().onEnded {
                    Haptics.feedback(style: .soft)
                })
            }
        }
    }
    
    func defaultPickerLabel(
        _ string: String,
        prefix: String? = nil,
        systemImage: String? = "chevron.up.chevron.down"
    ) -> some View {
        PickerLabel(
            string,
            prefix: prefix,
            systemImage: systemImage
//            backgroundColor: .accentColor,
//            foregroundColor: .accentColor
        )
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
        
        var id: String { rawValue }
    }
}
