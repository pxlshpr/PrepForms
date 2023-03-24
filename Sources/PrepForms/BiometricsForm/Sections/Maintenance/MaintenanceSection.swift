import SwiftUI
import PrepDataTypes
import PrepCoreDataStack
import SwiftUISugar

struct MaintenanceSection: View {
    
    @Environment(\.colorScheme) var colorScheme
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
                            .foregroundColor(formCellBackgroundColor(colorScheme: colorScheme))
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
                Color.clear
                    .animatedMaintenanceEnergyModifier(value: value, energyUnit: unit)
                updatedBadge
            }
            .fixedSize(horizontal: true, vertical: false)
            .frame(maxWidth: .infinity, alignment: .center)
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
        }
        
        return Group {
            if let value = model.maintenanceEnergy {
                filled(value: value, unit: UserManager.energyUnit)
            } else {
                empty
            }
        }
        .frame(height: 60)
    }
}
