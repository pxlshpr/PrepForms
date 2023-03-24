import SwiftUI
import SwiftHaptics
import PrepDataTypes
import ActivityIndicatorView
import SwiftUISugar

let collapsedDetent: PresentationDetent = .height(400)

struct LeanBodyMassForm: View {
    
    @Environment(\.dismiss) var dismiss
    @ObservedObject var model: BiometricsModel
    @State var detent: PresentationDetent

    init(_ model: BiometricsModel) {
        self.model = model
        let detent = model.lbmSource?.usesWeight == true ? .large : collapsedDetent
        _detent = State(initialValue: detent)
    }
    
    var body: some View {
        quickForm
            .presentationDetents([collapsedDetent, .large], selection: $detent)
            .onChange(of: model.lbmSource, perform: lbmSourceChanged)
    }
    
    func lbmSourceChanged(newSource: LeanBodyMassSource?) {
        if newSource?.usesWeight == true {
            detent = .large
        }
    }
    
    var quickForm: some View {
        NavigationView {
//        QuickForm(title: "Lean Body Mass") {
            FormStyledScrollView {
                infoSection
                leanBodyMassSection
                supplementaryContent
            }
            .navigationTitle("Lean Body Mass")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { trailingContent }
        }
    }
    
    var trailingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            HStack(spacing: 0) {
                syncButton
                dismissButton
            }
        }
    }

    var dismissButton: some View {
        Button {
            Haptics.feedback(style: .soft)
            dismiss()
        } label: {
            CloseButtonLabel()
        }
    }

    var infoSection: some View {
        FormStyledSection {
            Text("Lean body mass is the weight of your body minus your body fat (adipose tissue).")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    var leanBodyMassSection: some View {
        LeanBodyMassSection(
            includeHeader: false,
            footerString: footerStringBinding
        )
        .environmentObject(model)
    }
    
    var footerStringBinding: Binding<String> {
        Binding<String>(
            get: {
                switch model.lbmSource {
                case .userEntered:
                    return "You will need to ensure your lean body mass is kept up to date for an accurate calculation."
                case .health:
                    return "Your lean body mass will be kept in sync with the Health App."
                case .equation:
                    return "Use an equation to calculate your lean body mass."
                case .fatPercentage:
                    return "Enter your fat percentage to calculate your lean body mass."
                default:
                    return "Choose how you want to enter your lean body mass."
                }
            },
            set: { _ in }
        )
    }
    
    var percentageSupplementaryContent: some View {
        Group {
            Text("of")
                .font(.title)
                .foregroundColor(Color(.quaternaryLabel))
            WeightSection()
                .environmentObject(model)
        }
    }
    
    var equationSupplementaryContent: some View {
        Group {
            Text("with")
                .font(.title)
                .foregroundColor(Color(.quaternaryLabel))
            BiologicalSexSection(includeFooter: true)
                .environmentObject(model)
            WeightSection()
                .environmentObject(model)
            HeightSection()
                .environmentObject(model)
        }
    }
    
    @ViewBuilder
    var supplementaryContent: some View {
        switch model.lbmSource {
        case .fatPercentage:
            percentageSupplementaryContent
        case .equation:
            equationSupplementaryContent
        default:
            EmptyView()
        }
    }
    
    @ViewBuilder
    var syncButton: some View {
        if model.shouldShowSyncAllForLBMForm {
            Button {
                model.tappedSyncAllOnLBMForm()
            } label: {
                ButtonLabel(title: "Sync All", style: .health, isCompact: true)
            }
        }
    }
}
