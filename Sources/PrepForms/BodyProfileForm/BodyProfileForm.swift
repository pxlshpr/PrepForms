import SwiftUI
import SwiftUISugar
import PrepDataTypes
import PrepCoreDataStack

public struct BodyProfileForm: View {
    
    @Namespace var namespace
    
    @StateObject var model: BodyProfileModel
    
    public init() {
        let user = DataManager.shared.user
        let bodyProfile = user?.bodyProfile
        let units = user?.options.units ?? .defaultUnits
        let model = BodyProfileModel(existingProfile: bodyProfile, userUnits: units)
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

struct ButtonLabel: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Namespace var localNamespace
    
    let title: String
    let systemImage: String?
    
    let namespace: Namespace.ID?
    let titleMatchedGeometryId: String
    let imageMatchedGeometryId: String

    init(
        title: String,
        systemImage: String? = nil,
        namespace: Namespace.ID? = nil,
        titleMatchedGeometryId: String? = nil,
        imageMatchedGeometryId: String? = nil
    ) {
        self.systemImage = systemImage
        self.title = title
        self.namespace = namespace
        self.titleMatchedGeometryId = titleMatchedGeometryId ?? UUID().uuidString
        self.imageMatchedGeometryId = imageMatchedGeometryId ?? UUID().uuidString
    }
    
    var body: some View {
        HStack {
            if let systemImage {
                Image(systemName: systemImage)
                    .matchedGeometryEffect(id: imageMatchedGeometryId, in: namespace ?? localNamespace)
            }
            Text(title)
                .fontWeight(.bold)
                .matchedGeometryEffect(id: titleMatchedGeometryId, in: namespace ?? localNamespace)
        }
        .foregroundColor(.accentColor)
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(
                    Color.accentColor
//                    Color.accentColor.gradient
                        .opacity(colorScheme == .dark ? 0.1 : 0.15))
        )
    }
}

struct AppleHealthButtonLabel: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    let title: String
    let forNavigationBar: Bool
    
    init(title: String, forNavigationBar: Bool = false) {
        self.title = title
        self.forNavigationBar = forNavigationBar
    }
    
    var body: some View {
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
        forNavigationBar ? 2 : 3
    }

    var hPadding: CGFloat {
        forNavigationBar ? 8 : 10
    }
    
    var vPadding: CGFloat {
        forNavigationBar ? 8 : 12
    }

    var font: Font {
        forNavigationBar ? .footnote : .body
    }
}

struct TDEESection: View {
    
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var model: BodyProfileModel
    
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
                    systemImage: "flame.fill",
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
