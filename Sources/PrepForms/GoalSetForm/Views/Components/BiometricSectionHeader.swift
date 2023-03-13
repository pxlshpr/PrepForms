import SwiftUI
import PrepDataTypes

struct BiometricSectionHeader: View {
    
    @EnvironmentObject var model: BiometricsModel
    let type: BiometricType
    
    var body: some View {
        HStack {
            symbol
            Text(type.description)
            updatedBadge
            Spacer()
            syncedSymbol
        }
        .textCase(.uppercase)
        .fixedSize(horizontal: false, vertical: true)
        .foregroundColor(Color(.secondaryLabel))
        .font(.footnote)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    var symbol: some View {
        if let image = type.systemImage {
            Image(systemName: image)
        }
    }
    
    @ViewBuilder
    var updatedBadge: some View {
        if model.shouldShowUpdatedBadge(for: type) {
            UpdatedBadge()
        }
    }
    
    @ViewBuilder
    var syncedSymbol: some View {
        if model.isSyncing(type) {
            appleHealthBolt
        }
    }
}
