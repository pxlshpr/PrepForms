import SwiftUI
import PrepDataTypes
import FoodLabelScanner
import SwiftHaptics
import SwiftUISugar
import PrepCoreDataStack

enum BiometricType {
    case restingEnergy
    case activeEnergy
    case sex
    case age
    case weight
    case leanBodyMass
    case fatPercentage
    case height
    
    var description: String {
        switch self {
        case .restingEnergy:
            return "Resting Energy"
        case .activeEnergy:
            return "Active Energy"
        case .sex:
            return "Sex"
        case .age:
            return "Age"
        case .weight:
            return "Weight"
        case .leanBodyMass:
            return "Lean Body Mass"
        case .fatPercentage:
            return "Fat Percentage"
        case .height:
            return "Height"
        }
    }
    
    var defaultUnit: BiometricUnit? {
        switch self {
        case .restingEnergy, .activeEnergy:
            return .energy(UserManager.energyUnit)
        case .weight, .leanBodyMass:
            return .weight(UserManager.weightUnit)
        case .height:
            return .height(UserManager.heightUnit)
        default:
            return nil
        }
    }
    
    var usesUnit: Bool {
        switch self {
        case .sex, .age, .fatPercentage:
            return false
        default:
            return true
        }
    }
}

enum BiometricUnit {
    case energy(EnergyUnit)
    case weight(WeightUnit)
    case height(HeightUnit)
    
    var description: String {
        switch self {
        case .energy(let energyUnit):
            return energyUnit.shortDescription
        case .weight(let weightUnit):
            return weightUnit.shortDescription
        case .height(let heightUnit):
            return heightUnit.shortDescription
        }
    }
    
    var energyUnit: EnergyUnit? {
        switch self {
        case .energy(let energyUnit):
            return energyUnit
        default:
            return nil
        }
    }
    var weightUnit: WeightUnit? {
        switch self {
        case .weight(let weightUnit):
            return weightUnit
        default:
            return nil
        }
    }
    var heightUnit: HeightUnit? {
        switch self {
        case .height(let heightUnit):
            return heightUnit
        default:
            return nil
        }
    }
}

struct BiometricValue {
    var amount: Double
    var unit: BiometricUnit?
}

struct BiometricValueForm: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @FocusState var isFocused: Bool
    
    @StateObject var model: Model
    @State var hasFocusedOnAppear: Bool = false
    @State var hasCompletedFocusedOnAppearAnimation: Bool = false

    class Model: ObservableObject {
        
        let type: BiometricType
        let initialValue: BiometricValue?
        let handleNewValue: (BiometricValue?) -> ()
        
        @Published var unit: BiometricUnit?
        @Published var internalTextfieldString: String = ""
        @Published var internalTextfieldDouble: Double? = nil
        
        init(type: BiometricType, initialValue: BiometricValue?, handleNewValue: @escaping (BiometricValue?) -> Void) {
            self.type = type
            self.initialValue = initialValue
            self.handleNewValue = handleNewValue
            
            if let initialValue {
                internalTextfieldDouble = initialValue.amount
                internalTextfieldString = initialValue.amount.cleanWithoutRounding
            }
            self.unit = initialValue?.unit ?? type.defaultUnit

        }
        
        var title: String {
            type.description
        }
        
        var shouldDisableDone: Bool {
            //TODO: Check validity, isDirty etc
            false
        }
        
        var value: BiometricValue? {
            guard let internalTextfieldDouble else { return nil }
            return BiometricValue(amount: internalTextfieldDouble, unit: unit)
        }
        
        var textFieldAmountString: String {
            //TODO: Force integer for age
            get { internalTextfieldString }
            set {
                guard !newValue.isEmpty else {
                    internalTextfieldDouble = nil
                    internalTextfieldString = newValue
                    return
                }
                guard let double = Double(newValue) else {
                    return
                }
                self.internalTextfieldDouble = double
                self.internalTextfieldString = newValue
            }
        }
    }
    
    init(
        type: BiometricType,
        initialValue: BiometricValue? = nil,
        handleNewValue: @escaping (BiometricValue?) -> ()
    ) {
        let model = Model(
            type: type,
            initialValue: initialValue,
            handleNewValue: handleNewValue
        )
        _model = StateObject(wrappedValue: model)
    }
    
    var placeholder: String {
        "Required"
    }
    
    var body: some View {
        NavigationStack {
            QuickForm(title: model.title) {
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
                    unitPickerButton
                }
                .frame(maxHeight: 50)
            }
            .padding(.leading, 20)
            doneButton
                .padding(.horizontal, 20)
        }
    }
    
    var doneButton: some View {
        FormInlineDoneButton(disabled: model.shouldDisableDone) {
            Haptics.successFeedback()
            model.handleNewValue(model.value)
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
            get: { model.textFieldAmountString },
            set: { newValue in
                withAnimation {
                    model.textFieldAmountString = newValue
                }
            }
        )

        return TextField(placeholder, text: binding)
            .focused($isFocused)
            .multilineTextAlignment(.leading)
            .font(binding.wrappedValue.isEmpty ? .body : .largeTitle)
            .keyboardType(.decimalPad)
            .frame(height: 50)
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
    
    var unitPickerButton: some View {
        
        func unitText(_ string: String) -> some View {
            Text(string)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal, 15)
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color(.tertiarySystemFill))
                )
        }
        
        func unitPicker(for type: BiometricType) -> some View {
            
            var unitLabel: some View {
                HStack(spacing: 2) {
                    Text(model.unit?.description ?? "")
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
            }
            
            let heightUnitBinding = Binding<HeightUnit>(
                get: { model.unit?.heightUnit ?? .cm },
                set: { newUnit in
                    withAnimation {
                        Haptics.feedback(style: .soft)
                        model.unit = .height(newUnit)
                    }
                }
            )

            let energyUnitBinding = Binding<EnergyUnit>(
                get: { model.unit?.energyUnit ?? .kcal },
                set: { newUnit in
                    withAnimation {
                        Haptics.feedback(style: .soft)
                        model.unit = .energy(newUnit)
                    }
                }
            )

            var energyPicker: some View {
                Picker(selection: energyUnitBinding, label: EmptyView()) {
                    ForEach(EnergyUnit.allCases, id: \.self) {
                        Text($0.description).tag($0)
                    }
                }
            }

            let weightUnitBinding = Binding<WeightUnit>(
                get: { model.unit?.weightUnit ?? .kg },
                set: { newUnit in
                    withAnimation {
                        Haptics.feedback(style: .soft)
                        model.unit = .weight(newUnit)
                    }
                }
            )

            var weightPicker: some View {
                Picker(selection: weightUnitBinding, label: EmptyView()) {
                    ForEach(WeightUnit.allCases, id: \.self) {
                        Text($0.description).tag($0)
                    }
                }
            }

            var heightPicker: some View {
                Picker(selection: heightUnitBinding, label: EmptyView()) {
                    ForEach(HeightUnit.allCases, id: \.self) {
                        Text($0.description).tag($0)
                    }
                }
            }

            @ViewBuilder
            var unitPicker: some View {
                switch type {
                case .restingEnergy, .activeEnergy:
                    energyPicker
                case .weight, .leanBodyMass:
                    weightPicker
                case .height:
                    heightPicker
                default:
                    EmptyView()
                }
            }
            
            return Menu {
                unitPicker
            } label: {
                unitLabel
            }
            .animation(.none, value: heightUnitBinding.wrappedValue)
            .animation(.none, value: energyUnitBinding.wrappedValue)
            .animation(.none, value: weightUnitBinding.wrappedValue)
            .contentShape(Rectangle())
            .simultaneousGesture(TapGesture().onEnded {
                Haptics.feedback(style: .soft)
            })
        }
        
        return Group {
            if model.type.usesUnit {
                unitPicker(for: model.type)
            } else {
                EmptyView()
            }
        }
    }
}
