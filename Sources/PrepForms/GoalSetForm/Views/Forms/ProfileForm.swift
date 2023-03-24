import SwiftUI
import SwiftHaptics
import PrepDataTypes
import ActivityIndicatorView
import SwiftUISugar

struct ProfileForm: View {
    
    @Environment(\.dismiss) var dismiss
    @ObservedObject var model: BiometricsModel
    
    init(_ model: BiometricsModel) {
        self.model = model
    }
    
    var body: some View {
        quickForm
    }
    
    var quickForm: some View {
        NavigationView {
            FormStyledScrollView {
                infoSection
                AgeSection()
                BiologicalSexSection(includeFooter: true)
                WeightSection()
                if model.restingEnergyEquation.requiresHeight {
                    HeightSection()
                }
            }
            .navigationTitle("Components")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { trailingContent }
        }
    }
    
    var infoSection: some View {
        FormStyledSection {
            Text("These are used to calculate your resting energy using the \(model.restingEnergyEquation.menuDescription) equation.")
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(.secondary)
        }
    }
    
    var trailingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            syncButton
            dismissButton
        }
    }
    
    var dismissButton: some View {
        Button {
            Haptics.feedback(style: .soft)
            dismiss()
        } label: {
            CloseButtonLabel(forNavigationBar: true)
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
