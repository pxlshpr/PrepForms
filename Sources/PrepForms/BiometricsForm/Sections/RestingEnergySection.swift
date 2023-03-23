import SwiftUI
import SwiftHaptics
import PrepDataTypes
import ActivityIndicatorView
import SwiftUISugar
import HealthKit
import PrepCoreDataStack

struct RestingEnergySection: View {
    
    @EnvironmentObject var model: BiometricsModel
    @State var showFormOnAppear = false
    @State var presentedSheet: Sheet? = nil
    
    var body: some View {
        VStack(spacing: 7) {
            header
            contentRow
            footer
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .sheet(item: $presentedSheet) { sheet(for: $0) }
    }
    
    @ViewBuilder
    func sheet(for sheet: Sheet) -> some View {
        switch sheet {
        case .sourcePicker:
            sourcePickerSheet
        case .leanBodyMassForm:
            leanBodyMassForm
        case .profileForm:
            profileForm
        case .intervalTypePicker:
            intervalTypePickerSheet
        case .intervalPeriodPicker:
            intervalPeriodPickerSheet
        case .intervalValuePicker:
            intervalValuePickerSheet
        case .equationPicker:
            equationPickerSheet
        }
    }
    
    var header: some View {
        BiometricSectionHeader(type: .restingEnergy)
            .environmentObject(model)
            .padding(.horizontal, 20)
    }
    
    var contentRow: some View {
        content
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 0)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(Color(.secondarySystemGroupedBackground))
        )
        .if(model.restingEnergyFooterString == nil) { view in
            view.padding(.bottom, 10)
        }
    }
    
    
    @ViewBuilder
    var content: some View {
        VStack {
            Group {
                if let source = model.restingEnergySource {
                    filledContent(source)
                } else {
                    emptyContent
                }
            }
        }
    }
    
    func filledContent(_ source: RestingEnergySource) -> some View {
        Group {
            sourceSection
            switch source {
            case .health:
                healthContent
            case .userEntered:
                EmptyView()
            case .equation:
                equationContent
            }
            bottomRow
        }
    }

    var sourcePickerSheet: some View {
        PickerSheet(
            title: "Choose a Source",
            items: RestingEnergySource.pickerItems,
            pickedItem: model.restingEnergySource?.pickerItem,
            didPick: {
                Haptics.feedback(style: .soft)
                guard let pickedSource = RestingEnergySource(pickerItem: $0) else { return }
                model.changeRestingEnergySource(to: pickedSource)
            }
        )
    }
    
    var sourceSection: some View {
        var label: some View {
            BiometricSourcePickerLabel(source: model.restingEnergySourceBinding.wrappedValue)
        }

        var pickerButton: some View {
            Button {
                Haptics.feedback(style: .soft)
                present(.sourcePicker)
            } label: {
                label
            }
        }
        
        return HStack {
            pickerButton
            Spacer()
        }
        .padding(.horizontal, 17)
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
    
    //MARK: - Equation Content
    
    var equationContent: some View {
        VStack {
            equationRow
            parametersRow
        }
    }
    
    var equationRow: some View {
        
        var equationButton: some View {
            Button {
                Haptics.feedback(style: .soft)
                present(.equationPicker)
            } label: {
                BiometricPickerLabel(model.restingEnergyEquation.menuDescription)
            }
        }
        
        var equationMenu: some View {
            Menu {
                Picker(selection: model.restingEnergyEquationBinding, label: EmptyView()) {
                    ForEach(RestingEnergyEquation.latest, id: \.self) { equation in
                        Text(equation.pickerDescription + " • " + equation.year).tag(equation)
                    }
                    Divider()
                    ForEach(RestingEnergyEquation.legacy, id: \.self) {
                        Text($0.pickerDescription + " • " + $0.year).tag($0)
                    }
                }
            } label: {
                BiometricPickerLabel(model.restingEnergyEquation.menuDescription)
                    .animation(.none, value: model.restingEnergyEquation)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .contentShape(Rectangle())
            .simultaneousGesture(TapGesture().onEnded {
                Haptics.feedback(style: .soft)
            })
        }
        
        return HStack {
            HStack {
                Text("using")
                    .foregroundColor(Color(.tertiaryLabel))
                equationButton
                Text("equation")
                    .foregroundColor(Color(.tertiaryLabel))
            }
        }
        .padding(.top, 8)
    }
    
    var leanBodyMassForm: some View {
        LeanBodyMassForm(model)
    }
    
    var profileForm: some View {
        ProfileForm()
            .environmentObject(model)
    }
    
    var parametersRow: some View {
        
        var lbmFormButton: some View {
            let isSyncedBinding = Binding<Bool>(
                get: { model.restingEnergyEquationVariablesAreSynced },
                set: { _ in }
            )
            return Button {
                Haptics.feedback(style: .soft)
                present(.leanBodyMassForm)
            } label: {
                MeasurementLabel(
                    label: model.hasLeanBodyMass ? "lean body mass" : "set lean body mass",
                    valueString: model.lbmFormattedWithUnit,
                    useHealthAppData: isSyncedBinding.wrappedValue
                )
            }
        }
        
        var profileFormButton: some View {
            
            var usesHeight: Bool {
                model.restingEnergyEquation.requiresHeight
            }
            
            @ViewBuilder
            var label: some View {
                if model.hasRestingEnergyEquationVariables,
                   let age = model.age,
                   let sex = model.sex,
                   let weight = model.weight
                {
                    ProfileLabel(
                        age: age,
                        sex: sex,
                        weight: weight,
                        height: usesHeight ? model.height : nil,
                        bodyMassUnit: UserManager.bodyMassUnit,
                        heightUnit: UserManager.heightUnit,
                        isSynced: model.restingEnergyEquationVariablesAreSynced
                    )
                    .fixedSize(horizontal: true, vertical: false)
                } else {
                    MeasurementLabel(
                        label: "set parameters",
                        valueString: "",
                        useHealthAppData: false
                    )
                }
            }
            
            return Button {
                Haptics.feedback(style: .soft)
                present(.profileForm)
            } label: {
                label
            }
        }
        
        var prefixString: some View {
            Text(model.restingEnergyEquation == .katchMcardle ? "with" : "as")
                .foregroundColor(Color(.tertiaryLabel))
//                .frame(height: 25)
//                .frame(maxHeight: .infinity)
                .padding(.vertical, 5)
                .padding(.bottom, 2)

        }
        
        @ViewBuilder
        var link: some View {
            if model.restingEnergyEquation.usesLeanBodyMass {
                lbmFormButton
            } else {
                profileFormButton
            }
        }

        
        var hStack: some View {
            HStack {
                prefixString
                link
            }
        }
        
        return hStack
    }
    
    func tappedManualEntry() {
        showFormOnAppear = true
        model.changeRestingEnergySource(to: .userEntered)
    }
    
    func tappedSyncWithHealth() {
        Task(priority: .high) {
            do {
                try await HealthKitManager.shared.requestPermission(for: .basalEnergyBurned)
                withAnimation {
                    model.restingEnergySource = .health
                }
                model.syncRestingEnergy()
            } catch {
                cprint("Error syncing with Health: \(error)")
            }
        }
    }
    
    func tappedEquation() {
        model.changeRestingEnergySource(to: .equation)
    }

    var emptyContent: some View {
        HStack {
            BiometricButton(healthTitle: "Sync", action: tappedSyncWithHealth)
            BiometricButton("Calculate", systemImage: "function", action: tappedEquation)
            BiometricButton("Enter", systemImage: "keyboard", action: tappedManualEntry)
        }
        .padding(.horizontal, 15)
    }
    
    var healthContent: some View {
        healthPeriodContent
            .padding()
            .padding(.horizontal)
    }
    
    var bottomRow: some View {
        let valueBinding = Binding<BiometricValue?>(
            get: {
                model.restingEnergyBiometricValue
            },
            set: { newValue in
                guard let energyUnit = newValue?.unit?.energyUnit else { return }
                model.restingEnergy = newValue?.double
                
                /// Convert other energy based values in `BiometricModel` before setting the unit
                if let activeEnergy = model.activeEnergy {
                    model.activeEnergy = UserManager.energyUnit.convert(activeEnergy, to: energyUnit)
                }
                UserManager.energyUnit = energyUnit
                
                /// Delay this by a second so that the core-data persistence doesn't interfere with
                /// the change of energy unit
                model.saveBiometrics(afterDelay: true)
            }
        )
        
        return BiometricValueRow(
            value: valueBinding,
            type: .restingEnergy,
            source: model.restingEnergySource ?? .userEntered,
            syncStatus: model.restingEnergySyncStatus,
            prefix: model.restingEnergyPrefix,
            showFormOnAppear: $showFormOnAppear
        )
        .padding(.horizontal)
    }
    
    enum Sheet: String, Identifiable {
        case profileForm
        case leanBodyMassForm
        case sourcePicker
        case intervalTypePicker
        case intervalPeriodPicker
        case intervalValuePicker
        case equationPicker
        
        var id: String { rawValue }
    }
    
    var intervalTypePickerSheet: some View {
        PickerSheet(
            title: "Choose a value",
            items: HealthIntervalType.pickerItems,
            pickedItem: model.restingEnergyInterval.intervalType.pickerItem,
            didPick: {
                Haptics.feedback(style: .soft)
                guard let pickedType = HealthIntervalType(pickerItem: $0) else { return }
                model.changeRestingEnergyIntervalType(to: pickedType)
            }
        )
    }

    var intervalPeriodPickerSheet: some View {
        PickerSheet(
            title: "Duration to average",
            items: HealthPeriod.pickerItems,
            pickedItem: model.restingEnergyInterval.period.pickerItem,
            didPick: {
                Haptics.feedback(style: .soft)
                guard let pickedPeriod = HealthPeriod(pickerItem: $0) else { return }
                model.changeRestingEnergyIntervalPeriod(to: pickedPeriod)
            }
        )
    }
    
    var equationPickerSheet: some View {
        PickerSheet(
            title: "Equation",
            items: RestingEnergyEquation.pickerItems,
            pickedItem: model.restingEnergyEquation.pickerItem,
            didPick: {
                Haptics.feedback(style: .soft)
                guard let pickedEquation = RestingEnergyEquation(pickerItem: $0) else { return }
                model.changeRestingEnergyEquation(to: pickedEquation)
            }
        )
    }
    
    var intervalValuePickerSheet: some View {
        var items: [PickerItem] {
            model.restingEnergyIntervalValues.map { PickerItem(with: $0) }
        }
        
        return PickerSheet(
            title: "\(model.restingEnergyInterval.period.description.capitalizingFirstLetter())s to average",
            items: items,
            pickedItem: PickerItem(with: model.restingEnergyInterval.value),
            didPick: {
                Haptics.feedback(style: .soft)
                guard let value = Int($0.id) else { return }
                model.changeRestingEnergyIntervalValue(to: value)
            }
        )
    }

    var healthPeriodContent: some View {
        var intervalTypeMenu: some View {
            Button {
                Haptics.feedback(style: .soft)
                present(.intervalTypePicker)
            } label: {
                BiometricPickerLabel(model.restingEnergyInterval.intervalType.menuDescription)
            }
        }
        
        var periodIntervalMenu: some View {
            Button {
                Haptics.feedback(style: .soft)
                present(.intervalPeriodPicker)
            } label: {
                BiometricPickerLabel(
                    "\(model.restingEnergyInterval.period.description)\(model.restingEnergyInterval.value > 1 ? "s" : "")"
                )
            }
        }
        
        
        var intervalValueMenu: some View {
            Button {
                Haptics.feedback(style: .soft)
                present(.intervalValuePicker)
            } label: {
                BiometricPickerLabel("\(model.restingEnergyInterval.value)")
            }
        }
        
        var intervalRow: some View {
            HStack {
                Spacer()
                HStack(spacing: 5) {
                    Text("previous")
                        .foregroundColor(Color(.tertiaryLabel))
                    intervalValueMenu
                    periodIntervalMenu
                }
                Spacer()
            }
        }
        
        return VStack(spacing: 5) {
            HStack {
                Spacer()
                HStack {
                    Text("using")
                        .foregroundColor(Color(.tertiaryLabel))
                    intervalTypeMenu
                }
                Spacer()
            }
            if model.restingEnergyInterval.intervalType == .average {
                intervalRow
            }
        }
    }
    
    @ViewBuilder
    var footer: some View {
        if let string = model.restingEnergyFooterString {
            Text(string)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(Color(.secondaryLabel))
                .font(.footnote)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
        }
    }
}

extension HealthPeriod {
    static var pickerItems: [PickerItem] {
        allCases.map { $0.pickerItem }
    }
    
    init?(pickerItem: PickerItem) {
        guard let int16 = Int16(pickerItem.id),
              let source = HealthPeriod(rawValue: int16) else {
            return nil
        }
        self = source
    }
    
    var pickerItem: PickerItem {
        PickerItem(
            id: "\(self.rawValue)",
            title: description,
            detail: nil,
            secondaryDetail: nil
        )
    }
}


extension HealthIntervalType {
    static var pickerItems: [PickerItem] {
        allCases.map { $0.pickerItem }
    }
    
    init?(pickerItem: PickerItem) {
        guard let int16 = Int16(pickerItem.id),
              let source = HealthIntervalType(rawValue: int16) else {
            return nil
        }
        self = source
    }
    
    var pickerItem: PickerItem {
        PickerItem(
            id: "\(self.rawValue)",
            title: pickerDescription,
            detail: pickerDetail,
            secondaryDetail: pickerSecondaryDetail,
            systemImage: systemImage
        )
    }
    
    var systemImage: String? {
        switch self {
        case .latest:
            return "calendar.badge.clock"
        case .average:
            return "sum"
        }
    }

    var pickerDetail: String? {
        switch self {
        case .latest:
            return "Use the latest available value."
        case .average:
            return "Use the average daily value of the past x days/weeks/months. "
        }
    }

    var pickerSecondaryDetail: String? {
        switch self {
        case .latest:
            return nil
        case .average:
            return "This will a rolling average that updates every day."
        }
    }
}

extension RestingEnergyEquation {
    static var pickerItems: [PickerItem] {
        allCases
            .sorted(by: { $0.year > $1.year })
            .map { $0.pickerItem }
    }
    
    init?(pickerItem: PickerItem) {
        guard let int16 = Int16(pickerItem.id),
              let source = RestingEnergyEquation(rawValue: int16) else {
            return nil
        }
        self = source
    }
    
    var pickerItem: PickerItem {
        PickerItem(
            id: "\(self.rawValue)",
            title: pickerTitle,
            detail: pickerDetail,
            secondaryDetail: pickerSecondaryDetail
        )
    }
    
    var pickerTitle: String {
        "\(pickerDescription) • \(year)"
    }

    var pickerDetail: String? {
        switch self {
        case .rozaShizgal:
            return "This is the revised Harris-Benedict equation."
        case .schofield:
            return "This is the equation used by the WHO."
        default:
            return nil
        }
    }

    var pickerSecondaryDetail: String? {
        switch self {
        case .katchMcardle, .cunningham:
            return "Uses your lean body mass."
        case .henryOxford, .schofield:
            return "Uses your age, weight and biological sex."
        case .mifflinStJeor, .rozaShizgal, .harrisBenedict:
            return "Uses your age, weight, height and biological sex."
        }
    }
}
