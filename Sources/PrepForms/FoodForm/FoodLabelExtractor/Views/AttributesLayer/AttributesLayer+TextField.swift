import SwiftUI
import FoodLabelScanner
import PrepDataTypes
import SwiftHaptics

extension AttributesLayer {
    
    var textFieldContents: some View {
        ZStack {
            textFieldBackground
            HStack {
                textField
                clearButton
                unitPicker
            }
            .padding(.horizontal, K.textFieldHorizontalPadding)
        }
    }

    var textField: some View {
        let binding = Binding<String>(
            get: { extractor.textFieldAmountString },
            set: { newValue in
                withAnimation {
                    extractor.textFieldAmountString = newValue
                }
            }
        )

        return TextField("", text: binding)
            .focused($isFocused)
            .keyboardType(.decimalPad)
            .font(.system(size: 22, weight: .semibold, design: .default))
            .matchedGeometryEffect(id: "textField", in: namespace)
            .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { obj in
                if let textField = obj.object as? UITextField {
                    textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
                }
            }
    }
    
    var unitPicker: some View {
        
        func unitText(_ string: String) -> some View {
            Text(string)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal, 15)
                .frame(height: 35)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color(.tertiarySystemFill))
                )
        }

        let binding = Binding<FoodLabelUnit>(
            get: { extractor.pickedAttributeUnit },
            set: { newUnit in
                withAnimation {
                    Haptics.feedback(style: .soft)
                    extractor.pickedAttributeUnit = newUnit
                }
            }
        )

        func unitPicker(for nutrientType: NutrientType) -> some View {
            return Menu {
                Picker(selection: binding, label: EmptyView()) {
                    ForEach(nutrientType.supportedFoodLabelUnits, id: \.self) {
                        Text($0.description).tag($0)
                    }
                }
            } label: {
                HStack(spacing: 2) {
                    Text(extractor.pickedAttributeUnit.description)
                        .fontWeight(.semibold)
                    Image(systemName: "chevron.up.chevron.down")
                        .imageScale(.small)
                }
                .foregroundColor(.accentColor)
                .padding(.horizontal, 15)
                .frame(height: 35)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color(.tertiarySystemFill))
                )
            }
            .animation(.none, value: extractor.pickedAttributeUnit)
            .contentShape(Rectangle())
            .simultaneousGesture(TapGesture().onEnded {
                Haptics.feedback(style: .soft)
            })
        }
        
        return Group {
            if let attribute = extractor.currentAttribute {
                if attribute == .energy {
                    Picker("", selection: binding) {
                        ForEach(
                            [FoodLabelUnit.kcal, FoodLabelUnit.kj],
                            id: \.self
                        ) { unit in
                            Text(unit.description).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                } else if let nutrientType = attribute.nutrientType {
                    if nutrientType.supportedFoodLabelUnits.count > 1 {
                        unitPicker(for: nutrientType)
                    } else {
                        unitText(nutrientType.supportedFoodLabelUnits.first?.description ?? "g")
                    }
                } else {
                    unitText("g")
                }
            }
        }
    }
    
    @ViewBuilder
    var clearButton: some View {
        Button {
            extractor.tappedClearButton()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 20))
                .symbolRenderingMode(.palette)
                .foregroundStyle(
                    Color(.tertiaryLabel),
                    Color(.tertiarySystemFill)
                )

        }
        .opacity(extractor.shouldShowClearButton ? 1 : 0)
        .buttonStyle(.borderless)
        .padding(.trailing, 5)
    }

    //MARK: - Helpers
    
    var textFieldBackground: some View {
        var height: CGFloat { K.topButtonHeight }
//        var xOffset: CGFloat { 0 }
        
        var foregroundStyle: some ShapeStyle {
//            Material.thinMaterial
            expandedTextFieldColor
//            Color(.secondarySystemFill)
        }
        var background: some View { Color.clear }
        
        return RoundedRectangle(cornerRadius: K.topButtonCornerRadius, style: .circular)
            .foregroundStyle(foregroundStyle)
            .background(background)
            .frame(height: height)
//            .frame(width: width)
//            .offset(x: xOffset)
    }

    var keyboardColor: Color {
        colorScheme == .light ? Color(hex: K.ColorHex.keyboardLight) : Color(hex: K.ColorHex.keyboardDark)
    }
    
    var expandedTextFieldColor: Color {
        colorScheme == .light ? Color(hex: K.ColorHex.searchTextFieldLight) : Color(hex: K.ColorHex.searchTextFieldDark)
    }
}
