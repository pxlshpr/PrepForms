import SwiftUI
import EmojiPicker
import SwiftHaptics
//import FoodLabelCamera
import FoodLabelScanner
//import MFPSearch
import Camera

extension FoodForm {
    var emojiPicker: some View {
        EmojiPicker(
            categories: [.foodAndDrink, .animalsAndNature],
            focusOnAppear: true,
            includeCancelButton: true
        ) { emoji in
            Haptics.successFeedback()
            fields.emoji = emoji
            showingEmojiPicker = false
        }
    }
    
    var barcodeScanner: some View {
        BarcodeScanner { barcodes, image in
            handleScannedBarcodes(barcodes, on: image)
        }
    }
}
