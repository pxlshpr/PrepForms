import SwiftUI
import SwiftHaptics
import PrepDataTypes
import ActivityIndicatorView
import SwiftUISugar

struct ProfileForm: View {
    
    @EnvironmentObject var model: BiometricsModel
    @Namespace var namespace

    var infoSection: some View {
        FormStyledSection {
            Text("Please provide these details in order to calculate your resting energy using the \(model.restingEnergyFormula.menuDescription) formula.")
                .foregroundColor(.secondary)
        }
    }
    
    var trailingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            if model.shouldShowSyncAllForMeasurementsForm {
                Button {
                    model.tappedSyncAllOnMeasurementsForm()
                } label: {
                    ButtonLabel(title: "Sync All", style: .health, isCompact: true)
//                    AppleHealthButtonLabel(title: "Sync All", isCompact: true)
                }
            }
        }
    }
    
    var body: some View {
        FormStyledScrollView {
            infoSection
            AgeSection()
            BiologicalSexSection(includeFooter: true)
            WeightSection()
            if model.restingEnergyFormula.requiresHeight {
                HeightSection()
            }
        }
//        .navigationTitle(model.restingEnergyFormula.menuDescription + " Formula")
        .navigationTitle("Biometrics")
        .toolbar { trailingContent }
    }
}
