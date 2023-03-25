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
                .toolbar { leadingContent }
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
            if isValid {
                doneButton
            } else {
                dismissButton
            }
        }
    }
    
    var leadingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarLeading) {
            syncAllButton
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
    
    var isValid: Bool {
        model.maintenanceEnergy != nil
    }

    @ViewBuilder
    var doneButton: some View {
        Button {
            Haptics.successFeedback()
            dismiss()
        } label: {
            Text("Done")
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(height: 32)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color.accentColor.gradient)
                )
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
