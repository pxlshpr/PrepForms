import SwiftUI
import SwiftHaptics
import PrepDataTypes
import ActivityIndicatorView
import SwiftUISugar

struct LeanBodyMassSection: View {
    
    let includeHeader: Bool
    @Binding var footerString: String
    @EnvironmentObject var model: BiometricsModel

    @Namespace var namespace
    @FocusState var isFocused: Bool
    
    init(includeHeader: Bool = true, footerString: Binding<String> = .constant("")) {
        self.includeHeader = includeHeader
        _footerString = footerString
    }
    
    var body: some View {
        FormStyledSection(header: header, footer: footer) {
            content
        }
        .onChange(of: model.lbmSource, perform: lbmSourceChanged)
    }
    
    @ViewBuilder
    var header: some View {
        if includeHeader {
            Text("Lean Body Mass")
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
                        case .healthApp:
//                            healthContent
                            EmptyView()
                        case .userEntered:
                            EmptyView()
                        case .fatPercentage:
                            EmptyView()
                        case .formula:
                            formulaContent
                        }
                        bottomRow
                    }
                } else {
                    emptyContent
                }
            }
        }
    }

    var formulaContent: some View {
        var formulaRow: some View {
            var menu: some View {
                Menu {
                    Picker(selection: model.lbmFormulaBinding, label: EmptyView()) {
                        ForEach(LeanBodyMassFormula.allCases, id: \.self) {
                            Text($0.pickerDescription).tag($0)
                        }
                    }
                } label: {
                    PickerLabel(
                        model.lbmFormula.year,
                        prefix: model.lbmFormula.menuDescription,
                        foregroundColor: .secondary,
                        prefixColor: .primary
                    )
                    .animation(.none, value: model.lbmFormula)
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
                    menu
                    Text("formula")
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }
            .padding(.top, 8)
        }
        
        return VStack {
            formulaRow
                .padding(.bottom)
        }
    }
    
    func tappedSyncWithHealth() {
        model.changeLBMSource(to: .healthApp)
    }
    
    func tappedFormula() {
        model.changeLBMSource(to: .formula)
    }
    
    func tappedFatPercentage() {
        model.changeLBMSource(to: .fatPercentage)
        isFocused = true
    }
    
    func tappedManualEntry() {
        model.changeLBMSource(to: .userEntered)
        isFocused = true
    }
    
    var emptyContent: some View {
        VStack {
            HStack {
                BiometricButton(healthTitle: "Sync", action: tappedSyncWithHealth)
                BiometricButton("Enter", systemImage: "keyboard", action: tappedManualEntry)
            }
            HStack {
                BiometricButton("Calculate", systemImage: "function", action: tappedFormula)
                BiometricButton("Use Fat %", systemImage: "function", action: tappedFatPercentage)
            }
        }
    }

    var bottomRow: some View {
        @ViewBuilder
        var health: some View {
            switch model.lbmFetchStatus {
            case .noData:
                Text("No Data")
            case .noDataOrNotAuthorized:
                Text("No Data or Not Authorized")
            case .notFetched, .fetching, .fetched:
                HStack {
                    Spacer()
                    if model.lbmFetchStatus == .fetching {
                        ActivityIndicatorView(isVisible: .constant(true), type: .opacityDots())
                            .frame(width: 25, height: 25)
                            .foregroundColor(.secondary)
                    } else {
                        if let date = model.lbmDate {
                            Text("as of \(date.tdeeFormat)")
                                .font(.subheadline)
                                .foregroundColor(Color(.tertiaryLabel))
                        }
                        Text(model.lbmFormatted)
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                            .foregroundColor(model.lbmSource == .userEntered ? .primary : .secondary)
                            .matchedGeometryEffect(id: "lbm", in: namespace)
                            .if(!model.hasLeanBodyMass) { view in
                                view
                                    .redacted(reason: .placeholder)
                            }
                        Text(model.userWeightUnit.shortDescription)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        
        var manualEntry: some View {
            var prompt: String {
                model.lbmSource == .userEntered ? "lean body mass in" : "fat percent"
            }
            var binding: Binding<String> {
                model.lbmTextFieldStringBinding
            }
            var unitString: String {
                model.lbmSource == .fatPercentage ? "%" : model.userWeightUnit.shortDescription
            }
            return HStack {
                Spacer()
                TextField(prompt, text: binding)
                    .keyboardType(.decimalPad)
                    .focused($isFocused)
                    .multilineTextAlignment(.trailing)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .matchedGeometryEffect(id: "lbm", in: namespace)
                Text(unitString)
                    .foregroundColor(.secondary)
            }
        }
        
        var calculatedLBMRow: some View {
            HStack {
                Spacer()
                if model.lbmSource == .fatPercentage {
                    Text("lean body mass")
                        .font(.subheadline)
                        .foregroundColor(Color(.tertiaryLabel))
                }
                Text(model.calculatedLBMFormatted)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundColor(.secondary)
                    .if(!model.hasLeanBodyMass) { view in
                        view
                            .redacted(reason: .placeholder)
                    }
                Text(model.userWeightUnit.shortDescription)
                    .foregroundColor(.secondary)
            }
        }
     
        return Group {
            switch model.lbmSource {
            case .healthApp:
                health
            case .formula:
                calculatedLBMRow
            case .userEntered:
                manualEntry
            case .fatPercentage:
                manualEntry
                calculatedLBMRow
            default:
                EmptyView()
            }
        }
    }
    
    var sourceSection: some View {
        var sourceMenu: some View {
            Menu {
                Picker(selection: model.lbmSourceBinding, label: EmptyView()) {
                    ForEach(LeanBodyMassSource.allCases, id: \.self) {
                        Label($0.pickerDescription, systemImage: $0.systemImage).tag($0)
                    }
                }
            } label: {
                BiometricSourcePickerLabel(source: model.lbmSourceBinding.wrappedValue)
            }
            .animation(.none, value: model.lbmSource)
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
//        .padding(.horizontal, 17)
    }
    
    func lbmSourceChanged(to newSource: LeanBodyMassSource?) {
        switch newSource {
        case .userEntered:
            isFocused = true
        default:
            break
        }
    }
}
