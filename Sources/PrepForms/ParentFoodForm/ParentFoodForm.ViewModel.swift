import SwiftUI
import PrepDataTypes

extension ParentFoodForm {
    class ViewModel: ObservableObject {
        
        let forRecipe: Bool
        let existingFood: Food?
        
        @Published var items: [IngredientItem] = []
        
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
    }
    
    func recalculateBadgeWdiths() {
        Task.detached(priority: .background) {
            var copy = self.items
            
            let start = CFAbsoluteTimeGetCurrent()
            
            let energyValues = copy.energyValuesInKcalDecreasing
            for i in copy.indices {
                let largest = energyValues.first ?? 0
                let smallest = energyValues.last ?? 0
                copy[i].badgeWidth = calculateMacrosIndicatorWidth(
                    for: copy[i].energyInKcal,
                    largest: largest,
                    smallest: smallest
                )
            }
            
            print("🔹 Took: \(CFAbsoluteTimeGetCurrent()-start)s")
            
            await MainActor.run { [copy] in
                self.items = copy
            }
        }
    }
}

extension Array where Element == IngredientItem {
    var energyValuesInKcalDecreasing: [Double] {
        let scaled = self.map { $0.energyInKcal }
        let sorted = scaled.sorted { $0 > $1 }
        return sorted
    }
}
