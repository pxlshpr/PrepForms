import SwiftUI
import PrepDataTypes
import PrepCoreDataStack

struct BiometricSectionHeader: View {
    
    @EnvironmentObject var model: BiometricsModel
    let type: BiometricType
    
    var body: some View {
        HStack {
            symbol
            Text(title)
            updatedBadge
            Spacer()
//            syncedSymbol
        }
        .textCase(.uppercase)
        .fixedSize(horizontal: false, vertical: true)
        .foregroundColor(Color(.secondaryLabel))
        .font(.footnote)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    var title: String {
        switch type {
        case .restingEnergy:
            return "Resting Energy"
        case .activeEnergy:
            return "Active Energy"
        default:
            return type.description
        }
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
