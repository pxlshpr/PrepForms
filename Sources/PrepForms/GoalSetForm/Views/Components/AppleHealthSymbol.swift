import SwiftUI

let HealthBottomColorHex = "fc2e1d"
let HealthTopColorHex = "fe5fab"

let HealthTopColor = Color(hex: HealthTopColorHex)
let HealthBottomColor = Color(hex: HealthBottomColorHex)

let HealthGradient = LinearGradient(
    colors: [HealthTopColor, HealthBottomColor],
    startPoint: .top,
    endPoint: .bottom
)

var appleHealthSymbol: some View {
    Image(systemName: "heart.fill")
        .symbolRenderingMode(.palette)
        .foregroundStyle(HealthGradient)
}

var appleHealthBolt: some View {
    Image(systemName: "bolt.horizontal.fill")
        .symbolRenderingMode(.palette)
        .foregroundStyle(HealthGradient)
}
