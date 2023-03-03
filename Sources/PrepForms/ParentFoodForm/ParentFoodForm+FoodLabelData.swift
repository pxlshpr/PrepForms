import SwiftUI
import FoodLabel
import PrepDataTypes

extension ParentFoodForm {
    var foodLabelData: FoodLabelData {
        FoodLabelData(
            energyValue: viewModel.value(for: .energy),
            carb: viewModel.amount(for: .carb),
            fat: viewModel.amount(for: .fat),
            protein: viewModel.amount(for: .protein),
            nutrients: viewModel.microsDict,
            quantityValue: fields.amount.value.double ?? 0,
            quantityUnit: fields.amount.value.doubleValue.unitDescription
        )
    }
}

extension ParentFoodForm.ViewModel {
    
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
            let value = value(for: .micro(nutrientType: nutrientType, nutrientUnit: nutrientType.defaultUnit))
            dict[nutrientType] = value
        }

        print("⌛️ Getting microsDict took: \(CFAbsoluteTimeGetCurrent()-start)s")
        return dict
    }
    
    var energyValue: FoodLabelValue {
        let energy = items.reduce(0) { $0 + $1.energyInKcal }
        return FoodLabelValue(amount: energy, unit: .kcal)
    }

    func amount(for component: NutrientMeterComponent) -> Double {
        items.reduce(0) { $0 + $1.scaledValue(for: component) }
    }

    func value(for component: NutrientMeterComponent) -> FoodLabelValue {
        FoodLabelValue(
            amount: amount(for: component),
            unit: component.unit.foodLabelUnit ?? .g
        )
    }
}

