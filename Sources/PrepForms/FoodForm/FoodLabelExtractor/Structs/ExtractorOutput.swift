import UIKit
import VisionSugar
import FoodLabelScanner

public struct ExtractorOutput {
    public let scanResult: ScanResult
    public let extractedNutrients: [ExtractedNutrient]
    public let image: UIImage
    public let croppedImages: [RecognizedText : UIImage]
    public let selectedColumnIndex: Int
}
