import PrepDataTypes
import FoodLabelScanner

extension FoodLabelValue {
    mutating func correctUnit(for attribute: Attribute) {
        guard let unit else {
            self.unit = attribute.defaultUnit
            return
        }
        
        if !attribute.supportsUnit(unit) {
            self.unit = attribute.defaultUnit
        }
        return
    }
}
