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
        if model.lastUpdatedAt == nil {
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

    
    var content: some View {
        FormStyledScrollView {
            infoSection
            energyGroup
            profileTitle
            weightSection
            leanBodyMassSection
            heightSection
            ageSection
            biologicalSexSection
            footerSection
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
        @ViewBuilder
        var syncedSymbol: some View {
            if model.isSyncing(.activeEnergy) || model.isSyncing(.restingEnergy) {
                appleHealthBolt
            }
        }

        return HStack {
            Image(systemName: "flame.fill")
                .font(.title2)
            Text("Maintenance \(UserManager.energyDescription)")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundColor(.primary)
            Spacer()
            syncedSymbol
        }
        .padding(.horizontal, 20 + 17)
        .padding(.top, 20)
        .padding(.bottom, 0)
    }

    var infoText: some View {
//        Text("These are used to create goals based on your **\(UserManager.tdeeDescription)**, which is an estimate of how much you would have to consume to *maintain* your current weight.")
//        Text("Your biometric data is used to create goals based on your **Maintenance Calories**, which estimates what you need to consume to *maintain* your current weight.")
        Text("We use your biometric data to set goals based on your **\(UserManager.tdeeDescription)** and to monitor changes in your **body mass**.")
    }
    
    var infoSection: some View {
        infoText
            .multilineTextAlignment(.leading)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 30)
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
    
    @ViewBuilder
    var footerSection: some View {
        if model.isSyncingAtLeastOneType {
            HStack(alignment: .firstTextBaseline) {
                appleHealthBolt
                    .imageScale(.small)
                    .frame(width: 25)
                Text("These biometrics are being kept in sync with your data from the Health App.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
        }
    }
}

