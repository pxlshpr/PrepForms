//import SwiftUI
//import Combine
//import PrepViews
//
//extension MealItemForm.QuantityForm {
//    
//    var textField: some View {
//        let binding = Binding<String>(
//            get: { viewModel.amountString },
//            set: { newValue in
//                withAnimation {
//                    viewModel.amountString = newValue
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
//                Text(viewModel.unitDescription)
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
//            pickedUnit: viewModel.unit.formUnit,
//            includeServing: viewModel.shouldShowServingInUnitPicker,
//            includeWeights: viewModel.shouldShowWeightUnits,
//            includeVolumes: viewModel.shouldShowVolumeUnits,
//            sizes: viewModel.foodSizes,
//            servingDescription: viewModel.servingDescription,
//            allowAddSize: false,
//            didPickUnit: viewModel.didPickUnit
//        )
//    }
//    
//    var textFieldFont: Font {
//        viewModel.internalAmountDouble == nil ? .body : .largeTitle
//    }
//}
