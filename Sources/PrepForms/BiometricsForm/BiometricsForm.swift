import SwiftUI
import SwiftUISugar
import PrepDataTypes
import PrepCoreDataStack
import SwiftHaptics

public struct BiometricsForm: View {
    
    @Namespace var namespace
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @StateObject var model: BiometricsModel = BiometricsModel()
    @State var presentedSheet: Sheet? = nil
    @State var changedTypes: [BiometricType] = []

    let didUpdateBiometrics = NotificationCenter.default.publisher(for: .didUpdateBiometrics)
    
    public init() { }
    
    public var body: some View {
        NavigationView {
            content
                .navigationTitle("Biometrics")
                .toolbar { trailingContent }
                .toolbar { leadingContent }
                .onAppear(perform: appeared)
                .onReceive(didUpdateBiometrics, perform: didUpdateBiometrics)
                .sheet(item: $presentedSheet) { sheet(for: $0) }
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
            HStack(spacing: 0) {
                syncAllButton
                closeButton
            }
        }
    }
    
    var closeButton: some View {
        Button {
            Haptics.feedback(style: .soft)
            dismiss()
        } label: {
            CloseButtonLabel()
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
}

extension BiometricsForm {
    
    var restingEnergySection: some View {
        func presentSheet(_ sheet: RestingEnergySheet) {
            present(.resting(sheet))
        }
        return RestingEnergySection(sheetPresenter: presentSheet)
            .environmentObject(model)
    }

    var activeEnergySection: some View {
        func presentSheet(_ sheet: ActiveEnergySheet) {
            present(.active(sheet))
        }
        return ActiveEnergySection(sheetPresenter: presentSheet)
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


extension BiometricsForm {
    
    enum Sheet: Hashable, Identifiable {
        case resting(RestingEnergySheet)
        case active(ActiveEnergySheet)
        case leanBodyMass(LeanBodyMassSheet)
        case weightSource
        case heightSource
        case ageSource
        case sexSource
        
        var id: Self { self }
    }
}

extension BiometricsForm {
    
    @ViewBuilder
    func sheet(for sheet: Sheet) -> some View {
        
        switch sheet {
            
        case .resting(let restingEnergySheet):
            model.restingEnergySheet(for: restingEnergySheet)
            
        case .active(let activeEnergySheet):
            model.activeEnergySheet(for: activeEnergySheet)
            
        case .leanBodyMass(let leanBodyMassSheet):
            switch leanBodyMassSheet {
            case .source:
                EmptyView()
            case .equation:
                EmptyView()
            }
            
        case .weightSource:
            EmptyView()
            
        case .heightSource:
            EmptyView()
            
        case .ageSource:
            EmptyView()
            
        case .sexSource:
            EmptyView()
            
        }
    }
    
    func present(_ sheet: Sheet) {
        
        func present() {
            Haptics.feedback(style: .soft)
            presentedSheet = sheet
        }
        
        func delayedPresent() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                present()
            }
        }
        
        if presentedSheet != nil {
            presentedSheet = nil
            delayedPresent()
        } else {
            present()
        }
    }
}
