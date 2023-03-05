import SwiftUI
import SwiftHaptics
import PrepDataTypes
import ActivityIndicatorView
import SwiftUISugar

struct LeanBodyMassForm: View {
    
    @EnvironmentObject var model: TDEEForm.Model
    @Namespace var namespace
    @FocusState var isFocused: Bool
    
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
//        VStack(spacing: 10) {
//            emptyButton("Sync with Health app", showHealthAppIcon: true, action: tappedSyncWithHealth)
//            emptyButton("Calculate using a Formula", systemImage: "function", action: tappedFormula)
//            emptyButton("Convert Fat Percentage", systemImage: "percent", action: tappedFatPercentage)
//            emptyButton("Let me type it in", systemImage: "keyboard", action: tappedManualEntry)
//        }
        FlowView(alignment: .center, spacing: 10, padding: 37) {
            emptyButton2("Sync with Health app", showHealthAppIcon: true, action: tappedSyncWithHealth)
            emptyButton2("Calculate", systemImage: "function", action: tappedFormula)
            emptyButton2("Fat Percentage", systemImage: "percent", action: tappedFatPercentage)
            emptyButton2("Enter Manually", systemImage: "keyboard", action: tappedManualEntry)
        }
    }

    var infoSection: some View {
        FormStyledSection {
            Text("Lean body mass is the weight of your body minus your body fat (adipose tissue).")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    var bottomRow: some View {
        @ViewBuilder
        var health: some View {
            if model.lbmFetchStatus != .notAuthorized {
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
                HStack(spacing: 5) {
                    HStack {
                        if model.lbmSource == .healthApp {
                            appleHealthSymbol
                        } else {
                            if let systemImage = model.lbmSource?.systemImage {
                                Image(systemName: systemImage)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Text(model.lbmSource?.menuDescription ?? "")
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    Image(systemName: "chevron.up.chevron.down")
                        .imageScale(.small)
                }
                .foregroundColor(.secondary)
                .animation(.none, value: model.lbmSource)
                .fixedSize(horizontal: true, vertical: false)
            }
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
    
    var footer: some View {
        var string: String {
            switch model.lbmSource {
            case .userEntered:
                return "You will need to ensure your lean body mass is kept up to date for an accurate calculation."
            case .healthApp:
                return "Your lean body mass will be kept in sync with the Health App."
            case .formula:
                return "Use a formula to calculate your lean body mass."
            case .fatPercentage:
                return "Enter your fat percentage to calculate your lean body mass."
            default:
                return "Choose how you want to enter your lean body mass."
            }
        }
        return Text(string)
    }
    
    var percentageSupplementaryContent: some View {
        Group {
            Text("of")
                .font(.title)
                .foregroundColor(Color(.quaternaryLabel))
            WeightSection()
//            Text("=")
//                .font(.title)
//                .foregroundColor(Color(.quaternaryLabel))
//            calculatedSection
        }
    }
    
    var formulaSupplementaryContent: some View {
        Group {
            Text("with")
                .font(.title)
                .foregroundColor(Color(.quaternaryLabel))
            BiologicalSexSection()
            WeightSection()
            HeightSection()
//            Text("=")
//                .font(.title)
//                .foregroundColor(Color(.quaternaryLabel))
//            calculatedSection
        }
    }
    
    @ViewBuilder
    var supplementaryContent: some View {
        switch model.lbmSource {
        case .fatPercentage:
            percentageSupplementaryContent
        case .formula:
            formulaSupplementaryContent
        default:
            EmptyView()
        }
    }
    
    var trailingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            if model.shouldShowSyncAllForLBMForm {
                Button {
                    model.tappedSyncAllOnLBMForm()
                } label: {
                    HStack {
                        appleHealthSymbol
                        Text("Sync All")
                    }
                }
            }
        }
    }
    var body: some View {
        FormStyledScrollView {
            infoSection
            FormStyledSection(footer: footer) {
                content
            }
            supplementaryContent
        }
        .scrollDismissesKeyboard(.interactively)
        .interactiveDismissDisabled(model.isEditing)
        .navigationTitle("Lean Body Mass")
        .toolbar { trailingContent }
        .onChange(of: model.lbmSource, perform: lbmSourceChanged)
    }
}
