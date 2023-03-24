import SwiftUI
import SwiftUISugar

let HealthBottomColorHex = "fc2e1d"
let HealthTopColorHex = "fe5fab"

let HealthTopColor = Color(hex: HealthTopColorHex)
let HealthBottomColor = Color(hex: HealthBottomColorHex)

let HealthGradient = LinearGradient(
    colors: [HealthTopColor, HealthBottomColor],
    startPoint: .top,
    endPoint: .bottom
)

let HealthGradientHorizontal = LinearGradient(
    colors: [HealthTopColor, HealthBottomColor],
    startPoint: .leading,
    endPoint: .trailing
)

let HealthToastStyle = ToastStyle(
    imageTopColor: HealthTopColor,
    imageBottomColor: HealthBottomColor,
    titleTopColor: HealthBottomColor,
    titleBottomColor: HealthTopColor
)

var HealthUpdatedToast: ToastInfo {
    ToastInfo(
        title: "Biometrics Updated",
        message: "You biometric data and goals have been updated.",
        style: HealthToastStyle,
        systemImage: "heart.fill"
    )
}

var appleHealthSymbol: some View {
    Image(systemName: "heart.fill")
        .symbolRenderingMode(.palette)
        .foregroundStyle(HealthGradient)
}

var appleHealthBolt: some View {
    Image(systemName: "heart.fill")
        .symbolRenderingMode(.palette)
        .foregroundStyle(HealthGradient)
//    Image(systemName: "bolt.horizontal.fill")
//        .symbolRenderingMode(.palette)
////        .foregroundStyle(HealthGradient)
////        .foregroundStyle(HealthGradientHorizontal)
////        .foregroundStyle(HealthTopColor)
////        .foregroundStyle(.green)
//        .foregroundStyle(.green.gradient)
}
