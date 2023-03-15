import SwiftUI
import SwiftUISugar
import PrepDataTypes
import PrepCoreDataStack
import SwiftHaptics
import ActivityIndicatorView

struct BiometricSyncFailedForm: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    let type: BiometricType
    let syncStatus: BiometricSyncStatus
    
    var body: some View {
        QuickForm(title: title) {
            VStack {
                text
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                settingsButton
            }
            .foregroundColor(.secondary)
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .foregroundColor(Color(.quaternarySystemFill).opacity(colorScheme == .dark ? 0.5 : 1.0))
            )
            .padding(.horizontal, 20)
        }
        .presentationDetents([.height(syncStatus == .lastSyncFailed ? 280 : 220)])
        .presentationDragIndicator(.hidden)
    }
    
    var title: String {
        syncStatus == .nextAvailableSynced ? "No Data" : "Sync Failed"
    }
    
    @ViewBuilder
    var settingsButton: some View {
        if syncStatus == .lastSyncFailed {
            Button {
                Haptics.feedback(style: .soft)
                UIApplication.shared.open(URL(string: "App-prefs:Privacy&path=HEALTH")!)
            } label: {
                ButtonLabel(title: "Go to Settings", leadingSystemImage: "gear")
            }
            .buttonStyle(.borderless)
            .padding(.top, 5)
        }
    }
    
    @ViewBuilder
    var text: some View {
        if syncStatus == .lastSyncFailed {
            Text("There may be no **\(type.description)** data available in the Health App, or you may not have granted us permission to access it.")
        } else {
            Text("No **\(type.description)** data was found for the selected period in the Health App, so the next available data was used instead.")
        }
    }
}
