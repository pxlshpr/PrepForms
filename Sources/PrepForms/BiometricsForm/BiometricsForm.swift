import SwiftUI
import SwiftUISugar
import PrepDataTypes
import PrepCoreDataStack
import SwiftHaptics

public struct BiometricsForm: View {
    
    @StateObject var model: BiometricsModel
    
    @Namespace var namespace
    @Environment(\.colorScheme) var colorScheme
    
    public init() {
        let user = DataManager.shared.user
        let biometrics = user?.biometrics
        let units = user?.options.units ?? .defaultUnits
        let model = BiometricsModel(existingProfile: biometrics, userUnits: units)
        _model = StateObject(wrappedValue: model)
    }
    
    public var body: some View {
        NavigationView {
            content
                .navigationTitle("Biometrics")
        }
    }
    
    var content: some View {
        FormStyledScrollView {
            infoSection
            maintenanceEnergySection
            weightSection
            leanBodyMassSection
            heightSection
            biologicalSexSection
            ageSection
        }
    }
    
    var infoText: some View {
        let energyUnit = UserManager.energyUnit
        let energyDescription = energyUnit == .kcal ? "Calories" : "Energy"
        return Text("These are used to calculate and create goals based on your **Maintenance \(energyDescription)**, which is an estimate of how much you would have to consume to *maintain* your current weight.")
    }
    
    var infoSection: some View {
        infoText
            .multilineTextAlignment(.leading)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 30)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .foregroundColor(
                        Color(.quaternarySystemFill)
                            .opacity(colorScheme == .dark ? 0.5 : 1)
                    )
            )
            .cornerRadius(10)
            .padding(.bottom, 10)
            .padding(.horizontal, 17)
    }
    
    var maintenanceEnergySection: some View {
        TDEESection(includeHeader: true, largeTitle: true)
            .environmentObject(model)
    }
    
    var weightSection: some View {
        WeightSection(largeTitle: true)
            .environmentObject(model)
    }

    var heightSection: some View {
        HeightSection(largeTitle: true)
            .environmentObject(model)
    }

    var biologicalSexSection: some View {
        BiologicalSexSection(largeTitle: true)
            .environmentObject(model)
    }
    
    var ageSection: some View {
        AgeSection(largeTitle: true)
            .environmentObject(model)
    }
    
    var leanBodyMassSection: some View {
        LeanBodyMassSection(largeTitle: true)
            .environmentObject(model)
    }

}

struct BiometricPickerLabel: View {
    
    let title: String
    
    init(_ title: String) {
        self.title = title
    }
    
    var body: some View {
        ButtonLabel(
            title: title,
            style: .plain,
            trailingSystemImage: "chevron.up.chevron.down",
            trailingImageScale: .small
        )
    }
}

struct BiometricSourcePickerLabel: View {
    let source: BiometricSource
    
    var body: some View {
        ButtonLabel(
            title: source.menuDescription,
            style: source.isHealthSynced ? .plainHealth : .plain,
            isCompact: true,
            leadingSystemImage: source.isHealthSynced ? nil : source.systemImage,
            leadingImageScale: .medium,
            trailingSystemImage: "chevron.up.chevron.down",
            trailingImageScale: .small
        )
    }
}
struct ButtonLabel: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Namespace var localNamespace
    
    enum Style {
        case plain
        case accent
        case health
        case plainHealth
    }

    let style: Style
    let isCompact: Bool
    let title: String
    let prefix: String?
    let leadingSystemImage: String?
    let leadingImageScale: Image.Scale
    let trailingSystemImage: String?
    let trailingImageScale: Image.Scale

    let namespace: Namespace.ID?
    let titleMatchedGeometryId: String
    let imageMatchedGeometryId: String
    
    init(
        title: String,
        prefix: String? = nil,
        style: Style = .accent,
        isCompact: Bool = false,
        leadingSystemImage: String? = nil,
        leadingImageScale: Image.Scale = .medium,
        trailingSystemImage: String? = nil,
        trailingImageScale: Image.Scale = .medium,
        namespace: Namespace.ID? = nil,
        titleMatchedGeometryId: String? = nil,
        imageMatchedGeometryId: String? = nil
    ) {
        self.style = style
        self.isCompact = isCompact
        self.leadingSystemImage = leadingSystemImage
        self.leadingImageScale = leadingImageScale
        self.trailingSystemImage = trailingSystemImage
        self.trailingImageScale = trailingImageScale
        self.title = title
        self.prefix = prefix
        self.namespace = namespace
        self.titleMatchedGeometryId = titleMatchedGeometryId ?? UUID().uuidString
        self.imageMatchedGeometryId = imageMatchedGeometryId ?? UUID().uuidString
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
    }
    
    @ViewBuilder
    var optionalLeadingImage: some View {
        if let leadingSystemImage {
            Image(systemName: leadingSystemImage)
                .imageScale(leadingImageScale)
                .foregroundColor(foregroundColor)
                .matchedGeometryEffect(id: imageMatchedGeometryId, in: namespace ?? localNamespace)
        } else if style == .health || style == .plainHealth {
            appleHealthSymbol
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
        case .plain, .plainHealth:
            return .secondary
        case .health:
            return HealthTopColor
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
                .matchedGeometryEffect(id: titleMatchedGeometryId, in: namespace ?? localNamespace)
        }
        .foregroundColor(foregroundColor)
    }
    
    var background: some View {

        var backgroundShapeStyle: some ShapeStyle {
            
            var topColor: Color {
                switch style {
                case .plain, .plainHealth:
                    return Color(.secondaryLabel)
                case .health:
                    return HealthTopColor
                case .accent:
                    return Color.accentColor
                }
            }
            
            var bottomColor: Color {
                switch style {
                case .plain, .plainHealth:
                    return Color(.secondaryLabel)
                case .health:
                    return HealthBottomColor
                case .accent:
                    return Color.accentColor
                }
            }
            
            return LinearGradient.linearGradient(
                colors: [topColor, bottomColor],
                startPoint: .top, endPoint: .bottom
            )
        }
        
        return RoundedRectangle(cornerRadius: 7, style: .continuous)
            .fill(
                backgroundShapeStyle
                    .opacity(colorScheme == .dark ? 0.1 : 0.15)
            )
    }
}

//TODO: Use ButtonLabel instead of this
struct AppleHealthButtonLabel: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    let title: String
    let isCompact: Bool
    
    init(title: String, isCompact: Bool = false) {
        self.title = title
        self.isCompact = isCompact
    }
    
    var body: some View {
        ButtonLabel(title: title, style: .health, isCompact: isCompact)
    }
    
    var body_legacy: some View {
        HStack(spacing: hSpacing) {
            appleHealthSymbol
            Text(title)
                .fontWeight(.bold)
        }
        .font(font)
        .foregroundColor(HealthTopColor)
        .padding(.horizontal, hPadding)
        .padding(.vertical, vPadding)
        .background(background)
    }
    
    var background: some View {
        RoundedRectangle(cornerRadius: 7, style: .continuous)
            .fill(
                .linearGradient(
                    colors: [
                        HealthTopColor,
                        HealthBottomColor
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
//                HealthTopColor
                .opacity(colorScheme == .dark ? 0.1 : 0.15)
            )
//            .fill(Color.accentColor.opacity(colorScheme == .dark ? 0.1 : 0.15))
    }
    
    var hSpacing: CGFloat {
        isCompact ? 2 : 3
    }

    var hPadding: CGFloat {
        isCompact ? 8 : 10
    }
    
    var vPadding: CGFloat {
        isCompact ? 8 : 12
    }

    var font: Font {
        isCompact ? .footnote : .body
    }
}
