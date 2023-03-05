//import SwiftUI
//import VisionSugar
//import FoodLabelScanner
//
//extension TextPickerModel {
//    
//    //MARK: - TextBoxes
//    
//    func texts(for imageModel: ImageModel) -> [RecognizedText] {
//        
//        guard !mode.isColumnSelection else {
//            return mode.columnTexts(onImageWithId: imageModel.id)
//        }
//        
//        let filter = mode.filter ?? .allTextsAndBarcodes
//        let texts = imageModel.texts(for: filter)
//        return texts
//    }
//   
//    func textBoxes(for imageModel: ImageModel) -> [TextBox] {
//        let texts = texts(for: imageModel)
//        var textBoxes: [TextBox] = []
//        textBoxes = texts.map {
//            TextBox(
//                boundingBox: $0.boundingBox,
//                color: color(for: $0),
//                tapHandler: tapHandler(for: $0)
//            )
//        }
//        
//        textBoxes.append(
//            contentsOf: barcodes(for: imageModel).map {
//                TextBox(boundingBox: $0.boundingBox,
//                        color: color(for: $0),
//                        tapHandler: tapHandler(for: $0)
//                )
//        })
//        return textBoxes
//    }
//    
//    //MARK: - Helpers
//    
//    var columnCountForCurrentImage: Int {
//        currentImageModel?.scanResult?.columnCount ?? 0
//    }
//    
//    var currentImageModel: ImageModel? {
//        guard currentIndex < imageModels.count else { return nil }
//        return imageModels[currentIndex]
//    }
//    
//    var currentScanResult: ScanResult? {
//        currentImageModel?.scanResult
//    }
//    
//    var singleSelectedImageText: ImageText? {
//        guard selectedImageTexts.count == 1 else {
//            return nil
//        }
//        return selectedImageTexts.first
//    }
//    
//    func boundingBox(forImageAt index: Int) -> CGRect {
//        if mode.isColumnSelection {
//            return mode.boundingBox(forImageWithId: imageModels[index].id) ?? .zero
//        } else {
//            return selectedBoundingBox(forImageAt: index) ?? imageModels[index].relevantBoundingBox
//        }
//    }
//
//    func shouldDismissAfterTappingDone() -> Bool {
//        if case .multiSelection(_, _, let handler) = mode {
//            handler(selectedImageTexts)
//            return true
//        } else if case .columnSelection(_, _, _, let requireConfirmation, _, _) = mode {
//            return !requireConfirmation
//        }
//        return true
//    }
//
//    func barcodes(for imageModel: ImageModel) -> [RecognizedBarcode] {
//        guard mode.filter?.includesBarcodes == true else {
//            return []
//        }
//        return imageModel.recognizedBarcodes
//    }
//    
//    func color(for barcode: RecognizedBarcode) -> Color {
//        return Color.blue
//    }
//    
//    func color(for text: RecognizedText) -> Color {
//        if selectedImageTexts.contains(where: { $0.text == text }) {
//            if mode.isColumnSelection {
//                return Color(.systemBackground)
////                return Color.white
//            } else {
//                return Color.accentColor
//            }
//        } else {
//            return mode.isColumnSelection ? Color(.systemBackground).opacity(0.3) : Color.yellow
//        }
//    }
//    
//    func texts(at index: Int) -> [RecognizedText] {
//        texts(for: imageModels[index])
//    }
//    
//    var textsForCurrentImage: [RecognizedText] {
//        return texts(for: imageModels[currentIndex])
//        //        if onlyShowTextsWithValues {
//        //            return imageModels[currentIndex].textsWithValues
//        //        } else {
//        //            return imageModels[currentIndex].texts
//        //        }
//    }
//    
//    var currentImageId: UUID? {
//        imageModels[currentIndex].id
//    }
//    
//    func imageSize(at index: Int) -> CGSize? {
//        imageModels[index].image?.size
//    }
//    
//    var currentImage: UIImage? {
//        imageModels[currentIndex].image
//    }
//    var currentImageSize: CGSize? {
//        currentImage?.size
//    }
//    
////    var shouldShowMenu: Bool {
////        allowsTogglingTexts || deleteImageHandler != nil
////    }
//    
//    var shouldShowActions: Bool {
////        allowsTogglingTexts || deleteImageHandler != nil
//        mode.isImageViewer
//    }
//
//    var shouldShowDoneButton: Bool {
//        mode.isMultiSelection || mode.isColumnSelection
//    }
//    
//    var showShowImageSelector: Bool {
//        (mode.isImageViewer || mode.isColumnSelection || mode.isMultiSelection) && imageModels.count > 1
//    }
//
//    var shouldShowSelectedTextsBar: Bool {
//        mode.isMultiSelection
////        allowsMultipleSelection
//    }
//    
//    var shouldShowColumnPickerBar: Bool {
//        mode.isColumnSelection
//    }
//
//    var shouldShowBottomBar: Bool {
//        showShowImageSelector || shouldShowSelectedTextsBar || shouldShowColumnPickerBar
//    }
//    
//    var shouldShowMenuInTopBar: Bool {
//        shouldShowActions
////        imageModels.count == 1 && shouldShowActions && allowsMultipleSelection == false
//    }
//    
//    var columns: [TextColumn]? {
//        guard case .columnSelection(let column1, let column2, _, _, _, _) = mode else {
//            return nil
//        }
//        return [column1, column2]
//    }
//    
//    var columnSelectionHandler: ColumnSelectionHandler? {
//        mode.columnSelectionHandler
//    }
//    
//    var requiresConfirmation: Bool {
//        mode.requiresConfirmation
//    }
//}
