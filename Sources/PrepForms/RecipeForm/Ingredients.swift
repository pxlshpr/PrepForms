import SwiftUI

class Ingredients: ObservableObject {
    
    @Published var foodItems: [IngredientFoodItem] = []
    
    init() {
    }
    
    var isEmpty: Bool {
        true
    }
}
