import SwiftUI

extension AttributesLayer {
    
    func cell(for nutrient: ExtractedNutrient) -> some View {
        var isConfirmed: Bool { nutrient.isConfirmed }
        var isCurrentAttribute: Bool { extractor.currentAttribute == nutrient.attribute }
        var imageName: String {
            isConfirmed
//            ? "circle.inset.filled"
//            : "circle"
            ? "checkmark.square.fill"
            : "square.dashed"
        }

        var listRowBackground: some View {
            isCurrentAttribute
            ? (colorScheme == .dark
               ? Color(.tertiarySystemFill)
               : Color(.systemFill)
            )
            : .clear
        }
        
        var hstack: some View {
            var valueDescription: String {
                nutrient.value?.descriptionWithoutRounding ?? "Enter a value"
            }
            
            var textColor: Color {
                isConfirmed ? .secondary : .primary
            }
            
            var valueTextColor: Color {
                guard nutrient.value != nil else {
                    return Color(.tertiaryLabel)
                }
                return isConfirmed ? .secondary : .accentColor
//                return textColor
            }
            
            var shouldDisable: Bool {
                nutrient.value == nil
            }
            
            var checkBoxColor: Color {
//                shouldDisable ? Color(.quaternaryLabel) : .secondary
                shouldDisable ? Color(.quaternaryLabel) : (isConfirmed ? .secondary : .accentColor)
            }
            
            return HStack(spacing: 0) {
                Button {
                    tappedCell(for: nutrient.attribute)
                } label: {
                    HStack(spacing: 0) {
                        Text(nutrient.attribute.description)
                            .foregroundColor(textColor)
                        Spacer()
                    }
                }
                Button {
                    tappedCellValue(for: nutrient.attribute)
                } label: {
                    Text(valueDescription)
                        .monospacedDigit()
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundColor(valueTextColor)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .background(
                            Group {
                                if shouldDisable {
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .fill(Color(.tertiarySystemFill))
                                } else {
                                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                                        .fill(Color.accentColor.opacity(
                                            colorScheme == .dark ? 0.1 : 0.15
                                        ))
                                        .opacity(isConfirmed ? 0 : 1)
                                }
                            }
                        )
//                        .background(
//                            RoundedRectangle(cornerRadius: 5, style: .continuous)
//                                .fill(Color(.tertiarySystemFill))
//                                .opacity(isConfirmed ? 0 : 1)
//                        )
                }
                Button {
//                    actionHandler(.toggleAttributeConfirmation(nutrient.attribute))
                    extractor.toggleAttributeConfirmation(nutrient.attribute)
                } label: {
                    Image(systemName: imageName)
                        .foregroundColor(checkBoxColor)
//                        .padding(.horizontal, 15)
                        .frame(width: K.Cell.checkBoxButtonWidth)
                        .frame(maxHeight: .infinity)
                        .contentShape(Rectangle())
                }
                .disabled(shouldDisable)
            }
            .foregroundColor(textColor)
            .foregroundColor(.primary)
        }
        
        return hstack
        .listRowBackground(listRowBackground)
        .listRowInsets(.init(top: 0, leading: 25, bottom: 0, trailing: 0))
    }

}
