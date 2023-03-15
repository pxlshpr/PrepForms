import SwiftUI
import SwiftUISugar
import PrepDataTypes
import PrepCoreDataStack
import SwiftHaptics
import ActivityIndicatorView

struct AnimatableBiometricsValueModifier: AnimatableModifier {
    
    @Environment(\.colorScheme) var colorScheme
    @State var size: CGSize = .zero
    
    var value: BiometricValue
    let type: BiometricType
    let textColor: Color
    
    var animatableData: Double {
        get { value.double ?? 0 }
        set { value.double = newValue }
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
    
    var valueString: String {
        value.valueDescription
    }
    
    var secondaryValueString: String? {
        value.secondaryValueDescription
    }
    
    var secondaryUnitString: String? {
        value.secondaryUnitDescription
    }
    
    var animatedLabel: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Text(valueString)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundColor(textColor)

            if let unit = value.unitDescription {
                Text(unit)
                    .foregroundColor(textColor)
                    .font(.system(.body, design: .rounded, weight: .regular))
            }
            if let secondaryValueString, let secondaryUnitString {
                Text(secondaryValueString)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundColor(textColor)
                Text(secondaryUnitString)
                    .foregroundColor(textColor)
                    .font(.system(.body, design: .rounded, weight: .regular))
            }
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.trailing)
        .fixedSize(horizontal: true, vertical: false)
    }
}

extension View {
    func animatedBiometricsValueModifier(
        value: BiometricValue,
        type: BiometricType,
        textColor: Color
    ) -> some View {
        modifier(AnimatableBiometricsValueModifier(
            value: value,
            type: type,
            textColor: textColor
        ))
    }
}
