import SwiftUI
import SwiftHaptics
import PrepDataTypes
import ActivityIndicatorView
import SwiftUISugar
import PrepCoreDataStack

struct LeanBodyMassSection: View {
    
    let includeHeader: Bool
    @Binding var footerString: String
    @EnvironmentObject var model: BiometricsModel
    @State var showFormOnAppear = false
    @State var presentedSheet: Sheet? = nil
    
    enum Sheet: String, Identifiable {
        case sourcePicker
        case equationPicker
        
        var id: String { rawValue }
    }

    init(includeHeader: Bool = true, footerString: Binding<String> = .constant("")) {
        self.includeHeader = includeHeader
        _footerString = footerString
    }
    
    var body: some View {
        FormStyledSection(header: header) {
            content
        }
        .sheet(item: $presentedSheet) { sheet(for: $0) }
    }
    
    @ViewBuilder
    func sheet(for sheet: Sheet) -> some View {
        switch sheet {
        case .sourcePicker:
            sourcePickerSheet
        case .equationPicker:
            equationPickerSheet
        }
    }
    
    var equationPickerSheet: some View {
        PickerSheet(
            title: "Equation",
            items: LeanBodyMassEquation.pickerItems,
            pickedItem: model.lbmEquation.pickerItem,
            didPick: {
                Haptics.feedback(style: .soft)
                guard let pickedEquation = LeanBodyMassEquation(pickerItem: $0) else { return }
                model.changeLBMEquation(to: pickedEquation)
            }
        )
    }

    @ViewBuilder
    var header: some View {
        if includeHeader {
            BiometricSectionHeader(type: .leanBodyMass)
                .environmentObject(model)
        }
    }
    
    @ViewBuilder
    var footer: some View {
        if !footerString.isEmpty {
            Text(footerString)
        }
    }

    var content: some View {
        VStack {
            Group {
                if let source = model.lbmSource {
                    Group {
                        sourceSection
                        switch source {
                        case .health:
//                            healthContent
                            EmptyView()
                        case .userEntered:
                            EmptyView()
                        case .fatPercentage:
                            EmptyView()
                        case .equation:
                            equationContent
                        }
                        bottomRow
                    }
                } else {
                    emptyContent
                }
            }
        }
    }

    var equationContent: some View {
        
        var equationRow: some View {
            
            var button: some View {
                Button {
                    Haptics.feedback(style: .soft)
                    present(.equationPicker)
                } label: {
                    PickerLabel(
                        model.lbmEquation.year,
                        prefix: model.lbmEquation.menuDescription,
                        foregroundColor: .secondary,
                        prefixColor: .primary,
                        isLarge: true
                    )
                }
            }

            return HStack {
                HStack {
                    Text("using")
                        .foregroundColor(Color(.tertiaryLabel))
                    button
                    Text("equation")
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }
            .padding(.top, 8)
        }
        
        return VStack {
            equationRow
                .padding(.bottom)
        }
    }
    
    func tappedSyncWithHealth() {
        model.changeLBMSource(to: .health)
    }
    
    func tappedEquation() {
        model.changeLBMSource(to: .equation)
    }
    
    func tappedFatPercentage() {
        showFormOnAppear = true
        model.changeLBMSource(to: .fatPercentage)
    }
    
    func tappedManualEntry() {
        showFormOnAppear = true
        model.changeLBMSource(to: .userEntered)
    }
    
    var emptyContent: some View {
        VStack {
            HStack {
                BiometricButton(healthTitle: "Sync", action: tappedSyncWithHealth)
                BiometricButton("Enter", systemImage: "keyboard", action: tappedManualEntry)
            }
            HStack {
                BiometricButton("Calculate", systemImage: "function", action: tappedEquation)
                BiometricButton("Enter Fat %", systemImage: "function", action: tappedFatPercentage)
            }
        }
    }

    var bottomRow: some View {
        let valueBinding = Binding<BiometricValue?>(
            get: { model.leanBodyMassBiometricValue },
            set: { newValue in
                
                if model.lbmSource == .fatPercentage {
                    if let double = newValue?.double {
                        model.lbm = max(min(double, 100), 0)
                    }
                    //TODO: What else do we do after setting percentage?
                    
                } else {
                    guard let bodyMassUnit = newValue?.unit?.bodyMassUnit else { return }
                    model.lbm = newValue?.double
                        
                    /// Convert other body mass based values in `BiometricModel` before setting the unit
                    if let weight = model.weight {
                        model.weight = UserManager.bodyMassUnit.convert(weight, to: bodyMassUnit)
                    }
                    
                    UserManager.bodyMassUnit = bodyMassUnit
                }
                
                /// Delay this by a second so that the core-data persistence doesn't interfere with
                /// the change of energy unit
                model.saveBiometrics(afterDelay: true)
            }
        )
        
        let computedValueBinding = Binding<BiometricValue?>(
            get: {
                guard let calculated = model.calculatedLeanBodyMass else { return nil }
                return .leanBodyMass(calculated, UserManager.bodyMassUnit)
            },
            set: { _ in }
        )
        
        var placeholder: String? {
            var missing: [BiometricType] = []
            if model.weight == nil { missing.append(.weight) }
            if model.height == nil { missing.append(.height) }
            if model.sex == nil { missing.append(.sex) }
            guard !missing.isEmpty else { return nil }
            return "needs \(missing.map({$0.shortDescription}).joined(separator: ", "))"
        }
        
        return HStack {
            BiometricValueRow(
                value: valueBinding,
                computedValue: computedValueBinding,
                type: .leanBodyMass,
                source: model.lbmSource ?? .userEntered,
                syncStatus: model.lbmSyncStatus,
                prefix: model.lbmPrefix,
                placeholder: placeholder,
                showFormOnAppear: $showFormOnAppear
            )
        }
    }
    
    var sourcePickerSheet: some View {
        PickerSheet(
            title: "Choose a Source",
            items: LeanBodyMassSource.pickerItems,
            pickedItem: model.lbmSource?.pickerItem,
            didPick: {
                Haptics.feedback(style: .soft)
                guard let pickedSource = LeanBodyMassSource(pickerItem: $0) else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    model.changeLBMSource(to: pickedSource)
                }
            }
        )
    }

    var sourceSection: some View {
  
        var label: some View {
            BiometricSourcePickerLabel(source: model.lbmSourceBinding.wrappedValue)
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
}

extension LeanBodyMassEquation {
    static var pickerItems: [PickerItem] {
        allCases
            .sorted(by: { $0.year > $1.year })
            .map { $0.pickerItem }
    }
    
    init?(pickerItem: PickerItem) {
        guard let int16 = Int16(pickerItem.id),
              let source = LeanBodyMassEquation(rawValue: int16) else {
            return nil
        }
        self = source
    }
    
    var pickerItem: PickerItem {
        PickerItem(
            id: "\(self.rawValue)",
            title: pickerTitle,
            detail: nil,
            secondaryDetail: pickerDetail
        )
    }
    
    var pickerTitle: String {
        "\(pickerDescription)"
    }

    var pickerDetail: String? {
        switch self {
        case .boer:
            return "Best suitable for obese individuals."
        case .james:
            return "The is the most widely used equation."
        case .hume:
            return "This is an old but dependable equation that was confirmed in a 2015 research to be reliable."
        }
    }

    var pickerSecondaryDetail: String? {
        return nil
        switch self {
        case .boer:
            return "Uses your weight, height and biological sex."
        case .james:
            return "Uses your weight, height and biological sex."
        case .hume:
            return "Uses your weight, height and biological sex."
        }
    }
}
