import SwiftUI
import SwiftHaptics
import PrepDataTypes
import ActivityIndicatorView
import SwiftUISugar
import HealthKit
import PrepCoreDataStack

extension TDEEForm {
    
    var restingEnergySection: some View {
        RestingEnergySection()
            .environmentObject(model)
    }
}

//func label(_ label: String, _ valueString: String) -> some View {

//let HealthBottomColorHex = "fc2e1d"
//let HealthTopColorHex = "fe5fab"

//var appleHealthSymbol: some View {
//    Image(systemName: "heart.fill")
//        .symbolRenderingMode(.palette)
//        .foregroundStyle(
//            .linearGradient(
//                colors: [
//                    HealthTopColor,
//                    HealthBottomColor
//                ],
//                startPoint: .top,
//                endPoint: .bottom
//            )
//        )
//}

struct MeasurementLabel: View {
    @Environment(\.colorScheme) var colorScheme
    
    let label: String
    let valueString: String
    let useHealthAppData: Bool
    
    var body: some View {
        ButtonLabel(
            title: string,
            prefix: prefix,
            style: style,
            trailingSystemImage: systemImage,
            trailingImageScale: .small
        )
    }
    
    var systemImage: String? {
        useHealthAppData ? nil : "chevron.right"
    }
    
    var body_legacy: some View {
        PickerLabel(
            string,
            prefix: prefix,
            systemImage: systemImage,
            imageColor: imageColor,
            backgroundColor: backgroundColor,
            backgroundGradientTop: backgroundGradientTop,
            backgroundGradientBottom: backgroundGradientBottom,
            foregroundColor: foregroundColor,
            prefixColor: prefixColor,
            infiniteMaxHeight: false
        )
    }
    
    var style: ButtonLabel.Style {
        if useHealthAppData {
            return .health
        }
        return valueString.isEmpty ? .accent : .plain
    }
    
    var backgroundGradientTop: Color? {
        guard useHealthAppData else {
            return nil
        }
        return HealthTopColor
    }
    var backgroundGradientBottom: Color? {
        guard useHealthAppData else {
            return nil
        }
        return HealthBottomColor
    }

    var backgroundColor: Color {
        guard !valueString.isEmpty else {
            return .accentColor
        }
        let defaultColor = colorScheme == .light ? Color(hex: "e8e9ea") : Color(hex: "434447")
        return useHealthAppData ? Color(.systemGroupedBackground) : defaultColor
    }
    
    var foregroundColor: Color {
        guard !valueString.isEmpty else {
            return .white
        }
        if useHealthAppData {
            return Color.white
//            return Color(.secondaryLabel)
        } else {
            return Color.primary
        }
    }
    var prefixColor: Color {
        if useHealthAppData {
            return Color(hex: "F3DED7")
//            return Color(.secondaryLabel)
//            return Color(.tertiaryLabel)
        } else {
            return Color.secondary
        }
    }
    
    var string: String {
        valueString.isEmpty ? label : valueString
    }
    
    var prefix: String? {
        valueString.isEmpty ? nil : label
    }
    
    var imageColor: Color {
        valueString.isEmpty ? .white : Color(.tertiaryLabel)
    }
}

struct MeasurementLabel_Previews: PreviewProvider {
    static var previews: some View {
        FormStyledScrollView {
            FormStyledSection {
                MeasurementLabel(
                    label: "weight",
                    valueString: "93.55",
                    useHealthAppData: true
                )
            }
        }
    }
}

func emptyButton(_ string: String, systemImage: String? = nil, showHealthAppIcon: Bool = false, action: (() -> ())? = nil) -> some View {
    Button {
        action?()
    } label: {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage)
//                    .foregroundColor(.white)
                    .foregroundColor(.white.opacity(0.7))
            } else if showHealthAppIcon {
                appleHealthSymbol
            }
            Text(string)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(.white)
//                .foregroundColor(.secondary)
        }
        .frame(minHeight: 30)
        .padding(.horizontal, 15)
        .padding(.vertical, 5)
        .background (
            Capsule(style: .continuous)
                .foregroundColor(.accentColor)
//                .foregroundColor(Color(.secondarySystemFill))
        )
    }
}

var permissionRequiredContent: some View  {
    VStack {
        VStack(alignment: .center, spacing: 5) {
            Text("Health app integration requires permissions to be granted in:")
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(.secondary)
            Text("Settings → Privacy & Security → Health → Prep")
                .font(.footnote)
                .foregroundColor(Color(.tertiaryLabel))
        }
        .multilineTextAlignment(.center)
        Button {
            UIApplication.shared.open(URL(string: "App-prefs:Privacy&path=HEALTH")!)
        } label: {
            ButtonLabel(title: "Go to Settings", leadingSystemImage: "gear")
//            HStack {
//                Image(systemName: "gear")
//                Text("Go to Settings")
//                    .fixedSize(horizontal: true, vertical: false)
//            }
//            .foregroundColor(.white)
//            .padding(.horizontal)
//            .padding(.vertical, 12)
//            .background(
//                RoundedRectangle(cornerRadius: 20, style: .continuous)
//                    .foregroundColor(Color.accentColor)
//            )
        }
        .buttonStyle(.borderless)
        .padding(.top, 5)
    }
}
