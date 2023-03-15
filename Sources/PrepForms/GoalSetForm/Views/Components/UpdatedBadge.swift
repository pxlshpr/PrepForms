import SwiftUI

struct UpdatedBadge: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Text("Updated")
            .textCase(.uppercase)
            .font(.footnote)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        HealthGradient
                            .opacity(colorScheme == .dark ? 0.5 : 0.8)
                    )
            )
    }
}
