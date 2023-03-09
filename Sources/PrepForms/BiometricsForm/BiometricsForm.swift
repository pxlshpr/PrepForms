import SwiftUI
import SwiftUISugar
import PrepDataTypes
import PrepCoreDataStack
import SwiftHaptics

public struct BiometricsForm: View {
    
    @StateObject var model: BiometricsModel
    
    @Namespace var namespace
    @Environment(\.colorScheme) var colorScheme
    
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
        }
    }
    
    var trailingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button {
                model.tappedSyncAll()
            } label: {
                ButtonLabel(title: "Sync All", style: .health, isCompact: true)
            }
        }
    }
    
    var content: some View {
        FormStyledScrollView {
            infoSection
            maintenanceEnergySection
            weightSection
            leanBodyMassSection
            heightSection
            biologicalSexSection
            ageSection
        }
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
    
    var weightSection: some View {
        WeightSection(largeTitle: true)
            .environmentObject(model)
    }

    var heightSection: some View {
        HeightSection(largeTitle: true)
            .environmentObject(model)
    }

    var biologicalSexSection: some View {
        BiologicalSexSection(largeTitle: true)
            .environmentObject(model)
    }
    
    var ageSection: some View {
        AgeSection(largeTitle: true)
            .environmentObject(model)
    }
    
    var leanBodyMassSection: some View {
        LeanBodyMassSection(largeTitle: true)
            .environmentObject(model)
    }
}
