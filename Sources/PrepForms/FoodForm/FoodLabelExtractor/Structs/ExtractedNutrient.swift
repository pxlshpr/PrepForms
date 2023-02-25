import SwiftUI
import VisionSugar
import FoodLabelScanner
import PrepDataTypes

public class ExtractedNutrient: ObservableObject, Identifiable {
    
    public var attribute: Attribute
    public var attributeText: RecognizedText? = nil
    @Published public var isConfirmed: Bool = false
    @Published public var value: FoodLabelValue? = nil
    @Published public var valueText: RecognizedText? = nil
    
    public var scannerValue: FoodLabelValue? = nil
    public var scannerValueText: RecognizedText? = nil

    init(
        attribute: Attribute,
        attributeText: RecognizedText? = nil,
        isConfirmed: Bool = false,
        value: FoodLabelValue? = nil,
        valueText: RecognizedText? = nil
    ) {
        self.attribute = attribute
        self.attributeText = attributeText
        self.isConfirmed = isConfirmed
        self.value = value
        self.valueText = valueText
        self.scannerValue = value
        self.scannerValueText = valueText
    }
    
    public var id: Attribute {
        self.attribute
    }
}

extension ExtractedNutrient {
    var attributeBoundingBox: CGRect {
        attributeText?.boundingBox ?? .null
    }

    var valueBoundingBox: CGRect {
        valueText?.boundingBox ?? .null
    }

    var boundingBoxWithAttribute: CGRect {
        attributeBoundingBox.union(valueBoundingBox)
    }
}

//MARK: Hashable and Equatable Conformance

extension ExtractedNutrient: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(attribute)
        hasher.combine(attributeText)
        hasher.combine(isConfirmed)
        hasher.combine(value)
        hasher.combine(valueText)
        hasher.combine(scannerValue)
        hasher.combine(scannerValueText)
    }
}

extension ExtractedNutrient: Equatable {
    public static func ==(lhs: ExtractedNutrient, rhs: ExtractedNutrient) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}
