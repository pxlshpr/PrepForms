import SwiftUI
import SwiftHaptics
import PrepViews
import SwiftUISugar

extension SizeForm {
    struct QuantityForm: View {

        @EnvironmentObject var fields: FoodForm.Fields
        
        @ObservedObject var sizeFormModel: SizeFormModel
        @StateObject var model: Model

        @Environment(\.dismiss) var dismiss
        @Environment(\.colorScheme) var colorScheme
        @FocusState var isFocused: Bool
        
        @State var hasFocusedOnAppear: Bool = false
        @State var hasCompletedFocusedOnAppearAnimation: Bool = false
        
        init(sizeFormModel: SizeFormModel) {
            self.sizeFormModel = sizeFormModel
            let model = Model(initialDouble: sizeFormModel.quantity)
            _model = StateObject(wrappedValue: model)
        }
        
        class Model: ObservableObject {
            let initialDouble: Double
            @Published var internalString: String = ""
            @Published var internalDouble: Double? = nil

            init(initialDouble: Double) {
                self.initialDouble = initialDouble
                self.internalDouble = initialDouble
                self.internalString = initialDouble.cleanAmount
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
                if initialDouble == internalDouble {
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

extension SizeForm.QuantityForm {
    
    var body: some View {
        NavigationStack {
            QuickForm(title: "Quantity") {
                textFieldSection
            }
            .toolbar(.hidden, for: .navigationBar)
            .onChange(of: isFocused, perform: isFocusedChanged)
        }
        .presentationDetents([.height(140)])
        .presentationDragIndicator(.hidden)
    }
    
    var doneButton: some View {
        FormInlineDoneButton(disabled: model.shouldDisableDone) {
            Haptics.feedback(style: .rigid)
            sizeFormModel.quantity = model.internalDouble ?? 1
            dismiss()
        }
    }
    
    var textFieldSection: some View {
        HStack(spacing: 0) {
            FormStyledSection(horizontalOuterPadding: 0) {
                HStack {
                    textField
                }
            }
            .padding(.leading, 20)
            doneButton
                .padding(.horizontal, 20)
        }
    }
    
    func isFocusedChanged(_ newValue: Bool) {
        if !isFocused {
            dismiss()
        }
    }
    
    var textField: some View {
        let binding = Binding<String>(
            get: { model.textFieldString },
            set: { newValue in
                withAnimation {
                    model.textFieldString = newValue
                }
            }
        )

        return TextField("e.g. \'5\' if \"5 cookies (50g)\"", text: binding)
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
}
