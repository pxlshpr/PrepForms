import SwiftUI

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
        "chevron.right"
//        useHealthAppData ? nil : "chevron.right"
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
