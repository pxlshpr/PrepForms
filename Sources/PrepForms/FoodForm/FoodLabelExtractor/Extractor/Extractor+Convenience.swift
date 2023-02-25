import SwiftUI
import PrepDataTypes
import VisionSugar
import FoodLabelScanner

extension Extractor {
    var textFieldAmountString: String {
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
    
    var leftColumnTitle: String {
        guard let scanResult else { return "" }
        return scanResult.headerTitle1
    }

    var rightColumnTitle: String {
        guard let scanResult else { return "" }
        return scanResult.headerTitle2
    }

    var currentUnit: FoodLabelUnit {
        currentNutrient?.value?.unit ?? .g
    }

    var currentValue: FoodLabelValue? {
        currentNutrient?.value
    }
    
    var shouldShowAttributesLayer: Bool {
        !dismissState.shouldHideUI
//        && !transitionState.isTransitioning
    }
    
    var currentAmountString: String {
        guard let amount = currentNutrient?.value?.amount else { return "" }
        return amount.cleanWithoutRounding
    }

    var currentNutrient: ExtractedNutrient? {
        guard let currentAttribute else { return nil }
        return extractedNutrients.first(where: { $0.attribute == currentAttribute })
    }
    
    var currentAttributeText: RecognizedText? {
        guard let currentNutrient else { return nil }
        return currentNutrient.attributeText
    }
    
    var currentValueText: RecognizedText? {
        guard let currentNutrient else { return nil }
        return currentNutrient.valueText
    }
    
    var currentNutrientIndex: Int? {
        guard let currentAttribute else { return nil }
        return extractedNutrients.firstIndex(where: { $0.attribute == currentAttribute })
    }
    
    var currentUnitString: String {
        guard let unit = currentNutrient?.value?.unit else { return "" }
        return unit.description
    }
    
    var currentNutrientIsConfirmed: Bool {
        currentNutrient?.isConfirmed == true
    }
    
    var nextUnconfirmedAttribute: Attribute? {
        nextUnconfirmedAttribute(to: currentAttribute)
    }

    var containsUnconfirmedAttributes: Bool {
        extractedNutrients.contains(where: { !$0.isConfirmed })
    }

    /// Returns the next element to `attribute` in `nutrients`,
    /// cycling back to the first once the end is reached.
    func nextUnconfirmedAttribute(to attribute: Attribute? = nil) -> Attribute? {
        let index: Int
        if let currentAttributeIndex = extractedNutrients.firstIndex(where: { $0.attribute == attribute }) {
            index = currentAttributeIndex
        } else {
            index = 0
        }
        
        /// Make sure we only loop once around the nutrients
        let maxNumberOfHops = extractedNutrients.count
        var numberOfHops = 0
        var indexToCheck = index >= extractedNutrients.count - 1 ? 0 : index + 1
        while numberOfHops < maxNumberOfHops {
            if !extractedNutrients[indexToCheck].isConfirmed {
                return extractedNutrients[indexToCheck].attribute
            }
            indexToCheck += 1
            if indexToCheck >= extractedNutrients.count - 1 {
                indexToCheck = 0
            }
            numberOfHops += 1
        }
        return nil
    }    
}

extension Extractor {
    
    var allTexts: [RecognizedText] {
        scanResult?.texts ?? []
//        scanResult?.textsWithFoodLabelValues ?? []
    }
    
    
    var textsToCrop: [RecognizedText] {
        guard let scanResult else { return [] }
        var texts: [RecognizedText] = []
        
        func appendText(_ text: RecognizedText?) {
            guard let text, !texts.contains(text) else { return }
            texts.append(text)
        }
        
        for nutrient in extractedNutrients {
            appendText(nutrient.attributeText)
            appendText(nutrient.valueText)
        }
        
        for text in scanResult.headerTexts {
            appendText(text)
        }

        for text in scanResult.servingTexts {
            appendText(text)
        }

        return texts
    }

    var textsToCrop_legacy: [RecognizedText] {
        let texts = extractedNutrients.compactMap {
            $0.valueText
        }
        return texts
    }

    var extractorOutput: ExtractorOutput? {
        guard let scanResult, let image else { return nil }
        return ExtractorOutput(
            scanResult: scanResult,
            extractedNutrients: extractedNutrients,
            image: image,
            croppedImages: allCroppedImages,
            selectedColumnIndex: extractedColumns.selectedColumnIndex
        )
    }
}

extension Extractor {
    var shouldHideOffScreen: Bool {
        presentationState == .offScreen
    }
    
    var imageOffset: CGFloat {
        guard let lastContentOffset else { return 0 }
        return lastContentOffset.y
    }
    
    var yOffset: CGFloat {
        shouldHideOffScreen
        ? UIScreen.main.bounds.height + imageOffset
        : 0
    }
    
    var imagePaddingTop: CGFloat {
        dismissState.shouldShrinkImage
        ? K.Collapse.imageTopPadding + K.topBarHeight
        : 0
    }
    
    var imagePaddingTrailing: CGFloat {
        dismissState.shouldShrinkImage
        ? UIScreen.main.bounds.width - K.Collapse.leftPadding
        : 0
    }

    var croppedImagesPaddingTop: CGFloat {
        dismissState == .shrinkingCroppedImages
        ? K.Collapse.nutrientsTopPadding - K.topBarHeight
        : 0
    }
    
    var croppedImagesPaddingTrailing: CGFloat {
        dismissState == .shrinkingCroppedImages
        ? UIScreen.main.bounds.width - K.Collapse.leftPadding
        : 0
    }

    var croppedImagesScale: CGFloat {
        dismissState == .shrinkingCroppedImages ? 0 : 1
    }
    
    var imageScale: CGFloat {
        dismissState.shouldShrinkImage ? 0 : 1
    }
}

func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
    let size = image.size
   
   let widthRatio  = targetSize.width  / size.width
   let heightRatio = targetSize.height / size.height
   
   // Figure out what our orientation is, and use that to form the rectangle
   var newSize: CGSize
   if(widthRatio > heightRatio) {
       newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
   } else {
       newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
   }
   
   // This is the rect that we've calculated out and this is what is actually used below
   let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
   
   // Actually do the resizing to the rect using the ImageContext stuff
   UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
   image.draw(in: rect)
   let newImage = UIGraphicsGetImageFromCurrentImageContext()
   UIGraphicsEndImageContext()
   
   return newImage!
}
