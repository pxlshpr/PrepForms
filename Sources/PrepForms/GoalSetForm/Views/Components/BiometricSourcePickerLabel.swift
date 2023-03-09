import SwiftUI
import PrepDataTypes

struct BiometricSourcePickerLabel: View {
    
    let source: BiometricSource
    
    var body: some View {
        ButtonLabel(
            title: source.menuDescription,
            style: source.isHealthSynced ? .healthPlain : .plain,
            isCompact: true,
            leadingSystemImage: source.isHealthSynced ? nil : source.systemImage,
            leadingImageScale: .medium,
            trailingSystemImage: "chevron.up.chevron.down",
            trailingImageScale: .small
        )
    }
}
