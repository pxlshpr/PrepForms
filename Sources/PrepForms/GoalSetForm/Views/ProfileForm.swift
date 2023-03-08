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
                    AppleHealthButtonLabel(title: "Sync All", isCompact: true)
//                    HStack {
//                        appleHealthSymbol
//                        Text("Sync All")
//                    }
                }
            }
        }
    }
    
    var body: some View {
        FormStyledScrollView {
            infoSection
            AgeSection()
            BiologicalSexSection()
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
