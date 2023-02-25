import SwiftUI

extension AttributesLayer {
    var currentAttributeRow: some View {
        @ViewBuilder
        var editButton: some View {
            if extractor.state.showsEditButton {
                HStack {
                    Spacer()
                    EditButton()
                        .padding(.trailing, 20)
                }
            }
        }
        
        return Group {
            if extractor.currentAttribute == nil {
                ZStack {
                    statusMessage
                    editButton
                }
                .transition(
                    .move(edge: .trailing)
                    .combined(with: .opacity)
                )
            } else {
                HStack(spacing: K.topButtonsHorizontalPadding) {
                    if extractor.state == .showingKeyboard {
                        textFieldContents
                    } else {
                        attributeButton
                        valueButton
                    }
                    actionButton
                }
                .transition(.move(edge: .leading))
            }
        }
    }

    var attributeButton: some View {
        var foregroundColor: Color {
            extractor.currentNutrientIsConfirmed
            ? .secondary
            : .primary
        }
        
        return Button {
            tappedValueButton()
        } label: {
            Text(extractor.currentAttribute?.description ?? "")
                .matchedGeometryEffect(id: "attributeName", in: namespace)
//                .font(.title3)
                .font(.system(size: 22, weight: .semibold, design: .default))
//                .foregroundColor(.primary)
                .foregroundColor(foregroundColor)
                .minimumScaleFactor(0.2)
                .lineLimit(2)
                .foregroundColor(.primary)
                .padding(.horizontal)
                .frame(maxWidth: .infinity)
                .frame(height: K.topButtonHeight)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .foregroundStyle(Color(.quaternarySystemFill))
                        .shadow(color: Color(.black).opacity(0.2), radius: 3, x: 0, y: 3)
                        .opacity(0)
                )
                .contentShape(Rectangle())
        }
    }
    
    var valueButton: some View {
        var amountColor: Color {
//            Color.primary
            Color.accentColor
        }
        
        var unitColor: Color {
//            Color.secondary
            Color.accentColor.opacity(0.7)
        }
        
        var backgroundStyle: some ShapeStyle {
            Color(.secondarySystemFill).gradient
        }
        
        return Button {
            tappedValueButton()
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                if extractor.currentAmountString.isEmpty {
                    Image(systemName: "keyboard")
                } else {
                    Text(extractor.currentAmountString)
//                        .foregroundColor(amountColor)
                        .matchedGeometryEffect(id: "textField", in: namespace)
                    Text(extractor.currentUnitString)
//                        .foregroundColor(unitColor)
                        .font(.system(size: 18, weight: .medium, design: .default))
                }
            }
            .foregroundColor(.white)
            .font(.system(size: 22, weight: .semibold, design: .default))
            .padding(.horizontal)
            .frame(height: K.topButtonHeight)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.accentColor.gradient)
//                ZStack {
//                    RoundedRectangle(cornerRadius: 12, style: .continuous)
//                        .fill(colorScheme == .light ? Color(.secondarySystemGroupedBackground) : Color(hex: "2C2C2E"))
//                        .opacity(0.5)
//                    RoundedRectangle(cornerRadius: 12, style: .continuous)
//                        .fill(Color.accentColor.opacity(
//                            colorScheme == .dark ? 0.1 : 0.15
//                        ))
//                }
            )
//            .background(
//                RoundedRectangle(cornerRadius: 12, style: .continuous)
//                    .foregroundStyle(backgroundStyle)
////                    .shadow(color: Color(.black).opacity(0.2), radius: 3, x: 0, y: 3)
//            )
            .contentShape(Rectangle())
        }
    }
    
    var actionButton: some View {
        var shouldDisable: Bool {
            extractor.currentValue == nil
            && extractor.internalTextfieldDouble == nil
//            guard let currentNutrient = extractor.currentNutrient else { return true }
//            if let textFieldDouble = extractor.internalTextfieldDouble {
//                if textFieldDouble != currentNutrient.value?.amount {
//                    return false
//                }
//                if extractor.pickedAttributeUnit != currentNutrient.value?.unit {
//                    return false
//                }
//            }
//            return currentNutrient.isConfirmed
        }
        
        var isConfirmed: Bool {
            extractor.currentNutrientIsConfirmed
        }
        var imageName: String {
            isConfirmed
            ? "checkmark.square.fill" /// "trash"
            : "square.dashed"
        }

        var background: some View {
            
            var color: Color {
                isConfirmed || shouldDisable
                ? Color(.secondarySystemFill)
                : .accentColor
            }
            
            return RoundedRectangle(cornerRadius: K.topButtonCornerRadius, style: .continuous)
                .foregroundStyle(color.gradient)
        }
        
        var foregroundColor: Color {
            isConfirmed
            ? .primary
//            ? (
//                colorScheme == .dark
//                ? shouldDisable ? Color(.tertiaryLabel) : .white
//                : shouldDisable ? Color(.quaternaryLabel) : .secondary
//            )
            : (shouldDisable ? .secondary : .white)
//            ? shouldDisable ? Color(.tertiaryLabel) : .accentColor
//            : shouldDisable ? Color(.quaternaryLabel) : .accentColor
        }
        
        return Button {
            tappedActionButton()
        } label: {
            Image(systemName: imageName)
                .font(.system(size: 22, weight: .semibold, design: .default))
                .foregroundColor(foregroundColor)
                .frame(width: K.topButtonWidth)
                .frame(height: K.topButtonHeight)
                .background(background)
                .contentShape(Rectangle())
        }
        .disabled(shouldDisable)
        .animation(.interactiveSpring(), value: shouldDisable)
    }

    var statusMessage: some View {
        var string: String {
            switch extractor.state {
            case .awaitingColumnSelection:
                return "Select a Column"
            case .allConfirmed:
                return "All Marked as Correct"
            default:
                return "Confirm Nutrients"
            }
        }
        
        var foregroundColor: Color {
            switch extractor.state {
            case .allConfirmed:
                return .secondary
            default:
                return .primary
            }
        }
        
        var showInfoButton: Bool {
            switch extractor.state {
            case .awaitingColumnSelection, .allConfirmed:
                return false
            default:
                return true
            }
        }
        
        var label: some View {
            HStack {
                Text(string)
                    .font(.system(size: 18, weight: .medium, design: .default))
                    .foregroundColor(foregroundColor)
                if showInfoButton {
                    Image(systemName: "info.circle")
                }
            }
            .padding(.horizontal)
            .frame(height: K.topButtonHeight)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .foregroundStyle(Color(.tertiarySystemFill))
            )
            .contentShape(Rectangle())
        }
        var button: some View {
            Button {
                showTutorial()
            } label: {
                label
            }
        }
        
        return Group {
            if extractor.state == .allConfirmed {
                label
            } else {
                button
            }
        }
    }
}
