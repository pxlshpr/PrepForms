import SwiftUI
import PrepDataTypes

struct MaintenanceSection: View {
    
    @EnvironmentObject var model: BiometricsModel
    @Namespace var namespace
    
    var body: some View {
        Group {
            VStack(spacing: 7) {
                content
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 0)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(Color(.secondarySystemGroupedBackground))
                    )
                    .padding(.bottom, 10)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
    }
    
    var content: some View {

        func filled(value: Double, unit: EnergyUnit) -> some View {
            HStack {
                MaintenanceEnergyView(
                    value: value,
                    unit: unit,
                    namespace: namespace
                )
                .fixedSize(horizontal: true, vertical: false)
                updatedBadge
            }
        }
        
        @ViewBuilder
        var updatedBadge: some View {
            if model.shouldShowUpdatedBadge(for: .restingEnergy)
                || model.shouldShowUpdatedBadge(for: .activeEnergy)
            {
                UpdatedBadge()
            }
        }

        var empty: some View {
            Text("Set your resting and active energies to determine this")
                .foregroundColor(Color(.tertiaryLabel))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
//                    .padding(.vertical)
        }
        
        return Group {
            if let value = model.maintenanceEnergy {
                filled(value: value, unit: model.userEnergyUnit)
            } else {
                empty
            }
        }
        .frame(height: 60)
    }
}
