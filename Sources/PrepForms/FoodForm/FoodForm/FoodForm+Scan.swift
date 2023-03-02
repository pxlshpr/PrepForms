import SwiftUI
import FoodLabelScanner

extension FoodForm {

    func didScanAllPickedImages() {
        extractFieldsOrShowColumnSelectionInfo()
    }
    
    func extractFieldsOrShowColumnSelectionInfo() {
    }
    
    func handleExtractedFieldValues(_ fieldValues: [FieldValue], shouldOverwrite: Bool) {
        
        fields.handleExtractedFieldsValues(fieldValues, shouldOverwrite: shouldOverwrite)
        
        /// Set the `ImageSetStatus` in `Sources` with the counts from `Fields`
        sources.imageSetStatus = .scanned(
            numberOfImages: sources.imageViewModels.count,
//            counts: fields.dataPointsCount //TODO: Do this
            counts: DataPointsCount(total: 0, autoFilled: 0, selected: 0, barcodes: 0)
        )
    }
    
}
