import SwiftUI
import SwiftUISugar
import PrepDataTypes

struct WeightForm: View {

    @StateObject var model: BiometricsModel = BiometricsModel()
    
    var body: some View {
        quickForm
            .presentationDetents([.height(300)])
    }
    
    var quickForm: some View {
        QuickForm(title: "Weight") {
            WeightSection(includeHeader: false)
                .environmentObject(model)
        }
    }
}
