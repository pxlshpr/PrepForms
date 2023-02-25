import PrepDataTypes
import FoodLabelScanner

extension NutrientType {
    var supportedNutrientUnits: [NutrientUnit] {
        var units = units.map {
            $0
        }
        /// Allow percentage values for `mineral`s and `vitamin`s
        if supportsPercentages {
            units.append(.p)
        }
        return units
    }

    //TODO: Do this on a per-group basis
    var supportsPercentages: Bool {
        group?.supportsPercentages ?? false
    }
}

extension NutrientTypeGroup {
    var supportsPercentages: Bool {
        self == .vitamins || self == .minerals
    }
}

//extension NutrientType {
//    var supportedFoodLabelUnits: [FoodLabelUnit] {
//        supportedNutrientUnits.map {
//            $0.foodLabelUnit ?? .g
//        }
//    }
//}
