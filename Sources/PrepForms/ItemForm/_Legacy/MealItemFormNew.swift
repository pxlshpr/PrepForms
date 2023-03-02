import SwiftUI
import PrepDataTypes
import PrepCoreDataStack
import SwiftHaptics
import PrepViews
import SwiftUISugar

//struct MealItemFormNew: View {
//
//    @Environment(\.colorScheme) var colorScheme
//    @ObservedObject var viewModel: MealItemViewModel
//    @State var hasAppeared: Bool = false
//    @State var bottomHeight: CGFloat = 0.0
//
//    let tappedSave: () -> ()
//    let tappedQuantityForm: () -> ()
//
//    var body: some View {
//        ZStack {
//            scrollView
//            saveLayer
//        }
//    }
//}

//struct MealItemFormQuantity: View {
//    @ObservedObject var viewModel: MealItemViewModel
//    @FocusState var isFocused: Bool
//    @State var showingUnitPicker = false
//}
//
//extension MealItemFormQuantity {
//    var body: some View {
//        FormStyledScrollView {
//            textFieldSection
//        }
//        .navigationTitle("Quantity")
//        .sheet(isPresented: $showingUnitPicker) { unitPicker }
//        .onAppear(perform: appeared)
//    }
//
//    func appeared() {
//        isFocused = true
//    }
//
//    var textFieldSection: some View {
//        return Group {
//            FormStyledSection {
//                HStack {
//                    textField
//                    unitView
//                }
//            }
//        }
//    }
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
//        var font: Font {
//            return viewModel.amountString.isEmpty ? .body : .largeTitle
//        }
//
//        return TextField("Required", text: binding)
//            .multilineTextAlignment(.leading)
//            .focused($isFocused)
//            .font(font)
//            .keyboardType(.decimalPad)
//            .frame(minHeight: 50)
//            .scrollDismissesKeyboard(.interactively)
//            .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { obj in
//                if let textField = obj.object as? UITextField {
//                    textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
//                }
//            }
//    }
//
//    var unitView: some View {
//        var unitButton: some View {
//            Button {
//                showingUnitPicker = true
//            } label: {
//                HStack(spacing: 5) {
//                    Text(viewModel.unitDescription)
//                        .multilineTextAlignment(.trailing)
////                        .foregroundColor(.secondary)
//                        .font(.title3)
//                    Image(systemName: "chevron.up.chevron.down")
//                        .imageScale(.small)
//                }
//                .bold()
//            }
//            .buttonStyle(.borderless)
//        }
//
//        return Group {
////            if supportedUnits.count > 1 {
//                unitButton
////            } else {
////                Text(viewModel.unitDescription)
////                    .multilineTextAlignment(.trailing)
////                    .foregroundColor(.secondary)
////                    .font(.title3)
////            }
//        }
//    }
//
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
//}

