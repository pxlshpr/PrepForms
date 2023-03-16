import SwiftUI
import SwiftUISugar
import SwiftHaptics

extension GoalValuesSection {
    struct ValueForm: View {
        @Environment(\.dismiss) var dismiss
        @Environment(\.colorScheme) var colorScheme
        @FocusState var isFocused: Bool
        
        @State var hasFocusedOnAppear: Bool = false
        @State var hasCompletedFocusedOnAppearAnimation: Bool = false

        @StateObject var model: Model
        
        let handleNewValue: (Double?) -> ()
        
        init(
            value: Double?,
            unitStrings: (String, String?),
            handleNewValue: @escaping (Double?) -> ()
        ) {
            self.handleNewValue = handleNewValue
            let model = Model(
                initialDouble: value,
                unitStrings: unitStrings
            )
            _model = StateObject(wrappedValue: model)
        }
        
        class Model: ObservableObject {
            let initialDouble: Double?
            let unitStrings: (String, String?)
            @Published var internalString: String = ""
            @Published var internalDouble: Double? = nil

            init(initialDouble: Double?, unitStrings: (String, String?)) {
                self.initialDouble = initialDouble
                self.internalDouble = initialDouble
                self.internalString = initialDouble?.cleanAmount ?? ""
                self.unitStrings = unitStrings
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

                return false
            }
        }
    }
}

extension GoalValuesSection.ValueForm {
    var body: some View {
        NavigationStack {
            QuickForm(title: "Amount") {
                textFieldSection
            }
            .onChange(of: isFocused, perform: isFocusedChanged)
        }
        .presentationDetents([.height(140)])
        .presentationDragIndicator(.hidden)
    }
    
    var textFieldSection: some View {
        HStack(spacing: 0) {
            FormStyledSection(horizontalOuterPadding: 0) {
                HStack {
                    textField
                    unitLabel
                }
            }
            .padding(.leading, 20)
            doneButton
                .padding(.horizontal, 20)
        }
    }
    
    var doneButton: some View {
        FormInlineDoneButton(disabled: model.shouldDisableDone) {
            Haptics.feedback(style: .rigid)
            handleNewValue(model.internalDouble)
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
            get: { model.textFieldString },
            set: { newValue in
                withAnimation {
                    model.textFieldString = newValue
                }
            }
        )

        return TextField("Optional", text: binding)
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
    
    var unitLabel: some View {
        VStack {
            Text(model.unitStrings.0)
                .fontWeight(.semibold)
            if let bottomString = model.unitStrings.1 {
                Text(bottomString)
                    .fontWeight(.medium)
                    .opacity(0.75)
            }
        }
//        .foregroundColor(.accentColor)
        .foregroundColor(Color(.secondaryLabel))
        .padding(.vertical, 15)
        .padding(.horizontal, 15)
        .frame(minHeight: 40)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(
//                    Color.accentColor.opacity(colorScheme == .dark ? 0.1 : 0.15)
                    Color(.secondaryLabel).opacity(colorScheme == .dark ? 0.1 : 0.15)
//                    Color(.secondarySystemFill)
                )
        )
        .fixedSize(horizontal: true, vertical: false)
    }
}
