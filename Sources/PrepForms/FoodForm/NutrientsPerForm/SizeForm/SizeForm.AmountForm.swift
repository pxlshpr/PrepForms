import SwiftUI
import SwiftHaptics
import PrepViews
import PrepDataTypes
import SwiftUISugar

extension SizeForm {
    struct AmountForm: View {

        @EnvironmentObject var fields: FoodForm.Fields
        
        @ObservedObject var sizeFormModel: SizeFormModel
        @StateObject var model: Model

        @Environment(\.dismiss) var dismiss
        @Environment(\.colorScheme) var colorScheme
        @FocusState var isFocused: Bool
        
        @State var showingUnitPicker = false
        @State var hasFocusedOnAppear: Bool = false
        @State var hasCompletedFocusedOnAppearAnimation: Bool = false
        
        init(sizeFormModel: SizeFormModel) {
            self.sizeFormModel = sizeFormModel
            let model = Model(
                initialDouble: sizeFormModel.amount,
                initialUnit: sizeFormModel.amountUnit
            )
            _model = StateObject(wrappedValue: model)
        }
        
        class Model: ObservableObject {
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

extension SizeForm.AmountForm {
    
    var body: some View {
        NavigationStack {
            QuickForm(title: "Amount") {
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
        FormInlineDoneButton(disabled: model.shouldDisableDone) {
            Haptics.feedback(style: .rigid)
            sizeFormModel.amount = model.internalDouble
            sizeFormModel.amountUnit = model.internalUnit
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
            pickedUnit: model.internalUnit,
            includeServing: true,
            includeWeights: true,
            includeVolumes: true,
            sizes: fields.allSizes,
            allowAddSize: false,
            didPickUnit: { newUnit in
                withAnimation {
                    Haptics.feedback(style: .rigid)
                    model.internalUnit = newUnit
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
                Text(model.internalUnit.shortDescription)
                    .fontWeight(.semibold)
                Image(systemName: "chevron.up.chevron.down")
                    .imageScale(.small)
            }
            .foregroundColor(.accentColor)
            .padding(.horizontal, 15)
            .frame(height: 40)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.accentColor.opacity(
                        colorScheme == .dark ? 0.1 : 0.15
                    ))
            )
//            .animation(.none, value: model.internalUnit)
        }
        .contentShape(Rectangle())
    }
}
