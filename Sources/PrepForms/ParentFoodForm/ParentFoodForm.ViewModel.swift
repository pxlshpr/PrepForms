import SwiftUI
import PrepDataTypes
import SwiftHaptics

extension ParentFoodForm {
    class ViewModel: ObservableObject {
        
        let forRecipe: Bool
        let existingFood: Food?
        
        @Published var items: [IngredientItem] = []
        @Published var sortOrder: IngredientSortOrder = .none

        init(
            forRecipe: Bool,
            existingFood: Food? = nil
        ) {
            self.existingFood = existingFood
            self.forRecipe = forRecipe
        }
    }
}

extension ParentFoodForm.ViewModel {
    var title: String {
        "\(isEditing ? "Edit" : "New") \(forRecipe ? "Recipe" : "Plate")"
    }
    
    var isEditing: Bool {
        existingFood == nil
    }
    
    var ingredientsTitle: String {
        forRecipe ? "Ingredients" : "Foods"
    }
    
    var addTitle: String {
        "Add \(forRecipe ? "an Ingredient" : "a Food")"
    }
    
    var isEmpty: Bool {
        items.isEmpty
    }
}

extension ParentFoodForm.ViewModel {
    
    func add(_ item: IngredientItem) {
        var item = item
        item.energyInKcal = item.scaledValueForEnergyInKcal
        self.items.append(item)
        resortItems()
    }
    
    var sortBinding: Binding<IngredientSortOrder> {
        Binding<IngredientSortOrder>(
            get: { self.sortOrder },
            set: { newValue in
                Haptics.feedback(style: .soft)
                self.sortOrder = newValue
            }
        )
    }
    
    var sortOrderTitle: String {
        if sortOrder != .none {
            return "Sort: \(sortOrder.description)"
        } else {
            return "Sort"
        }
    }

    func resortItems() {
        switch sortOrder {
        case .name:
            items.sort(by: { $0.food.name < $1.food.name })
        case .energy:
            items.sort(by: { $0.energyInKcal > $1.energyInKcal })
        case .carbPortion:
            items.sort(by: { $0.food.carbPortion > $1.food.carbPortion })
        case .fatPortion:
            items.sort(by: { $0.food.fatPortion > $1.food.fatPortion })
        case .proteinPortion:
            items.sort(by: { $0.food.proteinPortion > $1.food.proteinPortion })
        default:
            break
        }
    }
    
    func recalculateBadgeWdiths() {
        Task.detached(priority: .background) {
            var copy = self.items
            
            let start = CFAbsoluteTimeGetCurrent()
            
            let energyValues = copy.energyValuesInKcalDecreasing
            for i in copy.indices {
                copy[i].badgeWidth = calculateMacrosIndicatorWidth(
                    for: copy[i].energyInKcal,
                    within: energyValues
                )
            }
            
            print("🔹 Took: \(CFAbsoluteTimeGetCurrent()-start)s")
            
            await MainActor.run { [copy] in
                self.items = copy
            }
        }
    }
}

extension ParentFoodForm.ViewModel {
    var energyValue: FoodLabelValue {
        let energy = items.reduce(0) { $0 + $1.energyInKcal }
        return FoodLabelValue(amount: energy, unit: .kcal)
    }
}

extension Array where Element == IngredientItem {
    var energyValuesInKcalDecreasing: [Double] {
        let scaled = self.map { $0.energyInKcal }
        let sorted = scaled.sorted { $0 > $1 }
        return sorted
    }
}
