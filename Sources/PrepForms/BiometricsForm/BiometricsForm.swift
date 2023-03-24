import SwiftUI
import SwiftUISugar
import PrepDataTypes
import PrepCoreDataStack
import SwiftHaptics

public struct BiometricsForm: View {
    
    @StateObject var model: BiometricsModel = BiometricsModel()
    
    @Namespace var namespace
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    let didUpdateBiometrics = NotificationCenter.default.publisher(for: .didUpdateBiometrics)
    
    @State var changedTypes: [BiometricType] = []
    
    public init() { }
    
    public var body: some View {
        NavigationView {
            content
                .navigationTitle("Biometrics")
                .toolbar { trailingContent }
                .toolbar { leadingContent }
                .onAppear(perform: appeared)
                .onReceive(didUpdateBiometrics, perform: didUpdateBiometrics)
        }
    }
    
    var content: some View {
        FormStyledScrollView {
            allSections
        }
    }
    
    var allSections: some View {
        Group {
            infoSection
            energyGroup
            profileTitle
            weightSection
            leanBodyMassSection
            heightSection
            ageSection
            biologicalSexSection
        }
    }
    
    func appeared() {
        if UserManager.previousBiometrics != nil {
            UserManager.setDidViewBiometrics()
        }
    }
    
    func didUpdateBiometrics(notification: Notification) {
        let updated = UserManager.biometrics
        withAnimation {
            self.model.load(updated)
        }
        UserManager.setDidViewBiometrics()
    }
    
    var leadingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarLeading) {
            if model.isSyncingAtLeastOneType {
                lastUpdatedAt
            }
        }
    }
    
    @ViewBuilder
    var syncAllButton: some View {
        if model.shouldShowSyncAllButton {
            Button {
                model.tappedSyncAll()
            } label: {
                ButtonLabel(title: "Sync All", style: .health, isCompact: true)
            }
        }
    }
    
    var trailingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            syncAllButton
            closeButton
        }
    }
    
    var closeButton: some View {
        Button {
            Haptics.feedback(style: .soft)
            dismiss()
        } label: {
            CloseButtonLabel(forNavigationBar: true)
        }
    }
    
    @ViewBuilder
    var lastUpdatedAt: some View {
        if let lastUpdatedAt = model.lastUpdatedAt {
            Text("Updated: \(lastUpdatedAt.biometricShortFormat)")
                .foregroundColor(.secondary)
                .font(.footnote)
        }
    }

    var energyGroup: some View {
        Group {
            maintenanceTitle
            maintenanceSection
            Text("=")
                .font(.title)
                .foregroundColor(Color(.quaternaryLabel))
            restingEnergySection
            Text("+")
                .font(.title)
                .foregroundColor(Color(.quaternaryLabel))
            activeEnergySection
        }
    }
    
    var maintenanceSection: some View {
        MaintenanceSection()
            .environmentObject(model)
    }
    
    var profileTitle: some View {
        HStack {
            Image(systemName: "figure.arms.open")
                .font(.title2)
            Text("Body Profile")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal, 20 + 17)
        .padding(.top, 20)
        .padding(.bottom, 0)
    }

    var maintenanceTitle: some View {
        var isSynced: Bool {
            model.isSyncing(.activeEnergy) || model.isSyncing(.restingEnergy)
        }
        
        @ViewBuilder
        var syncedSymbol: some View {
            if isSynced {
                appleHealthBolt
            }
        }

        return HStack {
            syncedSymbol
//            Image(systemName: "flame.fill")
//                .font(.title2)
            Text("Maintenance Energy")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(
                    LinearGradient (
                        colors: [
                            isSynced ? HealthTopColor : .primary,
                            isSynced ? HealthBottomColor : .primary
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            Spacer()
        }
        .padding(.horizontal, 20 + 17)
        .padding(.top, 20)
        .padding(.bottom, 0)
    }

    var infoSection: some View {
        
        var content: some View {
            var text: some View {
                Text("Your biometric data is used to set goals based on your **Maintenance Energy**, also known as your Total Daily Energy Expenditure (TDEE).")
            }
            
            @ViewBuilder
            var syncInfo: some View {
                if model.isSyncingAtLeastOneType {
                    HStack(alignment: .firstTextBaseline) {
                        appleHealthBolt
                            .imageScale(.small)
                            .frame(width: 25)
                        Text("These biometrics are being kept in sync with your data from the Health App.")
//                            .font(.caption)
                            .foregroundColor(Color(.secondaryLabel))
                    }
                }
            }
            
            return VStack(alignment: .leading, spacing: 5) {
                Group {
//                    text
                    syncInfo
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        
        var section: some View {
            content
                .multilineTextAlignment(.leading)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .foregroundColor(
                            Color(.quaternarySystemFill)
                                .opacity(colorScheme == .dark ? 0.5 : 1)
                        )
                )
                .cornerRadius(10)
                .padding(.bottom, 10)
                .padding(.horizontal, 17)
        }
        
        return Group {
            if model.isSyncingAtLeastOneType {
                section
            }
        }
    }
    
    func updatedBinding(for type: BiometricType) -> Binding<Bool> {
        Binding<Bool>(
            get: { changedTypes.contains(type) },
            set: { _ in }
        )
    }
    var restingEnergySection: some View {
        RestingEnergySection()
            .environmentObject(model)
    }

    var activeEnergySection: some View {
        ActiveEnergySection()
            .environmentObject(model)
    }

    var weightSection: some View {
        WeightSection()
            .environmentObject(model)
    }

    var heightSection: some View {
        HeightSection()
            .environmentObject(model)
    }

    var biologicalSexSection: some View {
        BiologicalSexSection()
            .environmentObject(model)
    }
    
    var ageSection: some View {
        AgeSection()
            .environmentObject(model)
    }
    
    var leanBodyMassSection: some View {
        LeanBodyMassSection()
            .environmentObject(model)
    }
}

