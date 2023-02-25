import SwiftUI
import SwiftHaptics

extension TDEEForm {
    
    var healthSection: some View {
        var header: some View {
            HStack {
                appleHealthSymbol
                Text("Apple Health")
            }
        }
        
        @ViewBuilder
        var footer: some View {
            VStack(alignment: .leading, spacing: 5) {
                Group {
                    switch healthEnergyPeriod {
                    case .previousDay:
                        Text("Your maintenance energy will always be the energy your resting + active energy from the previous day. This will update daily.")
                    case .average:
                        Text("Your maintenance energy will always be the daily average of your resting + active energy from the past week. This will update daily.")
                    }
                }

                Button {
                    Haptics.feedback(style: .soft)
                    showingAdaptiveCorrectionInfo = true
                } label: {
                    Label("Learn More", systemImage: "info.circle")
                        .font(.footnote)
                }
            }
        }
        

        return Section(header: header, footer: footer) {
//            activeEnergyHealthAppPeriodLink
//            calculatedRestingEnergyField
//            healthActiveEnergyField
        }
    }
}
