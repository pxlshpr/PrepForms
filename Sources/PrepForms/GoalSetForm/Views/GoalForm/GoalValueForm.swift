import SwiftUI
import SwiftUISugar
import SwiftHaptics
import PrepDataTypes

struct GoalValueForm: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @FocusState var isFocused: Bool
    
    @State var hasFocusedOnAppear: Bool = false
    @State var hasCompletedFocusedOnAppearAnimation: Bool = false

    @StateObject var model: Model
    
    @State var showingUnitPicker: Bool = false
    
    let handleNewValue: (Double?) -> ()
    let side: GoalForm.Side
    
    init(
        goalModel: GoalModel,
        side: GoalForm.Side,
        value: Double?,
        handleNewValue: @escaping (Double?) -> ()
    ) {
        self.side = side
        self.handleNewValue = handleNewValue
        let model = Model(
            initialDouble: value,
            goalModel: goalModel
        )
        _model = StateObject(wrappedValue: model)
    }
    
    class Model: ObservableObject {
        let goalModel: GoalModel
        let initialDouble: Double?
        let initialType: GoalType
        @Published var internalString: String = ""
        @Published var internalDouble: Double? = nil
        @Published var unitStrings: (String, String?)

        init(initialDouble: Double?, goalModel: GoalModel) {
            self.initialDouble = initialDouble
            self.internalDouble = initialDouble
            self.internalString = initialDouble?.cleanAmount ?? ""
            self.goalModel = goalModel
            
            self.unitStrings = goalModel.unitStrings
            self.initialType = goalModel.type
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
            if initialType != goalModel.type {
                return false
            }
            
            if initialDouble == internalDouble {
                return true
            }

            return false
        }
    }
    
    var title: String {
        guard !model.goalModel.type.isSingleBounded else {
            return "Target"
        }
        return side == .left ? "Minimum Target" : "Maximum Target"
    }
    
    var body: some View {
        NavigationStack {
            QuickForm(title: title) {
                textFieldSection
            }
        }
        .presentationDetents([.height(140)])
        .presentationDragIndicator(.hidden)
        .sheet(isPresented: $showingUnitPicker) { unitPicker }
        .onChange(of: isFocused, perform: isFocusedChanged)
        .onChange(of: model.goalModel.type, perform: typeChanged)
    }
    
    func typeChanged(_ newType: GoalType) {
        model.unitStrings = model.goalModel.unitStrings
    }
    
    var unitPicker: some View {
        GoalUnitPicker(model: model.goalModel)
    }
    
    var textFieldSection: some View {
        HStack(spacing: 0) {
            FormStyledSection(horizontalOuterPadding: 0) {
                HStack {
                    textField
                    unitButton
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
    
    var unitButton: some View {
        
        var isEnabled: Bool {
            model.goalModel.shouldShowUnitPicker
        }
        
        var foregroundColor: Color {
            isEnabled
            ? .accentColor
            : .secondary
        }
        
        var label: some View {
            HStack {
                VStack {
                    Text(model.unitStrings.0)
                        .fontWeight(.semibold)
                    if let bottomString = model.unitStrings.1 {
                        Text(bottomString)
                            .fontWeight(.medium)
                            .opacity(0.75)
                    }
                }
                if isEnabled {
                    Image(systemName: "chevron.up.chevron.down")
                }
            }
            .foregroundColor(foregroundColor)
            .padding(.vertical, 15)
            .padding(.horizontal, 15)
            .frame(minHeight: 40)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(
                        foregroundColor
                            .opacity(colorScheme == .dark ? 0.1 : 0.15)
                    )
            )
            .fixedSize(horizontal: true, vertical: false)
        }
        
        return Button {
            Haptics.feedback(style: .soft)
            showingUnitPicker = true
        } label: {
            label
        }
        .disabled(!isEnabled)
    }
}

extension GoalModel {
    var shouldShowUnitPicker: Bool {
        !(self.goalSetType == .meal && self.type.isEnergy)
    }
}
