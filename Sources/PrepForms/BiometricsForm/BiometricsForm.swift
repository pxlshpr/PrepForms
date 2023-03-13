import SwiftUI
import SwiftUISugar
import PrepDataTypes
import PrepCoreDataStack
import SwiftHaptics

public struct BiometricsForm: View {
    
    @StateObject var model: BiometricsModel
    
    @Namespace var namespace
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.dismiss) var dismiss

    let didUpdateBiometrics = NotificationCenter.default.publisher(for: .didUpdateBiometrics)
    
    public init() {
        let user = DataManager.shared.user
        let biometrics = user?.biometrics
        let units = user?.options.units ?? .defaultUnits
        let model = BiometricsModel(existingProfile: biometrics, userUnits: units)
        _model = StateObject(wrappedValue: model)
    }
    
    public var body: some View {
        NavigationView {
            content
                .navigationTitle("Biometrics")
                .toolbar { trailingContent }
                .toolbar { leadingContent }
                .onAppear(perform: appeared)
                .onReceive(didUpdateBiometrics, perform: didUpdateBiometrics)
                .onChange(of: scenePhase, perform: scenePhaseChanged)
        }
    }
    
    func scenePhaseChanged(newValue: ScenePhase) {
        switch newValue {
//        case .active:
//            UserManager.setDidViewBiometrics()
        default:
            break
        }
    }
    
    func setBadges(from previousBiometrics: PreviousBiometrics) {
        print("🤎 Setting biometrics from previous")
    }
    
    func appeared() {
        if UserManager.shouldShowBiometricsBadge, let previousBiometrics = UserManager.previousBiometrics {
            setBadges(from: previousBiometrics)
            UserManager.setDidViewBiometrics()
        }
    }
    
    func didUpdateBiometrics(notification: Notification) {
        let updated = UserManager.biometrics
        withAnimation {
            self.model.load(updated)
        }
        if let previousBiometrics = UserManager.previousBiometrics {
            setBadges(from: previousBiometrics)
        }
        UserManager.setDidViewBiometrics()
    }
    
    var leadingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarLeading) {
//            syncAllButton
            lastUpdatedAt
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
            restingEnergySection
            activeEnergySection
            profileTitle
            weightSection
            leanBodyMassSection
            heightSection
            ageSection
            biologicalSexSection
        }
    }
    
    var profileTitle: some View {
        HStack {
            Text("Body Profile")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundColor(.primary)
            Spacer()
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
    
    var maintenanceEnergySection: some View {
        TDEESection(includeHeader: true, largeTitle: true)
            .environmentObject(model)
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

