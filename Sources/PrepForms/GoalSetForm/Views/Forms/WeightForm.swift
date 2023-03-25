import SwiftUI
import SwiftUISugar
import PrepDataTypes
import SwiftHaptics

struct WeightForm: View {

    @Environment(\.dismiss) var dismiss
    @StateObject var model: BiometricsModel = BiometricsModel()
    
    var body: some View {
        quickForm
            .presentationDetents([.height(300)])
            .onChange(of: model.weight, perform: weightChanged)
    }
    
    func weightChanged(_ newValue: Double?) {
        guard newValue != nil else { return }
        Haptics.successFeedback()
        dismiss()
    }
    
    var quickForm: some View {
        QuickForm(title: "Weight") {
            WeightSection(includeHeader: false)
                .environmentObject(model)
        }
    }
}
