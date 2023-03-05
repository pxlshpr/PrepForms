import SwiftUI
import SwiftUISugar
import FoodLabelScanner
import PhotosUI
import MFPScraper
import VisionSugar

extension FoodForm {
    public class Sources: ObservableObject {
        
        public static var shared = Sources()
        
        @Published var canBePublished: Bool = false

        @Published var imageModels: [ImageModel] = []
        @Published var imageSetStatus: ImageSetStatus = .loading()
        @Published var linkInfo: LinkInfo? = nil

        @Published var selectedPhotos: [PhotosPickerItem] = []

        var presentingImageIndex: Int = 0
        
        var didScanAllPickedImages: (() -> ())? = nil
        
        let id = UUID()
        
        public init() {
        }
                
        /// Reset this by recreating what it would be with a fresh call to `init()` (for reuse as we have one `@StateObject` in the entire app
        public func reset() {
            canBePublished = false

            imageModels = []
            imageSetStatus = .loading()
            linkInfo = nil

            selectedPhotos = []

            presentingImageIndex = 0
            
            didScanAllPickedImages = nil
            
//            autoFillHandler = nil
        }
    }
}

extension FoodForm.Sources {
    
    func add(_ image: UIImage, with scanResult: ScanResult) {
        let imageModel = ImageModel(image: image, scanResult: scanResult, delegate: self)
        addImageModel(imageModel)
    }
    
    func selectedPhotosChanged(to items: [PhotosPickerItem]) {
        for item in items {
            let imageModel = ImageModel(photosPickerItem: item, delegate: self)
            imageModels.append(imageModel)
        }
        updateCanBePublished()
        selectedPhotos = []
    }
    
    var numberOfSources: Int {
        imageModels.count + (linkInfo != nil ? 1 : 0)
    }
    
    func updateCanBePublished() {
        withAnimation {
            canBePublished = numberOfSources > 0
        }
    }
    
    func updateImageSetStatusToScanned() {
        imageSetStatus = .scanned(
            numberOfImages: imageModels.count,
            counts: DataPointsCount(total: 0, autoFilled: 0, selected: 0, barcodes: 0) /// do this
        )
    }
    
    /**
     This is used to know which `ImageModel`s should be discarded when the user dismisses the column picker—by setting a flag in the `ImageModel` that marks it as completed.
     
     As this only gets called when the actual processing is complete, those without the flag set will be discarded.
     */
    func markAllImageModelsAsProcessed() {
        for i in imageModels.indices {
            imageModels[i].isProcessed = true
        }
    }
    
    func removeUnprocessedImageModels() {
        imageModels.removeAll(where: { !$0.isProcessed })
    }
    
    func removeBarcodePayload(_ string: String) {
        /// Remove the `RecognizedBarcode` from all `ImageModel`s
        for i in imageModels.indices {
            imageModels[i].recognizedBarcodes.removeAll(where: { $0.string == string })
        }
        
        /// Now remove the redundant `ImageModel`s we may have (those that were associated with the scanned barcode and have no other used barcodes remaining in it)
        imageModels.removeAll(where: { $0.scanResult == nil && $0.recognizedBarcodes.isEmpty })
    }
}

extension FoodForm.Sources {
    
    func addLink(_ linkInfo: LinkInfo) {
        self.linkInfo = linkInfo
        withAnimation {
            updateCanBePublished()
        }
    }
    func removeLink() {
        linkInfo = nil
        withAnimation {
            updateCanBePublished()
        }
    }
    
    func removeImage(at index: Int) {
        guard index < imageModels.count else {
            return
        }
        imageModels.remove(at: index)
        withAnimation {
            updateCanBePublished()
        }
    }
    
    func addImageModel(_ imageModel: ImageModel) {
        imageModels.append(imageModel)
        withAnimation {
            updateCanBePublished()
        }
    }
    
}

//MARK: - Convenience
extension FoodForm.Sources {
    
    func id(forImageAtIndex index: Int) -> UUID? {
        guard imageModels.indices.contains(index) else {
            return nil
        }
        return imageModels[index].id
    }
    
    var allScanResults: [ScanResult] {
        imageModels.compactMap { $0.scanResult }
    }

    /// Returns how many images can still be added to this food
    var availableImagesCount: Int {
        max(5 - imageModels.count, 0)
    }
    
    var isEmpty: Bool {
        imageModels.isEmpty && linkInfo == nil
    }
    
    var pluralS: String {
        availableImagesCount == 1 ? "" : "s"
    }
    
    func croppedImage(for fill: Fill) async -> UIImage? {
        guard let resultId = fill.imageId,
              let boundingBoxToCrop = fill.boundingBoxToCrop,
              let image = image(for: resultId)
        else {
            return nil
        }
        
        return await image.cropped(boundingBox: boundingBoxToCrop)
    }
    
    func image(for id: UUID) -> UIImage? {
        for imageModel in imageModels {
            if imageModel.id == id {
//            if imageModel.scanResult?.id == scanResultId {
                return imageModel.image
            }
        }
        return nil
    }
}

//MARK: - ImageModelDelegate
extension FoodForm.Sources: ImageModelDelegate {
    
    func imageDidFinishScanning(_ imageModel: ImageModel) {
        guard !imageSetStatus.isScanned else {
            return
        }
        
        if imageModels.allSatisfy({ $0.status == .scanned }) {
            didScanAllPickedImages?()
        }
    }

    func imageDidStartScanning(_ imageModel: ImageModel) {
        withAnimation {
            self.imageSetStatus = .scanning(numberOfImages: imageModels.count)
        }
    }

    func imageDidFinishLoading(_ imageModel: ImageModel) {
        withAnimation {
            self.imageSetStatus = .scanning(numberOfImages: imageModels.count)
        }
    }
}

import VisionSugar

//MARK: - Available Texts
extension FoodForm.Sources {
    
    /**
     Returns true if there is at least one available (unused`RecognizedText` in all the `ScanResult`s that is compatible with the `fieldValue`
     */
    func hasAvailableTexts(for fieldValue: FieldValue) -> Bool {
        imageModels.contains(where: { $0.scanResult != nil })
        
        //TODO: Bring this back, we're currently rudimentarily returning true if we have any ScanResults
//        !availableTexts(for: fieldValue).isEmpty
    }
    
    func availableTexts(for fieldValue: FieldValue) -> [RecognizedText] {
        var availableTexts: [RecognizedText] = []
        for imageModel in imageModels {
            let texts = fieldValue.usesValueBasedTexts ? imageModel.textsWithFoodLabelValues : imageModel.texts
//            let filtered = texts.filter { isNotUsingText($0) }
            availableTexts.append(contentsOf: texts)
        }
        return availableTexts
    }

//    func isNotUsingText(_ text: RecognizedText) -> Bool {
//        fieldValueUsing(text: text) == nil
//    }
//    /**
//     Returns the `fieldValue` (if any) that is using the `RecognizedText`
//     */
//    func fieldValueUsing(text: RecognizedText) -> FieldValue? {
//        allFieldValues.first(where: {
//            $0.fill.uses(text: text)
//        })
//    }
}
