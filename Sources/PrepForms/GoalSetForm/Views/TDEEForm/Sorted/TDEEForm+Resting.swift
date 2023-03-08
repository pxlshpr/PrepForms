import SwiftUI
import SwiftHaptics
import PrepDataTypes
import ActivityIndicatorView
import SwiftUISugar
import HealthKit

//func label(_ label: String, _ valueString: String) -> some View {

//let AppleHealthBottomColorHex = "fc2e1d"
//let AppleHealthTopColorHex = "fe5fab"

//var appleHealthSymbol: some View {
//    Image(systemName: "heart.fill")
//        .symbolRenderingMode(.palette)
//        .foregroundStyle(
//            .linearGradient(
//                colors: [
//                    Color(hex: AppleHealthTopColorHex),
//                    Color(hex: AppleHealthBottomColorHex)
//                ],
//                startPoint: .top,
//                endPoint: .bottom
//            )
//        )
//}

struct MeasurementLabel: View {
    @Environment(\.colorScheme) var colorScheme
    
    let label: String
    let valueString: String
    let useHealthAppData: Bool
    
    var body: some View {
        ButtonLabel(
            title: string,
            prefix: prefix,
            style: style,
            trailingSystemImage: systemImage,
            trailingImageScale: .small
        )
    }
    
    var systemImage: String? {
        useHealthAppData ? nil : "chevron.right"
    }
    
    var body_legacy: some View {
        PickerLabel(
            string,
            prefix: prefix,
            systemImage: systemImage,
            imageColor: imageColor,
            backgroundColor: backgroundColor,
            backgroundGradientTop: backgroundGradientTop,
            backgroundGradientBottom: backgroundGradientBottom,
            foregroundColor: foregroundColor,
            prefixColor: prefixColor,
            infiniteMaxHeight: false
        )
    }
    
    var style: ButtonLabel.Style {
        if useHealthAppData {
            return .health
        }
        return valueString.isEmpty ? .accent : .plain
    }
    
    var backgroundGradientTop: Color? {
        guard useHealthAppData else {
            return nil
        }
        return Color(hex: AppleHealthTopColorHex)
    }
    var backgroundGradientBottom: Color? {
        guard useHealthAppData else {
            return nil
        }
        return Color(hex: AppleHealthBottomColorHex)
    }

    var backgroundColor: Color {
        guard !valueString.isEmpty else {
            return .accentColor
        }
        let defaultColor = colorScheme == .light ? Color(hex: "e8e9ea") : Color(hex: "434447")
        return useHealthAppData ? Color(.systemGroupedBackground) : defaultColor
    }
    
    var foregroundColor: Color {
        guard !valueString.isEmpty else {
            return .white
        }
        if useHealthAppData {
            return Color.white
//            return Color(.secondaryLabel)
        } else {
            return Color.primary
        }
    }
    var prefixColor: Color {
        if useHealthAppData {
            return Color(hex: "F3DED7")
//            return Color(.secondaryLabel)
//            return Color(.tertiaryLabel)
        } else {
            return Color.secondary
        }
    }
    
    var string: String {
        valueString.isEmpty ? label : valueString
    }
    
    var prefix: String? {
        valueString.isEmpty ? nil : label
    }
    
    var imageColor: Color {
        valueString.isEmpty ? .white : Color(.tertiaryLabel)
    }
}

struct MeasurementLabel_Previews: PreviewProvider {
    static var previews: some View {
        FormStyledScrollView {
            FormStyledSection {
                MeasurementLabel(
                    label: "weight",
                    valueString: "93.55",
                    useHealthAppData: true
                )
            }
        }
    }
}

extension TDEEForm {
    
    var restingEnergySection: some View {
//        var syncWithHealthAppToggle: some View {
//            Toggle(isOn: model.restingEnergyFormulaUsingSyncedHealthDataBinding) {
//                HStack {
//                    appleHealthSymbol
//                        .matchedGeometryEffect(id: "resting-health-icon", in: namespace)
//                    Text("Sync\(model.restingEnergyFormulaUsingSyncedHealthData ? "ed" : "") with Health App")
//                }
//            }
//            .toggleStyle(.button)
//        }
        
        var sourceSection: some View {
            var sourceMenu: some View {
                Menu {
                    Picker(selection: model.restingEnergySourceBinding, label: EmptyView()) {
                        ForEach(RestingEnergySource.allCases, id: \.self) {
                            Label($0.menuDescription, systemImage: $0.systemImage).tag($0)
                        }
                    }
                } label: {
                    BiometricSourcePickerLabel(source: model.restingEnergySourceBinding.wrappedValue)
                }
                .animation(.none, value: model.restingEnergySource)
                .fixedSize(horizontal: true, vertical: false)
                .contentShape(Rectangle())
                .simultaneousGesture(TapGesture().onEnded {
                    Haptics.feedback(style: .light)
                })
            }
            
            return HStack {
                sourceMenu
                Spacer()
            }
            .padding(.horizontal, 17)
        }
        
        //MARK: - Formula Content
        
        var formulaContent: some View {
            VStack {
                formulaRow
                flowView
            }
        }
        
        var formulaRow: some View {
            var formulaMenu: some View {
                Menu {
                    Picker(selection: model.restingEnergyFormulaBinding, label: EmptyView()) {
                        ForEach(RestingEnergyFormula.latest, id: \.self) { formula in
                            Text(formula.pickerDescription + " • " + formula.year).tag(formula)
                        }
                        Divider()
                        ForEach(RestingEnergyFormula.legacy, id: \.self) {
                            Text($0.pickerDescription + " • " + $0.year).tag($0)
                        }
                    }
                } label: {
//                    PickerLabel(
//                        model.restingEnergyFormula.year,
//                        prefix: model.restingEnergyFormula.menuDescription,
//                        foregroundColor: .secondary,
//                        prefixColor: .primary
//                    )
//                    PickerLabel(model.restingEnergyFormula.menuDescription)
                    BiometricPickerLabel(model.restingEnergyFormula.menuDescription)
                        .animation(.none, value: model.restingEnergyFormula)
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
                    formulaMenu
                    Text("formula")
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }
            .padding(.top, 8)
        }
        
        var flowView: some View {
            
            return FlowView(alignment: .center, spacing: 10, padding: 17) {
                ZStack {
                    Capsule(style: .continuous)
                        .foregroundColor(Color(.clear))
                    Text(model.restingEnergyFormula == .katchMcardle ? "with" : "as")
                        .foregroundColor(Color(.tertiaryLabel))
                    .frame(height: 25)
                    .padding(.vertical, 5)
                    .padding(.bottom, 2)
                }
                .fixedSize(horizontal: true, vertical: true)
                if model.restingEnergyFormula.usesLeanBodyMass {
//                    Button {
//                        model.path.append(.leanBodyMassForm)
                    NavigationLink {
                        LeanBodyMassForm()
                            .environmentObject(model)
                    } label: {
                        MeasurementLabel(
                            label: model.hasLeanBodyMass ? "lean body mass" : "set lean body mass",
                            valueString: model.lbmFormattedWithUnit,
                            useHealthAppData: model.restingEnergyFormulaUsingSyncedHealthData
                        )
                    }
                } else {
//                    Button {
//                        model.path.append(.profileForm)
                    NavigationLink {
                        ProfileForm()
                            .environmentObject(model)
                    } label: {
                        if model.hasProfile,
                           let age = model.age,
                           let sex = model.sex,
                           let weight = model.weight
                        {
                            ProfileLabel(
                                age: age,
                                sex: sex,
                                weight: weight,
                                height: model.height,
                                weightUnit: model.userWeightUnit,
                                heightUnit: model.userHeightUnit,
                                isSynced: model.profileIsSynced
                            )
                        } else {
                            MeasurementLabel(
                                label: "set biometrics",
                                valueString: "",
                                useHealthAppData: false
                            )
                        }
                    }
//                    Menu {
//                        Picker(selection: .constant(true), label: EmptyView()) {
//                            Text("Male").tag(true)
//                            Text("Female").tag(false)
//                        }
//                    } label: {
//                        MeasurementLabel(
//                            label: "sex",
//                            valueString: "male",
//                            useHealthAppData: model.restingEnergyFormulaUsingSyncedHealthData
//                        )
//                    }
//                    Button {
//                        model.path.append(.weightForm)
//                    } label: {
//                        MeasurementLabel(
//                            label: "weight",
//                            valueString: "93.6 kg",
//                            useHealthAppData: model.restingEnergyFormulaUsingSyncedHealthData
//                        )
//                    }
//                    Button {
//                        model.path.append(.heightForm)
//                    } label: {
//                        MeasurementLabel(
//                            label: "height",
//                            valueString: "177 cm",
//                            useHealthAppData: model.restingEnergyFormulaUsingSyncedHealthData
//                        )
//                    }
                }
            }
            .padding(.bottom, 5)
        }
        
        @ViewBuilder
        var content: some View {
            VStack {
                Group {
                    if let source = model.restingEnergySource {
                        Group {
                            sourceSection
                            switch source {
                            case .healthApp:
                                healthContent
                            case .userEntered:
                                EmptyView()
                            case .formula:
                                formulaContent
                            }
                            energyRow
                        }
                    } else {
                        emptyContent
                    }
                }
            }
        }
        
//        var manualEntryContent: some View {
//            VStack {
//                sourceSection
//                energyRow
//            }
//        }
        
        func tappedManualEntry() {
            model.changeRestingEnergySource(to: .userEntered)
            restingEnergyTextFieldIsFocused = true
        }
        
        func tappedSyncWithHealth() {
            Task(priority: .high) {
                do {
                    try await HealthKitManager.shared.requestPermission(for: .basalEnergyBurned)
                    withAnimation {
                        model.restingEnergySource = .healthApp
                    }
                    model.fetchRestingEnergyFromHealth()
                } catch {
                    cprint("Error syncing with Health: \(error)")
                }
            }
        }
        
        func tappedFormula() {
            model.changeRestingEnergySource(to: .formula)
        }

        var emptyContent: some View {
//            VStack(spacing: 10) {
//                emptyButton("Sync with Health app", showHealthAppIcon: true, action: tappedSyncWithHealth)
//                emptyButton("Calculate using a Formula", systemImage: "function", action: tappedFormula)
//                emptyButton("Let me type it in", systemImage: "keyboard", action: tappedManualEntry)
//            }
//            HStack {
//                Spacer()
//                emptyButton2("Sync", showHealthAppIcon: true, action: tappedSyncWithHealth)
//                Spacer()
//                emptyButton2("Calculate", systemImage: "function", action: tappedFormula)
//                Spacer()
//                emptyButton2("Enter", systemImage: "keyboard", action: tappedManualEntry)
//                Spacer()
//            }
            FlowView(alignment: BiometricButtonsAlignment, spacing: 10, padding: 17) {
//                emptyButton2("Calculate", systemImage: "function", action: tappedFormula)
//                emptyButton2("Enter", systemImage: "keyboard", action: tappedManualEntry)
//                emptyButton2("Sync", showHealthAppIcon: true, action: tappedSyncWithHealth)
                BiometricButton("Calculate", systemImage: "function", action: tappedFormula)
                BiometricButton("Enter", systemImage: "keyboard", action: tappedManualEntry)
                BiometricHealthButton("Sync", action: tappedSyncWithHealth)
            }
            .padding(.horizontal, 15)
        }
        
        var healthContent: some View {
            Group {
                if model.restingEnergyFetchStatus == .notAuthorized {
                    permissionRequiredContent
                } else {
                    healthPeriodContent
                }
            }
            .padding()
            .padding(.horizontal)
        }
        
        var energyRow: some View {
            @ViewBuilder
            var health: some View {
                if model.restingEnergyFetchStatus != .notAuthorized {
                    HStack {
                        Spacer()
                        if model.restingEnergyFetchStatus == .fetching {
                            ActivityIndicatorView(isVisible: .constant(true), type: .opacityDots())
                                .frame(width: 25, height: 25)
                                .foregroundColor(.secondary)
                        } else {
                            if let prefix = model.restingEnergyPrefix {
                                Text(prefix)
                                    .font(.subheadline)
                                    .foregroundColor(Color(.tertiaryLabel))
                            }
                            Text(model.restingEnergyFormatted)
                                .font(.system(.title3, design: .rounded, weight: .semibold))
                                .foregroundColor(model.restingEnergySource == .userEntered ? .primary : .secondary)
                                .fixedSize(horizontal: true, vertical: false)
                                .matchedGeometryEffect(id: "resting", in: namespace)
                                .if(!model.hasRestingEnergy) { view in
                                    view
                                        .redacted(reason: .placeholder)
                                }
                            Text(model.userEnergyUnit.shortDescription)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            var formula: some View {
                HStack {
                    Spacer()
                    Text(model.restingEnergyFormatted)
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: true, vertical: false)
                        .matchedGeometryEffect(id: "resting", in: namespace)
                        .if(!model.hasRestingEnergy) { view in
                            view
                                .redacted(reason: .placeholder)
                        }
                    Text(model.userEnergyUnit.shortDescription)
                        .foregroundColor(.secondary)
                }
            }
            
            var manualEntry: some View {
                HStack {
                    Spacer()
                    TextField("energy in", text: model.restingEnergyTextFieldStringBinding)
                        .keyboardType(.decimalPad)
                        .focused($restingEnergyTextFieldIsFocused)
                        .fixedSize(horizontal: true, vertical: false)
                        .multilineTextAlignment(.trailing)
//                        .fixedSize(horizontal: true, vertical: false)
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .matchedGeometryEffect(id: "resting", in: namespace)
                    Text(model.userEnergyUnit.shortDescription)
                        .foregroundColor(.secondary)
                }
            }
            
            return Group {
                switch model.restingEnergySource {
                case .healthApp:
                    health
                case .formula:
                    formula
                case .userEntered:
                    manualEntry
                default:
                    EmptyView()
                }
            }
            .padding(.trailing)
        }
        
        var healthPeriodContent: some View {
            var periodTypeMenu: some View {
               Menu {
                   Picker(selection: model.restingEnergyPeriodBinding, label: EmptyView()) {
                        ForEach(HealthPeriodOption.allCases, id: \.self) {
                            Text($0.pickerDescription).tag($0)
                        }
                    }
                } label: {
                    PickerLabel(
                        model.restingEnergyPeriod.menuDescription,
                        imageColor: Color(hex: "F3DED7"),
                        backgroundGradientTop: Color(hex: AppleHealthTopColorHex),
                        backgroundGradientBottom: Color(hex: AppleHealthBottomColorHex),
                        foregroundColor: .white
                    )
                    .animation(.none, value: model.restingEnergyPeriod)
                    .fixedSize(horizontal: true, vertical: false)
                }
                .contentShape(Rectangle())
                .simultaneousGesture(TapGesture().onEnded {
                    Haptics.feedback(style: .soft)
                })

            }
            
            var periodValueMenu: some View {
                Menu {
                    Picker(selection: model.restingEnergyIntervalValueBinding, label: EmptyView()) {
                        ForEach(model.restingEnergyIntervalValues, id: \.self) { quantity in
                            Text("\(quantity)").tag(quantity)
                        }
                    }
                } label: {
                    PickerLabel(
                        "\(model.restingEnergyIntervalValue)",
                        imageColor: Color(hex: "F3DED7"),
                        backgroundGradientTop: Color(hex: AppleHealthTopColorHex),
                        backgroundGradientBottom: Color(hex: AppleHealthBottomColorHex),
                        foregroundColor: .white
                    )
                    .animation(.none, value: model.restingEnergyIntervalValue)
                    .animation(.none, value: model.restingEnergyInterval)
                    .fixedSize(horizontal: true, vertical: false)
                }
                .contentShape(Rectangle())
                .simultaneousGesture(TapGesture().onEnded {
                    Haptics.feedback(style: .soft)
                })

            }
            
            var periodIntervalMenu: some View {
                Menu {
                    Picker(selection: model.restingEnergyIntervalBinding, label: EmptyView()) {
                        ForEach(HealthAppInterval.allCases, id: \.self) { interval in
                            Text("\(interval.description)\(model.restingEnergyIntervalValue > 1 ? "s" : "")").tag(interval)
                        }
                    }
                } label: {
                    PickerLabel(
                        "\(model.restingEnergyInterval.description)\(model.restingEnergyIntervalValue > 1 ? "s" : "")",
                        imageColor: Color(hex: "F3DED7"),
                        backgroundGradientTop: Color(hex: AppleHealthTopColorHex),
                        backgroundGradientBottom: Color(hex: AppleHealthBottomColorHex),
                        foregroundColor: .white
                    )
                    .animation(.none, value: model.restingEnergyInterval)
                    .animation(.none, value: model.restingEnergyIntervalValue)
                    .fixedSize(horizontal: true, vertical: false)
                }
                .contentShape(Rectangle())
                .simultaneousGesture(TapGesture().onEnded {
                    Haptics.feedback(style: .soft)
                })

            }
            
            var intervalRow: some View {
                HStack {
                    Spacer()
                    HStack(spacing: 5) {
                        Text("previous")
                            .foregroundColor(Color(.tertiaryLabel))
                        periodValueMenu
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
                        periodTypeMenu
                    }
                    Spacer()
                }
                if model.restingEnergyPeriod == .average {
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
        
        return VStack(spacing: 7) {
                restingHeader
                    .textCase(.uppercase)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(Color(.secondaryLabel))
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                content
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 0)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(Color(.secondarySystemGroupedBackground))
                        .matchedGeometryEffect(id: "resting-bg", in: namespace)
                )
                .if(model.restingEnergyFooterString == nil) { view in
                    view.padding(.bottom, 10)
                }
                footer
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
    }
}

func emptyButton(_ string: String, systemImage: String? = nil, showHealthAppIcon: Bool = false, action: (() -> ())? = nil) -> some View {
    Button {
        action?()
    } label: {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage)
//                    .foregroundColor(.white)
                    .foregroundColor(.white.opacity(0.7))
            } else if showHealthAppIcon {
                appleHealthSymbol
            }
            Text(string)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(.white)
//                .foregroundColor(.secondary)
        }
        .frame(minHeight: 30)
        .padding(.horizontal, 15)
        .padding(.vertical, 5)
        .background (
            Capsule(style: .continuous)
                .foregroundColor(.accentColor)
//                .foregroundColor(Color(.secondarySystemFill))
        )
    }
}

var permissionRequiredContent: some View  {
    VStack {
        VStack(alignment: .center, spacing: 5) {
            Text("Health app integration requires permissions to be granted in:")
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(.secondary)
            Text("Settings → Privacy & Security → Health → Prep")
                .font(.footnote)
                .foregroundColor(Color(.tertiaryLabel))
        }
        .multilineTextAlignment(.center)
        Button {
            UIApplication.shared.open(URL(string: "App-prefs:Privacy&path=HEALTH")!)
        } label: {
            ButtonLabel(title: "Go to Settings", leadingSystemImage: "gear")
//            HStack {
//                Image(systemName: "gear")
//                Text("Go to Settings")
//                    .fixedSize(horizontal: true, vertical: false)
//            }
//            .foregroundColor(.white)
//            .padding(.horizontal)
//            .padding(.vertical, 12)
//            .background(
//                RoundedRectangle(cornerRadius: 20, style: .continuous)
//                    .foregroundColor(Color.accentColor)
//            )
        }
        .buttonStyle(.borderless)
        .padding(.top, 5)
    }
}
