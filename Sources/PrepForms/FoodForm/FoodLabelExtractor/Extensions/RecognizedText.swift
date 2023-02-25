import VisionSugar
import FoodLabelScanner
import PrepDataTypes

extension RecognizedText {
    func allDetectedFoodLabelValues(for attribute: Attribute) -> [FoodLabelValue] {
        var allValues: [FoodLabelValue] = []
        
        func addValueIfNotExisting(_ value: FoodLabelValue) {
            guard !allValues.contains(value) else { return }
            allValues.append(value)
        }
        
        for candidate in candidates {
            let detectedValues = candidate.detectedValues
            for value in detectedValues {
                
                /// If the value has no unit, assign the attribute's default unit
//                let valueWithUnit: FoodLabelValue
//                if value.unit == nil {
//                    valueWithUnit = FoodLabelValue(amount: value.amount, unit: attribute.defaultUnit)
//                } else {
//                    valueWithUnit = value
//                }
//
//                addValueIfNotExisting(valueWithUnit)
//
//                if attribute == .energy {
//                    let oppositeUnit: FoodLabelUnit = valueWithUnit.unit == .kcal ? .kj : .kcal
//                    addValueIfNotExisting(FoodLabelValue(amount: valueWithUnit.amount, unit: oppositeUnit))
//                }
                let valueWithoutUnit = FoodLabelValue(amount: value.amount)
                addValueIfNotExisting(valueWithoutUnit)
            }
        }
        return allValues
    }
}
