import SwiftUI
import SwiftHaptics

struct BiometricButton: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    enum Style {
        case plain
        case health
    }
    
    let title: String
    let systemImage: String?
    let style: Style
    let action: () -> ()
    let isSecondary: Bool
    
    init(_ title: String, systemImage: String? = nil, isSecondary: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.isSecondary = isSecondary
        self.systemImage = systemImage
        self.style = .plain
        self.action = action
    }
    
    init(healthTitle title: String, isSecondary: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.isSecondary = isSecondary
        self.systemImage = nil
        self.style = .health
        self.action = action
    }

    var body: some View {
        Button {
            Haptics.feedback(style: .soft)
            action()
        } label: {
            label
        }
    }
    
    var label: some View {
        
        @ViewBuilder
        var image: some View {
            if style == .health {
                if isSecondary {
                    Image(systemName: "heart.fill")
                        .symbolRenderingMode(.palette)
//                        .foregroundColor(.green)
                        .foregroundStyle(HealthGradient)
                } else {
                    Image(systemName: "heart.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white)
                }
            } else if let systemImage {
                Image(systemName: systemImage)
                    .imageScale(.large)
                    .fontWeight(.medium)
            }
        }
        
        var textColor: Color {
            guard isSecondary else {
                return .white
            }
            return style == .plain
            ? .accentColor
            : HealthTopColor
//            : .green
        }
        
        var background: some View {
            
            var healthGradient: LinearGradient {
                HealthGradient
            }

            var healthColor: Color {
//                .green
                HealthTopColor
            }

            var shape: some Shape {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
            }
            
            var secondaryOpacity: CGFloat {
                colorScheme == .dark ? 0.1 : 0.15
            }
            
            return Group {
                if isSecondary {
                    switch style {
                    case .health:
                        shape
                            .fill(healthColor.opacity(secondaryOpacity))
                    case .plain:
                        shape
                            .fill(Color.accentColor.opacity(secondaryOpacity))
                    }
                } else {
                    switch style {
                    case .health:
                        shape
                            .fill(healthGradient)
//                            .fill(.green)
                    case .plain:
                        shape
                            .fill(Color.accentColor.gradient)
                    }
                }
            }
        }
        
        return VStack(spacing: 5) {
            image
            Text(title)
                .fontWeight(.bold)
        }
        .foregroundColor(textColor)
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(background)
    }
}
