import SwiftUI

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
