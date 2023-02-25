import SwiftUI
import SwiftHaptics
import FoodLabelScanner
import VisionSugar
import PrepDataTypes

extension AttributesLayer {
    
    func tappedActionButton() {
        if extractor.currentNutrientIsConfirmed {
//            withAnimation {
//                extractor.deleteCurrentAttribute()
//            }
            extractor.toggleAttributeConfirmationForCurrentAttribute()
        } else {
//            actionHandler(.confirmCurrentAttribute)
            extractor.confirmCurrentAttribute()
            if extractor.allNutrientsConfirmed {
                if extractor.state == .showingKeyboard {
                    resignFocusOfSearchTextField()
                }
                extractor.setAsAllConfirmed()
            } else {
                extractor.moveToNextUnconfirmedAttribute()
            }
        }
    }
    
    func tappedDismissKeyboard() {
        Haptics.feedback(style: .soft)
        resignFocusOfSearchTextField()
        withAnimation {
            if extractor.containsUnconfirmedAttributes {
                extractor.state = .awaitingConfirmation
            } else {
                extractor.state = .allConfirmed
            }
            hideBackground = false
        }
    }
    
    func tappedSuggestedValue(_ value: FoodLabelValue) {
        Haptics.feedback(style: .soft)
        extractor.setSuggestedValue(value)
    }
    
    func tappedValueButton() {
        Haptics.feedback(style: .soft)
        isFocused = true
        withAnimation {
            showKeyboardForCurrentAttribute()
        }
        extractor.showTappableTextBoxesForCurrentAttribute()
    }
    
    func tappedCell(for attribute: Attribute) {
        if attribute != extractor.currentAttribute {
//            actionHandler(.moveToAttribute(attribute))
            extractor.moveToAttribute(attribute)
        } else {
            extractor.deselectCurrentAttribute()
        }
    }
    
    func tappedCellValue(for attribute: Attribute) {
        if extractor.currentAttribute == attribute {
            tappedValueButton()
        } else {
//            actionHandler(.moveToAttribute(attribute))
            extractor.moveToAttribute(attribute)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                tappedValueButton()
            }
        }
    }
    
    func showTutorial() {
        guard !disableNextTutorialInvocation else {
            disableNextTutorialInvocation = false
            return
        }
        
        withAnimation {
            showingTutorial = true
        }
    }

    func tappedDismiss() {
        if extractor.state == .showingKeyboard {
            isFocused = false
        }
        extractor.dismiss()
    }
    
    func tappedDone() {
        extractor.tappedDone()
    }
    
    //MARK: - Helpers Actions
    
    func showKeyboardForCurrentAttribute() {
        extractor.state = .showingKeyboard
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                hideBackground = true
            }
        }
    }
    
    func resignFocusOfSearchTextField() {
        isFocused = false
        withAnimation {
            extractor.hideTappableTextBoxesForCurrentAttribute()
        }
    }
}
