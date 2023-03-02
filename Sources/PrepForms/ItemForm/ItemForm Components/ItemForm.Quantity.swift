
import SwiftUI
import SwiftHaptics
import PrepViews
import PrepDataTypes
import SwiftUISugar

extension ItemForm {
    
    struct QuantityForm: View {
        
        let food: Food
        @StateObject var viewModel: ViewModel

        @Environment(\.dismiss) var dismiss
        @Environment(\.colorScheme) var colorScheme
        @FocusState var isFocused: Bool
        
        @State var showingUnitPicker = false
        @State var hasFocusedOnAppear: Bool = false
        @State var hasCompletedFocusedOnAppearAnimation: Bool = false
        
        let didSubmit: (Double, FormUnit) -> ()
        
        init(
            food: Food,
            double: Double?,
            unit: FormUnit,
            didSubmit: @escaping (Double, FormUnit) -> ()
        ) {
            let viewModel = ViewModel(
                initialDouble: double,
                initialUnit: unit
            )
            _viewModel = StateObject(wrappedValue: viewModel)
            self.food = food
            self.didSubmit = didSubmit
        }
        
        class ViewModel: ObservableObject {
            let initialDouble: Double?
            let initialUnit: FormUnit
            @Published var internalString: String = ""
            @Published var internalDouble: Double? = nil
            @Published var internalUnit: FormUnit

            init(initialDouble: Double?, initialUnit: FormUnit) {
                self.initialDouble = initialDouble
                self.internalDouble = initialDouble
                self.internalString = initialDouble?.cleanAmount ?? ""
                self.initialUnit = initialUnit
                self.internalUnit = initialUnit
            }
            
            var textFieldString: String {
                get { internalString }
                set {
                    guard !newValue.isEmpty else {
                        internalDouble = nil
                        internalString = newValue
                        return
                    }
                    guard let double = Double(newValue) else {
                        return
                    }
                    self.internalDouble = double
                    self.internalString = newValue
                }
            }
            
            var shouldDisableDone: Bool {
                if initialDouble == internalDouble && initialUnit == internalUnit {
                    return true
                }

                if internalDouble == nil {
                    return true
                }
                return false
            }
        }
    }
}

extension ItemForm.QuantityForm {
    
    var body: some View {
        NavigationStack {
            QuickForm(title: "Quantity") {
                textFieldSection
            }
            .onChange(of: isFocused, perform: isFocusedChanged)
        }
        .presentationDetents([.height(140)])
        .presentationDragIndicator(.hidden)
        .sheet(isPresented: $showingUnitPicker) { unitPicker }
    }
    
    var textFieldSection: some View {
        HStack(spacing: 0) {
            FormStyledSection(horizontalOuterPadding: 0) {
                HStack {
                    textField
                    unitPickerButton
                }
            }
            .padding(.leading, 20)
            doneButton
                .padding(.horizontal, 20)
        }
    }
    
    var doneButton: some View {
        FormInlineDoneButton(disabled: viewModel.shouldDisableDone) {
            Haptics.feedback(style: .rigid)
            didSubmit(viewModel.internalDouble ?? 1, viewModel.internalUnit)
            dismiss()
        }
    }
    
    func isFocusedChanged(_ newValue: Bool) {
        if !isFocused {
            dismiss()
        }
    }
    
    var textField: some View {
        let binding = Binding<String>(
            get: { viewModel.textFieldString },
            set: { newValue in
                withAnimation {
                    viewModel.textFieldString = newValue
                }
            }
        )

        return TextField("Required", text: binding)
            .focused($isFocused)
            .multilineTextAlignment(.leading)
            .font(binding.wrappedValue.isEmpty ? .body : .largeTitle)
            .keyboardType(.decimalPad)
            .frame(minHeight: 50)
            .scrollDismissesKeyboard(.never)
            .introspectTextField { uiTextField in
                if !hasFocusedOnAppear {
                    uiTextField.becomeFirstResponder()
                    uiTextField.selectedTextRange = uiTextField.textRange(from: uiTextField.beginningOfDocument, to: uiTextField.endOfDocument)

                    hasFocusedOnAppear = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeIn) {
                            hasCompletedFocusedOnAppearAnimation = true
                        }
                    }
                }
            }
    }
    
    var unitPicker: some View {
        UnitPickerGridTiered(
            pickedUnit: viewModel.internalUnit,
            includeServing: food.servingQuantity != nil,
            includeWeights: food.canBeMeasuredInWeight,
            includeVolumes: food.canBeMeasuredInVolume,
            sizes: food.formSizes,
            allowAddSize: false,
            didPickUnit: { newUnit in
                withAnimation {
                    Haptics.feedback(style: .rigid)
                    viewModel.internalUnit = newUnit
                }
            }
        )
    }
    
    var unitPickerButton: some View {
        Button {
            Haptics.feedback(style: .soft)
            showingUnitPicker = true
        } label: {
            HStack(spacing: 2) {
                Text(viewModel.internalUnit.shortDescription)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
                    .minimumScaleFactor(0.3)
                    .fontWeight(.semibold)
                    .fixedSize(horizontal: false, vertical: true)
                Image(systemName: "chevron.up.chevron.down")
                    .imageScale(.small)
            }
            .foregroundColor(.accentColor)
            .padding(.horizontal, 15)
            .padding(.vertical, 5)
            .frame(minHeight: 40)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.accentColor.opacity(
                        colorScheme == .dark ? 0.1 : 0.15
                    ))
            )
//            .animation(.none, value: viewModel.internalUnit)
        }
        .contentShape(Rectangle())
    }
}
