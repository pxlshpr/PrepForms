import SwiftUI
import FoodLabel
import PrepDataTypes

extension ParentFoodForm {
    var foodLabelData: FoodLabelData {
        FoodLabelData(
            energyValue: model.value(for: .energy),
            carb: model.amount(for: .carb),
            fat: model.amount(for: .fat),
            protein: model.amount(for: .protein),
            nutrients: model.microsDict,
            quantityValue: fields.amount.value.double ?? 0,
            quantityUnit: fields.amount.value.doubleValue.unitDescription
        )
    }
}

extension ParentFoodForm.Model {
    
    var nutrientTypes: [NutrientType] {
        let start = CFAbsoluteTimeGetCurrent()
        var nutrients: Set<NutrientType> = Set()
        
        for item in items {
            for nutrient in item.food.info.nutrients.micros {
                guard let nutrientType = nutrient.nutrientType else { continue }
                nutrients.insert(nutrientType)
            }
        }
        
        let array = Array(nutrients)
        print("⌛️ Getting allAvailableNutrients took: \(CFAbsoluteTimeGetCurrent()-start)s")
        return array
    }
    
    var microsDict: [NutrientType : FoodLabelValue] {
        let start = CFAbsoluteTimeGetCurrent()
        var dict: [NutrientType : FoodLabelValue] = [:]

        for nutrientType in nutrientTypes {
            let value = value(for: .micro(nutrientType: nutrientType, nutrientUnit: nutrientType.defaultSupportedNutrientUnit))
            dict[nutrientType] = value
        }

        print("⌛️ Getting microsDict took: \(CFAbsoluteTimeGetCurrent()-start)s")
        return dict
    }
    
    var microsArray: [FoodNutrient] {
        let start = CFAbsoluteTimeGetCurrent()
        var array: [FoodNutrient] = []
        for nutrientType in nutrientTypes {
            let component: NutrientMeterComponent = .micro(nutrientType: nutrientType, nutrientUnit: nutrientType.defaultSupportedNutrientUnit)
            let amount = amount(for: component)
            let foodNutrient = FoodNutrient(
                nutrientType: nutrientType,
                value: amount,
                nutrientUnit: nutrientType.defaultSupportedNutrientUnit
            )
            array.append(foodNutrient)
        }
        print("⌛️ Getting microsArray took: \(CFAbsoluteTimeGetCurrent()-start)s")
        return array
    }
    
    func amount(for component: NutrientMeterComponent) -> Double {
        //TODO: Convert here
        items.reduce(0) { $0 + $1.scaledValue(for: component) }
    }

    func value(for component: NutrientMeterComponent) -> FoodLabelValue {
        FoodLabelValue(
            amount: amount(for: component),
            unit: component.unit.foodLabelUnit ?? .g
        )
    }
}

