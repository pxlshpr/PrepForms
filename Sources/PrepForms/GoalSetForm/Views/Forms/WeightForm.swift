import SwiftUI
import SwiftUISugar
import PrepDataTypes
import SwiftHaptics

struct WeightForm: View {

    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject var model: BiometricsModel = BiometricsModel()
    @State var showingSourcePicker: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                WeightSection(
                    includeHeader: false,
                    showSourcePicker: showSourcePicker
                )
                .environmentObject(model)
                Spacer()
            }
            .navigationTitle("Weight")
            .toolbar { trailingContent }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingSourcePicker) { sourcePicker }
            .background(
                formBackgroundColor(colorScheme: colorScheme)
                    .edgesIgnoringSafeArea(.all)
            )
        }
        .presentationDetents([.height(300)])
    }
    
    var sourcePicker: some View {
        model.measurementSourcePickerSheet(for: .weight)
    }
    
    func showSourcePicker() {
        showingSourcePicker = true
    }
    
    var trailingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            doneButton
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
