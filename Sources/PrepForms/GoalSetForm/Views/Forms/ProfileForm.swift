import SwiftUI
import SwiftHaptics
import PrepDataTypes
import ActivityIndicatorView
import SwiftUISugar

struct ProfileForm: View {
    
    @EnvironmentObject var model: BiometricsModel
    
    var body: some View {
        quickForm
    }
    
    var quickForm: some View {
        QuickForm(title: "Components") {
            infoSection
            AgeSection()
            BiologicalSexSection(includeFooter: true)
            WeightSection()
            if model.restingEnergyFormula.requiresHeight {
                HeightSection()
            }
        }
        .toolbar { trailingContent }
    }
    
    var infoSection: some View {
        FormStyledSection {
            Text("These are used to calculate your resting energy using the \(model.restingEnergyFormula.menuDescription) formula.")
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(.secondary)
        }
    }
    
    var trailingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            syncButton
        }
    }
    
    @ViewBuilder
    var syncButton: some View {
        if model.shouldShowSyncAllForMeasurementsForm {
            Button {
                model.tappedSyncAllOnMeasurementsForm()
            } label: {
                ButtonLabel(title: "Sync All", style: .health, isCompact: true)
            }
        }
    }
}
