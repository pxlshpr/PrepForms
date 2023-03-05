//import SwiftUI
//import Combine
//import PrepViews
//
//extension MealItemForm.QuantityForm {
//    
//    var textField: some View {
//        let binding = Binding<String>(
//            get: { model.amountString },
//            set: { newValue in
//                withAnimation {
//                    model.amountString = newValue
//                }
//            }
//        )
//        
//        return TextField("Required", text: binding)
//            .multilineTextAlignment(.leading)
//            .focused($isFocused)
////            .font(textFieldFont)
//            .keyboardType(.decimalPad)
////            .frame(minHeight: 50)
//            .scrollDismissesKeyboard(.interactively)
//            .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { obj in
//                if let textField = obj.object as? UITextField {
//                    textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
//                }
//            }
//    }
//
//    
//    var unitButton: some View {
//        Button {
//            showingUnitPicker = true
//        } label: {
//            HStack(spacing: 5) {
//                Text(model.unitDescription)
////                    .font(.title)
//                    .multilineTextAlignment(.trailing)
//                Image(systemName: "chevron.up.chevron.down")
//                    .imageScale(.small)
////                    .font(.title3)
////                    .imageScale(.large)
//            }
//        }
//        .buttonStyle(.borderless)
//    }
//    
//    @ViewBuilder
//    var unitPicker: some View {
//        UnitPickerGridTiered(
//            pickedUnit: model.unit.formUnit,
//            includeServing: model.shouldShowServingInUnitPicker,
//            includeWeights: model.shouldShowWeightUnits,
//            includeVolumes: model.shouldShowVolumeUnits,
//            sizes: model.foodSizes,
//            servingDescription: model.servingDescription,
//            allowAddSize: false,
//            didPickUnit: model.didPickUnit
//        )
//    }
//    
//    var textFieldFont: Font {
//        model.internalAmountDouble == nil ? .body : .largeTitle
//    }
//}
