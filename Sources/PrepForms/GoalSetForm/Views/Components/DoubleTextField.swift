import SwiftUI

struct DoubleTextField: View {
    
    @Binding var double: Double?
    var placeholder: String = "Required"
    
    @FocusState var isFocused: Bool    
    @State var internalString: String
    
    let focusOnAppear: Bool

    @Binding var shouldResignFocus: Bool

    init(double: Binding<Double?>, placeholder: String, focusOnAppear: Bool = false, shouldResignFocus: Binding<Bool>) {
        _double = double
        _internalString = State(initialValue: double.wrappedValue?.cleanAmount ?? "")
        self.placeholder = placeholder
        self.focusOnAppear = focusOnAppear
        _shouldResignFocus = shouldResignFocus
    }
    
    var body: some View {
        let binding = Binding<String>(
            get: {
                internalString
            },
            set: { newValue in
                guard !newValue.isEmpty else {
                    double = nil
                    internalString = newValue
                    return
                }
                guard let double = Double(newValue) else {
                    return
                }
                self.double = double
                withAnimation {
                    self.internalString = newValue
                }
            }
        )
        
        return TextField(placeholder, text: binding)
            .multilineTextAlignment(.leading)
            .focused($isFocused)
            .font(textFieldFont)
            .keyboardType(.decimalPad)
            .frame(minHeight: 50)
            .scrollDismissesKeyboard(.interactively)
            .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { obj in
                if let textField = obj.object as? UITextField {
                    textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
                }
            }
            .onTapGesture {
                isFocused = true
            }
            .onAppear {
                if focusOnAppear {
                    self.isFocused = true
                }
            }
            .onChange(of: double, perform: doubleChanged)
            .onChange(of: shouldResignFocus, perform: shouldResignFocusChanged)
    }
    
    func shouldResignFocusChanged(to newValue: Bool) {
        isFocused = false
    }
    
    /// Detect external changes
    func doubleChanged(to newDouble: Double?) {
        withAnimation {
            self.internalString = newDouble?.cleanAmount ?? ""
        }
    }
    
    var textFieldFont: Font {
        internalString.isEmpty ? .body : .largeTitle
    }
    
}
