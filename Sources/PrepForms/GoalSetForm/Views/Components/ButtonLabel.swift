import SwiftUI

struct ButtonLabel: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    enum Style {
        case plain
        case healthPlain
        case healthAccented
        case accent
        case health
    }

    let style: Style
    let isCompact: Bool
    let title: String
    let prefix: String?
    let leadingSystemImage: String?
    let leadingImageScale: Image.Scale
    let trailingSystemImage: String?
    let trailingImageScale: Image.Scale

    init(
        title: String,
        prefix: String? = nil,
        style: Style = .accent,
        isCompact: Bool = false,
        leadingSystemImage: String? = nil,
        leadingImageScale: Image.Scale = .medium,
        trailingSystemImage: String? = nil,
        trailingImageScale: Image.Scale = .medium
    ) {
        self.style = style
        self.isCompact = isCompact
        self.leadingSystemImage = leadingSystemImage
        self.leadingImageScale = leadingImageScale
        self.trailingSystemImage = trailingSystemImage
        self.trailingImageScale = trailingImageScale
        self.title = title
        self.prefix = prefix
    }
    
    var body: some View {
        HStack {
            optionalLeadingImage
            titleStack
            optionalTrailingImage
        }
        .font(font)
        .padding(.horizontal, hPadding)
        .padding(.vertical, vPadding)
        .background(background)
        .fixedSize(horizontal: true, vertical: false)
        .animation(.none, value: style)
    }

    @ViewBuilder
    var optionalLeadingImage: some View {
        if let leadingSystemImage {
            Image(systemName: leadingSystemImage)
                .imageScale(leadingImageScale)
                .foregroundColor(foregroundColor)
//        } else if style == .health || style == .healthPlain {
        } else if style == .healthPlain {
            Image(systemName: "heart.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(HealthGradient)
        } else if style == .healthAccented {
            Image(systemName: "heart.fill")
                .foregroundColor(foregroundColor)
        }
    }
    
    
    @ViewBuilder
    var optionalTrailingImage: some View {
        if let trailingSystemImage {
            Image(systemName: trailingSystemImage)
                .imageScale(trailingImageScale)
                .foregroundColor(foregroundColor)
        }
    }
    
    var foregroundColor: Color {
        switch style {
        case .accent:
            return .accentColor
        case .plain, .healthPlain:
            return .secondary
        case .healthAccented:
            return .white.opacity(0.9)
        case .health:
            return .green
//            return HealthTopColor
        }
    }
    
    var hSpacing: CGFloat {
        isCompact ? 2 : 3
    }

    var hPadding: CGFloat {
        isCompact ? 8 : 15
    }
    
    var vPadding: CGFloat {
        isCompact ? 8 : 12
    }

    var font: Font {
        isCompact ? .footnote : .body
    }

    var titleStack: some View {
        HStack(spacing: 5) {
            if let prefix {
                Text(prefix)
            }
            Text(title)
                .fontWeight(.bold)
        }
        .foregroundColor(foregroundColor)
    }
    
    var background: some View {

        var backgroundShapeStyle: some ShapeStyle {
            
            var topColor: Color {
                switch style {
                case .plain, .healthPlain:
                    return Color(.secondaryLabel)
                case .health, .healthAccented:
                    return .green
//                    return HealthTopColor
                case .accent:
                    return Color.accentColor
                }
            }
            
            var bottomColor: Color {
                switch style {
                case .plain, .healthPlain:
                    return Color(.secondaryLabel)
                case .health, .healthAccented:
                    return .green
//                    return HealthBottomColor
                case .accent:
                    return Color.accentColor
                }
            }
            
            return LinearGradient.linearGradient(
                colors: [topColor, bottomColor],
                startPoint: .top, endPoint: .bottom
            )
        }
        
        var opacity: CGFloat {
            switch style {
            case .healthAccented:
                return 1
            default:
                return colorScheme == .dark ? 0.1 : 0.15
            }
        }
        
        return RoundedRectangle(cornerRadius: 7, style: .continuous)
            .fill(
                backgroundShapeStyle
                    .opacity(opacity)
            )
    }
}
