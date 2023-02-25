import SwiftUI
import SwiftHaptics
import PrepDataTypes
import ActivityIndicatorView
import SwiftUISugar

struct ProfileForm: View {
    
    @EnvironmentObject var viewModel: TDEEForm.ViewModel
    @Namespace var namespace

    var infoSection: some View {
        FormStyledSection {
            Text("Please provide these details in order to calculate your resting energy using the \(viewModel.restingEnergyFormula.menuDescription) formula.")
                .foregroundColor(.secondary)
        }
    }
    
    var trailingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            if viewModel.shouldShowSyncAllForProfileForm {
                Button {
                    viewModel.tappedSyncAllOnProfileForm()
                } label: {
                    HStack {
                        appleHealthSymbol
                        Text("Sync All")
                    }
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
            if viewModel.restingEnergyFormula.requiresHeight {
                HeightSection()
            }
        }
//        .navigationTitle(viewModel.restingEnergyFormula.menuDescription + " Formula")
        .navigationTitle("Body Profile")
        .toolbar { trailingContent }
    }
}
