//import SwiftUI
//import SwiftHaptics
//
//struct TextPicker: View {
//    @Environment(\.dismiss) var dismiss
//    @StateObject var textPickerModel: TextPickerModel
//    @State var pickedColumn: Int = 1
//    
//    @State var showingAutoFillConfirmation = false
//    @State var showingDeleteConfirmation = false
//
//    init(imageModels: [ImageModel], mode: TextPickerMode) {
//        let model = TextPickerModel(
//            imageModels: imageModels,
//            mode: mode
//        )
//        _textPickerModel = StateObject(wrappedValue: model)
//    }
//    
//    var body: some View {
//        ZStack {
//            pagerLayer
//            buttonsLayer
//                .confirmationDialog("AutoFill", isPresented: $showingAutoFillConfirmation) {
//                    Button("Confirm AutoFill") {
//                        Haptics.successFeedback()
//                        textPickerModel.tappedConfirmAutoFill()
//                    }
//                } message: {
//                    Text("This will replace any existing data with those detected in this image")
//                }
//        }
//        .onAppear(perform: appeared)
//        .onChange(of: textPickerModel.shouldDismiss) { newValue in
//            if newValue {
//                dismiss()
//            }
//        }
//        .onChange(of: textPickerModel.showingAutoFillConfirmation, perform: { newValue in
//            showingAutoFillConfirmation = newValue
//        })
//    }
//    
//    func appeared() {
////        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//            textPickerModel.setInitialState()
////        }
//    }
//}
