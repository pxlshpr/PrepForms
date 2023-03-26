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
        content
            .presentationDetents([collapsedDetent, .large], selection: $detent)
            .onChange(of: model.lbmSource, perform: lbmSourceChanged)
    }
    
    func lbmSourceChanged(newSource: LeanBodyMassSource?) {
        if newSource?.usesWeight == true {
            detent = .large
        }
    }
    
    var content: some View {
        NavigationView {
            FormStyledScrollView {
                infoSection
                leanBodyMassSection
                supplementaryContent
            }
            .navigationTitle("Lean Body Mass")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { leadingContent }
            .toolbar { trailingContent }
        }
    }
    
    var leadingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarLeading) {
            syncButton
        }
    }
    
    var trailingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
//            if isValid {
                doneButton
//            } else {
//                dismissButton
//            }
        }
    }
    
    var isValid: Bool {
        model.lbm != nil
    }

    @ViewBuilder
    var doneButton: some View {
        Button {
            Haptics.successFeedback()
            dismiss()
        } label: {
            Text("Done")
//                .fontWeight(.bold)
//                .foregroundColor(.white)
//                .frame(height: 32)
//                .padding(.horizontal, 8)
//                .background(
//                    RoundedRectangle(cornerRadius: 7, style: .continuous)
//                        .fill(Color.accentColor.gradient)
//                )
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
