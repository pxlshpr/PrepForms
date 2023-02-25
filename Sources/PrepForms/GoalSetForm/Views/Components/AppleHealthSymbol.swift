import SwiftUI

let AppleHealthBottomColorHex = "fc2e1d"
let AppleHealthTopColorHex = "fe5fab"

//TODO: Modularize the linear gradient in both of these
var appleHealthSymbol: some View {
    Image(systemName: "heart.fill")
        .symbolRenderingMode(.palette)
        .foregroundStyle(
            .linearGradient(
                colors: [
                    Color(hex: AppleHealthTopColorHex),
                    Color(hex: AppleHealthBottomColorHex)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
}

var appleHealthBolt: some View {
    Image(systemName: "bolt.horizontal.fill")
        .symbolRenderingMode(.palette)
        .foregroundStyle(
            .linearGradient(
                colors: [
                    Color(hex: AppleHealthTopColorHex),
                    Color(hex: AppleHealthBottomColorHex)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
}
