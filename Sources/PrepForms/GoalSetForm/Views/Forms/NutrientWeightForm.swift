import SwiftUI
import SwiftUISugar
import PrepDataTypes

struct NutrientWeightForm: View {

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var model: BiometricsModel
    
    var body: some View {
        NavigationView {
            form
                .toolbar { leadingContent }
        }
    }
    
    var form: some View {
        FormStyledScrollView {
            WeightSection(includeHeader: false)
                .environmentObject(model)
                .navigationTitle("Weight")
        }
    }

    var leadingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarLeading) {
            Button {
                dismiss()
            } label: {
                closeButtonLabel
            }
        }
    }
}
