import SwiftUI
import SwiftUISugar
import PrepDataTypes
import PrepCoreDataStack
import SwiftHaptics

public struct BiometricsForm: View {
    
    @Namespace var namespace
    
    @StateObject var model: BiometricsModel
    
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
            titleCell("Maintenance Energy")
                .padding(.horizontal, 20)
            maintenanceEnergySection
            weightSection
            heightSection
            biologicalSexSection
            ageSection
        }
    }
    
    func titleCell(_ title: String) -> some View {
        Group {
            Spacer().frame(height: 15)
            HStack {
                Spacer().frame(width: 3)
                Text(title)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.primary)
                Spacer()
            }
            Spacer().frame(height: 7)
        }
    }

    var maintenanceEnergySection: some View {
        TDEESection(
            namespace: namespace,
            action: {}
        )
        .environmentObject(model)
    }
    
    var weightSection: some View {
        WeightSection(includeHeader: true)
            .environmentObject(model)
    }

    var heightSection: some View {
        HeightSection()
            .environmentObject(model)
    }

    var biologicalSexSection: some View {
        BiologicalSexSection()
            .environmentObject(model)
    }
    
    var ageSection: some View {
        AgeSection()
            .environmentObject(model)
    }

}

import ActivityIndicatorView

struct BiometricValueRow: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    struct Params {
        
        //TODO: Give in a BiometricValue and BiometricType here instead
        
        let valueString: String
        let unitString: String
        let prefix: String?
        let fetchStatus: HealthKitFetchStatus
        let isRedacted: Bool
        let isUserEntered: Bool
    }
    
    @Binding var params: Params
    @State var showingForm: Bool
    
    let matchedGeometryId: String?
    let matchedGeometryNamespace: Namespace.ID?
    
    init(
        params: Binding<Params>,
        matchedGeometryId: String? = nil,
        matchedGeometryNamespace: Namespace.ID? = nil
    ) {
        _params = params
        self.matchedGeometryId = matchedGeometryId
        self.matchedGeometryNamespace = matchedGeometryNamespace
        print("Initializing BiometricValueRow with isUserEntered: \(params.wrappedValue.isUserEntered)")
        _showingForm = State(initialValue: params.wrappedValue.isUserEntered)
    }
    
    enum Style {
        case calculated
        case userEntered
    }
    
    var body: some View {
        HStack {
            Spacer()
            content
        }
        .sheet(isPresented: $showingForm) { form }
    }
    
    var form: some View {
        func handleNewValue(_ value: BiometricValue?) {
            
        }
        
        return BiometricValueForm(
            type: .activeEnergy,
            initialValue: nil,
            handleNewValue: handleNewValue
        )
    }
    
    @ViewBuilder
    var content: some View {
        if params.isUserEntered {
            valueTexts
        } else {
            switch params.fetchStatus {
            case .fetching, .notFetched:
                ActivityIndicatorView(isVisible: .constant(true), type: .opacityDots())
                    .frame(width: 25, height: 25)
                    .foregroundColor(.secondary)
            case .fetched:
                valueTexts
            case .noData, .noDataOrNotAuthorized:
                Text("no data")
                    .font(font)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    var valueTexts: some View {
        if params.isUserEntered {
            button
        } else {
            texts
        }
    }

    var valueString: String {
        if params.valueString.isEmpty {
            if params.isUserEntered {
                return "required"
            } else {
                return "0"
            }
        } else {
            return params.valueString
        }
    }
    
    var unitString: String? {
        if params.valueString.isEmpty, params.isUserEntered {
            return nil
        } else {
            return params.unitString
        }
    }
    
    var font: Font {
        var fontWeight: Font.Weight {
            if params.isUserEntered, params.valueString.isEmpty {
                return .thin
            } else {
                return .semibold
            }
        }
        return .system(.title3, design: .rounded, weight: .semibold)
    }
    
    var textColor: Color {
        if params.isUserEntered {
            return .accentColor
        } else {
            return .secondary
        }
    }
    
    var texts: some View {
        HStack {
            if let prefix = params.prefix {
                Text(prefix)
                    .font(.subheadline)
                    .foregroundColor(Color(.tertiaryLabel))
            }
            Text(valueString)
                .font(font)
                .multilineTextAlignment(.trailing)
                .foregroundColor(textColor)
                .fixedSize(horizontal: false, vertical: true)
                .if(matchedGeometryId != nil && matchedGeometryNamespace != nil) {
                    $0.matchedGeometryEffect(
                        id: matchedGeometryId!,
                        in: matchedGeometryNamespace!
                    )
                }
                .if(params.isRedacted && !params.isUserEntered) { view in
                    view
                        .redacted(reason: .placeholder)
                }
            if let unitString {
                Text(unitString)
                    .foregroundColor(textColor)
            }
        }
    }
    
    var button: some View {
        Button {
            Haptics.feedback(style: .soft)
            showingForm = true
        } label: {
            texts
                .padding(.vertical, 8)
                .padding(.horizontal, 15)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(
                            Color.accentColor
                                .opacity(colorScheme == .dark ? 0.1 : 0.15)
                        )
                )

        }
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
            style: source.fromHealthApp ? .plainHealth : .plain,
            isCompact: true,
            leadingSystemImage: source.fromHealthApp ? nil : source.systemImage,
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
            return Color(hex: AppleHealthTopColorHex)
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
                    return Color(hex: AppleHealthTopColorHex)
                case .accent:
                    return Color.accentColor
                }
            }
            
            var bottomColor: Color {
                switch style {
                case .plain, .plainHealth:
                    return Color(.secondaryLabel)
                case .health:
                    return Color(hex: AppleHealthBottomColorHex)
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
        .foregroundColor(Color(hex: AppleHealthTopColorHex))
        .padding(.horizontal, hPadding)
        .padding(.vertical, vPadding)
        .background(background)
    }
    
    var background: some View {
        RoundedRectangle(cornerRadius: 7, style: .continuous)
            .fill(
                .linearGradient(
                    colors: [
                        Color(hex: AppleHealthTopColorHex),
                        Color(hex: AppleHealthBottomColorHex)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
//                Color(hex: AppleHealthTopColorHex)
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

struct TDEESection: View {
    
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var model: BiometricsModel
    
    let namespace: Namespace.ID
    let action: () -> ()
    
    var body: some View {
        emptyContent
    }
    
    var emptyContent: some View {
        var setupButton: some View {
            var label: some View {
                ButtonLabel(
                    title: "Setup Maintenance \(UserManager.energyDescription)",
                    leadingSystemImage: "flame.fill",
                    namespace: namespace,
                    titleMatchedGeometryId: "maintenance-header-title",
                    imageMatchedGeometryId: "maintenance-header-icon"
                )
            }
            
            return Button {
                action()
            } label: {
                label
            }
        }
        
        return VStack {
            model.tdeeDescriptionText
                .matchedGeometryEffect(id: "maintenance-footer", in: namespace)
                .multilineTextAlignment(.leading)
                .foregroundColor(Color(.secondaryLabel))
            if model.shouldShowInitialSetupButton {
                setupButton
                .buttonStyle(.borderless)
                .padding(.top, 5)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .foregroundColor(Color(.quaternarySystemFill))
        )
        .cornerRadius(10)
        .padding(.bottom, 10)
        .padding(.horizontal, 17)
    }
}
