import SwiftUI
import SwiftUISugar
import PrepDataTypes
import SwiftHaptics

struct WeightForm: View {

    @Environment(\.dismiss) var dismiss
    @StateObject var model: BiometricsModel = BiometricsModel()
    
    var body: some View {
        NavigationView {
            VStack {
                WeightSection(includeHeader: false)
                    .environmentObject(model)
                Spacer()
            }
            .navigationTitle("Weight")
            .toolbar { trailingContent }
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.height(300)])
    }
    
    var trailingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
//            if isValid {
                doneButton
//            } else {
//                dismissButton
//            }
        }
    }
    
    var isValid: Bool {
        model.weight != nil
    }

    @ViewBuilder
    var doneButton: some View {
        Button {
            Haptics.successFeedback()
            dismiss()
        } label: {
            Text("Done")
//                .fontWeight(.bold)
//                .foregroundColor(.white)
//                .frame(height: 32)
//                .padding(.horizontal, 8)
//                .background(
//                    RoundedRectangle(cornerRadius: 7, style: .continuous)
//                        .fill(Color.accentColor.gradient)
//                )
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
