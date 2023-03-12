import SwiftUI
import PrepDataTypes
import FoodLabelScanner
import SwiftHaptics
import SwiftUISugar
import PrepCoreDataStack

struct BiometricValueForm: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @FocusState var isFocused: Bool
    @FocusState var isSecondaryFocused: Bool

    @StateObject var model: Model
    @State var hasFocusedOnAppear: Bool = false
    @State var hasCompletedFocusedOnAppearAnimation: Bool = false
    
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
        ""
//        "Required"
    }
    
    var body: some View {
        NavigationStack {
            QuickForm(title: model.title) {
                textFieldSection
            }
            .onChange(of: isFocused, perform: focusChanged)
            .onChange(of: isSecondaryFocused, perform: focusChanged)
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
                        .layoutPriority(model.usesSecondaryUnit ? 1 : 0)
                    optionalSecondaryField
                }
                .frame(maxHeight: 50)
            }
            .padding(.leading, 20)
            doneButton
                .padding(.horizontal, 20)
        }
    }
    
    @ViewBuilder
    var optionalSecondaryField: some View {
        if model.usesSecondaryUnit {
            Group {
                secondaryTextField
                secondaryUnitPickerButton
            }
        }
    }
    
    var doneButton: some View {
        FormInlineDoneButton(disabled: model.shouldDisableDone) {
            Haptics.successFeedback()
            model.handleNewValue(model.value)
            dismiss()
        }
    }
    
    func focusChanged(_ newValue: Bool) {
        if !isFocused && !isSecondaryFocused {
            dismiss()
        }
    }
    
    var secondaryTextField: some View {
        let binding = Binding<String>(
            get: { model.secondaryTextFieldString },
            set: { newValue in
                withAnimation {
                    model.secondaryTextFieldString = newValue
                }
            }
        )

        return TextField(placeholder, text: binding)
            .focused($isSecondaryFocused)
            .multilineTextAlignment(.leading)
            .font(binding.wrappedValue.isEmpty ? .body : .title3)
            .keyboardType(.decimalPad)
            .frame(height: 50)
            .scrollDismissesKeyboard(.never)
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

        return TextField(placeholder, text: binding)
            .focused($isFocused)
            .multilineTextAlignment(.leading)
            .font(binding.wrappedValue.isEmpty ? .body : .largeTitle)
            .keyboardType(model.keyboardType)
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

    var secondaryUnitPickerButton: some View {
        HStack(spacing: 2) {
            Text(model.secondaryUnitString ?? "")
                .fontWeight(.semibold)
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 15)
        .frame(height: 40)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color(.tertiarySystemFill))
        )
    }
    
    var unitPickerButton: some View {
        
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

            let bodyMassUnitBinding = Binding<BodyMassUnit>(
                get: { model.unit?.bodyMassUnit ?? .kg },
                set: { newUnit in
                    withAnimation {
                        Haptics.feedback(style: .soft)
                        model.unit = .bodyMass(newUnit)
                    }
                }
            )

            var energyUnitPicker: some View {
                Picker(selection: energyUnitBinding, label: EmptyView()) {
                    ForEach(EnergyUnit.allCases, id: \.self) {
                        Text($0.shortDescription).tag($0)
                    }
                }
            }

            var bodyMassUnitPicker: some View {
                Picker(selection: bodyMassUnitBinding, label: EmptyView()) {
                    ForEach(BodyMassUnit.allCases, id: \.self) {
                        Text($0.shortDescription).tag($0)
                    }
                }
            }

            var heightUnitPicker: some View {
                Picker(selection: heightUnitBinding, label: EmptyView()) {
                    ForEach(HeightUnit.allCases, id: \.self) {
                        Text($0.shortDescription).tag($0)
                    }
                }
            }

            @ViewBuilder
            var unitPicker: some View {
                switch type {
                case .restingEnergy, .activeEnergy:
                    energyUnitPicker
                case .weight, .leanBodyMass:
                    bodyMassUnitPicker
                case .height:
                    heightUnitPicker
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
            .animation(.none, value: bodyMassUnitBinding.wrappedValue)
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

public struct BiometricValueFormPreview: View {
    
    @State var showingForm = false
    
    public init() { }
    
    public var body: some View {
        Button("Present") {
            showingForm = true
        }
        .sheet(isPresented: $showingForm) { valueForm }
    }
    
    var valueForm: some View {
        BiometricValueForm(type: .weight) { _ in
            
        }
    }
}
