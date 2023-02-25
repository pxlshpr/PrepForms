import SwiftUI
import VisionSugar
import SwiftHaptics
import FoodLabelScanner
import PrepDataTypes

extension Extractor {
    
    func showTextBoxesForCurrentAttribute() {
        setTextBoxes(
            attributeText: currentAttributeText,
            valueText: currentValueText,
            includeTappableTexts: state == .showingKeyboard
        )
    }
    
    func showTextBoxes(for attribute: Attribute) {
        guard let nutrient = extractedNutrients.first(where: { $0.attribute == attribute} ) else {
            return
        }
        setTextBoxes(
            attributeText: nutrient.attributeText,
            valueText: nutrient.valueText
        )
    }

    func setTextBoxes(
        attributeText: RecognizedText?,
        valueText: RecognizedText?,
        includeTappableTexts: Bool = false
    ) {
        var textBoxes: [TextBox] = []
        var texts: [RecognizedText] = []
        
        if let attributeText,
           attributeText.boundingBox != .zero
        {
            textBoxes.append(TextBox(
                boundingBox: attributeText.boundingBox,
                color: .accentColor,
                tapHandler: nil
            ))
            texts.append(attributeText)
        }
        
        var validValueText: RecognizedText? {
            guard let valueText,
                  valueText.boundingBox != attributeText?.boundingBox,
                  valueText.boundingBox != .zero
            else { return nil }
            
//            if includeTappableTexts, valueText.string.detectedValues.count > 1 {
//                return nil
//            }
            
            return valueText
        }
        
        if let validValueText {
            textBoxes.append(TextBox(
                boundingBox: validValueText.boundingBox,
                color: .accentColor,
                tapHandler: nil
            ))
            texts.append(validValueText)
        }

        self.textBoxes = textBoxes
        
        if includeTappableTexts {
            showTappableTextBoxesForCurrentAttribute()
        }
    }
    
    func showTappableTextBoxesForCurrentAttribute() {
        guard currentAttribute != nil, let scanResult else { return }
        let texts = scanResult.textsWithFoodLabelValues.filter { text in
            if !text.string.detectedValues.isEmpty {
                return true
            } else {
                return !self.textBoxes.contains(where: { $0.boundingBox == text.boundingBox })
            }
        }
        let textBoxes = texts.map { text in
            TextBox(
                id: text.id,
                boundingBox: text.boundingBox,
                color: .yellow,
                opacity: 0.3,
                tapHandler: { self.tappedText(text) }
            )
        }
        withAnimation {
            self.selectableTextBoxes = textBoxes
//            self.textBoxes.append(contentsOf: textBoxes)
        }
    }
    
    func hideTappableTextBoxesForCurrentAttribute() {
//        textBoxes = textBoxes.filter { $0.tapHandler == nil }
        self.selectableTextBoxes = []
    }

    func tappedText(_ text: RecognizedText) {
        guard let firstValue = text.firstFoodLabelValue, let currentAttribute, let currentNutrientIndex else {
            return
        }
        Haptics.feedback(style: .rigid)
        self.textFieldAmountString = firstValue.amount.cleanWithoutRounding
        
        let nonOptionalUnit: FoodLabelUnit
        if let valueUnit = firstValue.unit {
            nonOptionalUnit = valueUnit
        } else {
            nonOptionalUnit = currentAttribute.defaultUnit ?? .g
        }

        let valueWithUnit = FoodLabelValue(amount: firstValue.amount, unit: nonOptionalUnit)
        pickedAttributeUnit = nonOptionalUnit

        extractedNutrients[currentNutrientIndex].valueText = text
        extractedNutrients[currentNutrientIndex].value = valueWithUnit
        
        addCroppedImage(for: text)
        
        setTextBoxes(
            attributeText: currentAttributeText,
            valueText: text,
            includeTappableTexts: true
        )
    }
    
    func showColumnTextBoxes() {
        let textBoxes = extractedColumns.selectedColumnValueTexts.map {
            TextBox(
                boundingBox: $0.boundingBox,
                color: .accentColor,
                tapHandler: nil
            )
        }
        var selectableTextBoxes = extractedColumns.nonSelectedColumnValueTexts.map {
            TextBox(
                boundingBox: $0.boundingBox,
                color: .yellow,
                tapHandler: columnTextBoxTapHandler(for: $0)
            )
        }
        /// Filter out any selectable text boxes that have also been set for the standard text boxes
        selectableTextBoxes = selectableTextBoxes.filter { selectableTextBox in
            !textBoxes.contains(where: { $0.boundingBox == selectableTextBox.boundingBox })
        }
        
        self.textBoxes = textBoxes
        self.selectableTextBoxes = selectableTextBoxes
    }
    
    func columnTextBoxTapHandler(for text: RecognizedText) -> (() -> ())? {
        return { [weak self] in
            guard let self else { return }
            withAnimation(.interactiveSpring()) {
                Haptics.feedback(style: .soft)
                self.extractedColumns.toggleSelectedColumnIndex()
            }
            self.showColumnTextBoxes()
        }
    }
    
    var textBoxesForAllRecognizedTexts: [TextBox] {
        guard let textSet else { return [] }
        return textSet.texts.map {
            TextBox(
                id: $0.id,
                boundingBox: $0.boundingBox,
                color: .accentColor,
                opacity: 0.8,
                tapHandler: {}
            )
        }
    }
}
