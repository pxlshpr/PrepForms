import SwiftUI
import FoodLabelScanner
import VisionSugar

class ExtractedColumns: ObservableObject {
    
    let id = UUID()
    var column1: ExtractedColumn
    var column2: ExtractedColumn
    @Published var selectedColumnIndex: Int
    
    init() {
        self.column1 = .init(column: 1)
        self.column2 = .init(column: 2)
        self.selectedColumnIndex = 1
    }
    
    init(column1: ExtractedColumn, column2: ExtractedColumn, selectedColumnIndex: Int) {
        self.column1 = column1
        self.column2 = column2
        self.selectedColumnIndex = selectedColumnIndex
    }
    
    var selectedColumn: ExtractedColumn {
        selectedColumnIndex == 1 ? column1 : column2
    }

    var nonSelectedColumn: ExtractedColumn {
        selectedColumnIndex == 1 ? column2 : column1
    }

    var selectedColumnNutrients: [ExtractedNutrient] {
        selectedColumnIndex == 1 ? column1.extractedNutrients : column2.extractedNutrients
    }
    
    var valueTexts: [RecognizedText] {
        var texts: [RecognizedText] = []
        for column in [column1, column2] {
            texts.append(
                contentsOf: column.extractedNutrients
                    .compactMap { $0.valueText }
                )
        }
        return texts
    }
    
    var selectedColumnValueTexts: [RecognizedText] {
        selectedColumn.extractedNutrients
            .filter { nutrient in
                nonSelectedColumn.extractedNutrients
                    .contains(where: {
                        $0.attribute == nutrient.attribute
                        && $0.valueText != nil
                    })
            }
            .compactMap { nutrient in
                nutrient.valueText
            }
    }
    
    var nonSelectedColumnValueTexts: [RecognizedText] {
        nonSelectedColumn.extractedNutrients
            .filter { nutrient in
                selectedColumn.extractedNutrients
                    .contains(where: {
                        $0.attribute == nutrient.attribute
                        && $0.valueText != nil
                    })
            }
            .compactMap { nutrient in
                nutrient.valueText
            }
    }
    
    var boundingBox: CGRect {
        var boundingBoxes: [CGRect] = []
        for column in [column1, column2] {
            boundingBoxes.append(
                contentsOf: column.extractedNutrients
                    .compactMap { $0.boundingBoxWithAttribute }
            )
        }
        return boundingBoxes.union
    }
    
    func toggleSelectedColumnIndex() {
        selectedColumnIndex = selectedColumnIndex == 1 ? 2 : 1
    }
}

struct ExtractedColumn {
    let column: Int
    let name: String
    let extractedNutrients: [ExtractedNutrient]
    
    init(column: Int, name: String = "", extractedNutrients: [ExtractedNutrient] = []) {
        self.column = column
        self.name = name
        self.extractedNutrients = extractedNutrients
    }
    
//    func containsTexts(from imageViewModel: ImageViewModel) -> Bool {
//        imageTexts.contains {
//            $0.imageId == imageViewModel.id
//        }
//    }
//
    var valueTexts: [RecognizedText] {
        extractedNutrients
            .compactMap { $0.valueText }
    }
    
    func contains(_ text: RecognizedText) -> Bool {
        valueTexts.contains {
            $0.id == text.id
        }
    }
}
