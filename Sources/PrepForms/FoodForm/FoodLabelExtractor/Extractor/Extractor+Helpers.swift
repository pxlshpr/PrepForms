import SwiftUI
import SwiftHaptics
import VisionSugar
import PrepDataTypes

extension Extractor {
    
    func dismiss() {
        Haptics.feedback(style: .soft)
        withAnimation {
            presentationState = .offScreen
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            NotificationCenter.default.post(name: .didDismissExtractor, object: nil)
//            self?.didDismiss?(nil)
        }
    }

    func setState(to newState: ExtractorState) {
        withAnimation {
            self.state = newState
        }
    }
    
    var allNutrientsConfirmed: Bool {
        extractedNutrients.allSatisfy({ $0.isConfirmed })
    }
    
    func setAsAllConfirmed(unsettingCurrentAttribute: Bool = true) {
        Haptics.successFeedback()
        withAnimation {
            state = .allConfirmed
            if unsettingCurrentAttribute {
                currentAttribute = nil
            }
            showTextBoxesForCurrentAttribute()
        }
    }
    
    func checkIfAllNutrientsAreConfirmed(unsettingCurrentAttribute: Bool = true) {
        if allNutrientsConfirmed {
            setAsAllConfirmed(unsettingCurrentAttribute: unsettingCurrentAttribute)
        } else {
            withAnimation {
                state = state == .showingKeyboard ? .showingKeyboard : .awaitingConfirmation
            }
        }
    }
    
    func zoomToNutrients() async {
        guard let imageSize = image?.size,
              let boundingBox = scanResult?.nutrientsBoundingBox(includeAttributes: true)
        else { return }
        
        let zoomBox = ZoomBox(
            boundingBox: boundingBox,
            animated: true,
            padded: true,
            imageSize: imageSize
        )

        await MainActor.run { [weak self] in
            guard let _ = self else { return }
            NotificationCenter.default.post(
                name: .zoomZoomableScrollView,
                object: nil,
                userInfo: [Notification.ZoomableScrollViewKeys.zoomBox: zoomBox]
            )
        }
    }
    
    func selectColumn(_ index: Int) {
        withAnimation {
            extractedColumns.selectedColumnIndex = index
        }
        showColumnTextBoxes()
    }
    
    func tappedClearButton() {
        textFieldAmountString = ""
    }
    
    var shouldShowClearButton: Bool {
        !textFieldAmountString.isEmpty
    }
    
    func sizeForCropping(for texts: [RecognizedText], in size: CGSize) -> CGSize? {
        
        guard let smallest = texts.textWithSmallestHeight else { return .zero }
        cprint("✂️ Smallest is '\(smallest.string)' \(smallest.rect)")
        
        /// We want the smallest text to be at least `15px` high, so find the ratio accordingly
        let height = (size.height * 15.0) / smallest.rect.height
        let ratio = min(height / size.height, 0.9)
        cprint("✂️ Height: \(height), Ratio is '\(ratio)")

        guard ratio < 1 else { return nil }
        
        return CGSizeMake(size.width * ratio, size.height * ratio)
    }
}

extension Array where Element == RecognizedText {
    var textWithSmallestHeight: RecognizedText? {
        self.sorted(by: { $0.boundingBox.height < $1.boundingBox.height }).first
    }
}
