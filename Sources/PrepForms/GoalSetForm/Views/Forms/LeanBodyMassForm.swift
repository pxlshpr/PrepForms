import SwiftUI
import SwiftHaptics
import PrepDataTypes
import ActivityIndicatorView
import SwiftUISugar

struct LeanBodyMassForm: View {
    
    @EnvironmentObject var model: BiometricsModel
    
    var body: some View {
        FormStyledScrollView {
            infoSection
            LeanBodyMassSection(includeHeader: false, footerString: footerStringBinding)
                .environmentObject(model)
            supplementaryContent
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Lean Body Mass")
        .toolbar { trailingContent }
    }
    
    var infoSection: some View {
        FormStyledSection {
            Text("Lean body mass is the weight of your body minus your body fat (adipose tissue).")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    var footerStringBinding: Binding<String> {
        Binding<String>(
            get: {
                switch model.lbmSource {
                case .userEntered:
                    return "You will need to ensure your lean body mass is kept up to date for an accurate calculation."
                case .health:
                    return "Your lean body mass will be kept in sync with the Health App."
                case .formula:
                    return "Use a formula to calculate your lean body mass."
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
            BiologicalSexSection(includeFooter: true)
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
                    ButtonLabel(title: "Sync All", style: .health, isCompact: true)
//                    AppleHealthButtonLabel(title: "Sync All", isCompact: true)
                }
            }
        }
    }
}
