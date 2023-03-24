import SwiftUI
import SwiftUISugar
import SwiftHaptics
import PrepDataTypes
import HealthKit
import PrepCoreDataStack

public struct TDEEForm: View {
    
    @Namespace var namespace
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject var model: BiometricsModel = BiometricsModel()
    
    @State var showingSaveButton: Bool = false
    
    let didUpdateBiometrics = NotificationCenter.default.publisher(for: .didUpdateBiometrics)
    
    @ViewBuilder
    public var body: some View {
        NavigationView {
            form
                .scrollDismissesKeyboard(.interactively)
                .navigationTitle("Maintenance Energy")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { trailingContent }
                .onReceive(didUpdateBiometrics, perform: didUpdateBiometrics)
        }
    }
    
    func didUpdateBiometrics(notification: Notification) {
        withAnimation {
            self.model.load(UserManager.biometrics)
        }
    }

    var form: some View {
        FormStyledScrollView {
            maintenanceSection
            symbol("=")
            restingEnergySection
            symbol("+")
            activeEnergySection
        }
    }
    
    func symbol(_ string: String) -> some View {
        Text(string)
            .font(.title)
            .foregroundColor(Color(.quaternaryLabel))
    }
    
    var restingEnergySection: some View {
        RestingEnergySection()
            .environmentObject(model)
    }
    
    var activeEnergySection: some View {
        ActiveEnergySection()
            .environmentObject(model)
    }
    
    var maintenanceSection: some View {
        MaintenanceSection()
            .environmentObject(model)
    }
    
    
    var trailingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            HStack(spacing: 0) {
                syncAllButton
                dismissButton
            }
        }
    }
    
    @ViewBuilder
    var syncAllButton: some View {
        if model.shouldShowSyncAllForTDEEForm {
            Button {
                model.tappedSyncAllOnTDEEForm()
            } label: {
                ButtonLabel(title: "Sync All", style: .health, isCompact: true)
            }
        }
    }
    
    var dismissButton: some View {
        Button {
            Haptics.feedback(style: .soft)
            dismiss()
        } label: {
            CloseButtonLabel()
        }
    }
}
