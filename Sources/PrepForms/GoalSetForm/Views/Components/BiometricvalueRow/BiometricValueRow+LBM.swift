import SwiftUI
import SwiftUISugar
import PrepDataTypes
import PrepCoreDataStack
import SwiftHaptics
import ActivityIndicatorView

extension BiometricValueRow {
        
    var isFatPercentage: Bool {
        self.type == .leanBodyMass && source.isUserEnteredAndComputed
    }

    @ViewBuilder
    var optionalSecondaryRow: some View {
        if source.isUserEnteredAndComputed {
            HStack {
                Spacer()
                button
            }
        }
    }

    @ViewBuilder
    var computedLeanBodyMassTexts: some View {
        if let computedValue {
            HStack {
                if let prefix {
                    Text(prefix)
                        .font(.subheadline)
                        .foregroundColor(Color(.tertiaryLabel))
                }
                if let computedValue = computedValue.wrappedValue {
                    Color.clear
                        .animatedBiometricsValueModifier(
                            value: computedValue,
                            type: type,
                            textColor: .secondary
                        )
                } else {
                    EmptyView()
//                    Text("0 kg")
//                        .font(font)
//                        .redacted(reason: .placeholder)
//                        .multilineTextAlignment(.trailing)
//                        .foregroundColor(.secondary)
//                        .opacity(0.5)
//                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
    
}
