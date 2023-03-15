import SwiftUI
import SwiftUISugar
import PrepDataTypes

struct NutrientLeanBodyMassForm: View {

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var model: BiometricsModel
    
    var body: some View {
        NavigationView {
            content
                .toolbar { leadingContent }
        }
    }
    
    var content: some View {
        LeanBodyMassForm()
            .environmentObject(model)
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
