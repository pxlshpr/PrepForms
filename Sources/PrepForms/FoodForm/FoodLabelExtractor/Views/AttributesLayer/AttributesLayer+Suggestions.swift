import SwiftUI
import PrepDataTypes
import SwiftHaptics

extension AttributesLayer {
    
    var suggestionsLayer: some View {
        
        var valueSuggestions: [FoodLabelValue] {
            guard let text = extractor.currentValueText, let attribute = extractor.currentAttribute else {
                return []
            }
            let values = text.allDetectedFoodLabelValues(for: attribute)
            /// Filter out values that are currently being displayed
            return values.filter {
                $0.amount != extractor.internalTextfieldDouble
            }
        }
        
        var backgroundColor: Color {
//                Color(.tertiarySystemFill)
            colorScheme == .dark ? Color(hex: "737373") : Color(hex: "EBEDF0")
        }
        
        var textColor: Color {
//                .primary
            .secondary
        }
        
        var scrollView: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack {
                    ForEach(valueSuggestions, id: \.self) { value in
                        Button {
                            tappedSuggestedValue(value)
                        } label: {
                            Text(value.descriptionWithoutRounding)
                                .foregroundColor(textColor)
                                .padding(.horizontal, 15)
                                .frame(height: K.suggestionsBarHeight)
                                .background(
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .foregroundColor(backgroundColor)
                                )
                        }
                    }
                }
                .padding(.horizontal, 10)
            }
        }
        
        var noTextBoxPrompt: String {
            "Enter value or select from image."
//            model.textFieldAmountString.isEmpty
//            ? "or select a detected text from the image."
//            : "Select a detected text from the image."
        }
        
        var keyboardDismissButton: some View {
            Button {
                tappedDismissKeyboard()
            } label: {
                Image(systemName: "keyboard.chevron.compact.down.fill")
                    .font(.system(size: 18, weight: .medium, design: .default))
//                    .foregroundColor(colorScheme == .dark ? .white : .secondary)
                    .foregroundColor(.secondary)
                    .frame(width: K.topButtonWidth)
                    .frame(height: K.topButtonHeight)
//                    .background(
//                        RoundedRectangle(cornerRadius: K.topButtonCornerRadius, style: .continuous)
//                            .foregroundStyle(Color(.secondarySystemFill))
//                    )
                    .contentShape(Rectangle())
            }
        }
        
        return Group {
            HStack {
                if valueSuggestions.isEmpty {
                    Text(noTextBoxPrompt)
                        .foregroundColor(Color(.tertiaryLabel))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                } else {
                    scrollView
                }
                keyboardDismissButton
                    .padding(.trailing, K.topButtonsHorizontalPadding)
            }
        }
        .frame(height: K.suggestionsBarHeight)
//        .background(.green)
        .padding(.bottom, K.keyboardHeight + 2)
    }

}
