import SwiftUI
import PrepDataTypes

struct AnimatableMaintenanceEnergyModifier: AnimatableModifier {
    
    @Environment(\.colorScheme) var colorScheme
    @State var size: CGSize = .zero

    var value: Double
    var energyUnit: EnergyUnit
    
    var animatableData: Double {
        get { value }
        set { value = newValue }
    }
    
    func body(content: Content) -> some View {
        content
            .frame(width: size.width, height: size.height)
            .overlay(
                animatedLabel
                    .readSize { size in
                        self.size = size
                    }
            )
    }
    
    var animatedLabel: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(value.formattedEnergy)
                .fixedSize(horizontal: true, vertical: false)
                .font(.system(.largeTitle, design: .rounded, weight: .semibold))
                .foregroundColor(.primary)
            Text(energyUnit.shortDescription)
                .foregroundColor(.secondary)
                .font(.system(.body, design: .rounded, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.trailing)
        .fixedSize(horizontal: true, vertical: false)
    }
}

public extension View {
    func animatedMaintenanceEnergyModifier(value: Double, energyUnit: EnergyUnit) -> some View {
        modifier(AnimatableMaintenanceEnergyModifier(value: value, energyUnit: energyUnit))
    }
}
