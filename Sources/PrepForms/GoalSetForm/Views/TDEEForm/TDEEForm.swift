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
    @State var presentedSheet: Sheet? = nil

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
                .sheet(item: $presentedSheet) { sheet(for: $0) }
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
    
    var maintenanceSection: some View {
        MaintenanceSection()
            .environmentObject(model)
    }
    
    
    var trailingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            doneButton
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

extension TDEEForm {
    
    enum Sheet: Hashable, Identifiable {
        case resting(RestingEnergySheet)
        case active(ActiveEnergySheet)
        
        var id: Self { self }
    }
    
    @ViewBuilder
    func sheet(for sheet: Sheet) -> some View {
        
        switch sheet {
            
        case .resting(let restingEnergySheet):
            model.restingEnergySheet(for: restingEnergySheet)
            
        case .active(let activeEnergySheet):
            model.activeEnergySheet(for: activeEnergySheet)
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

enum LeanBodyMassSheet: Hashable, Identifiable {
    case source
    case equation
    
    var id: Self { self }
}

enum ActiveEnergySheet: Hashable, Identifiable {
    case source
    case intervalType
    case intervalPeriod
    case intervalValue
    case activityLevel

    var id: Self { self }
}
