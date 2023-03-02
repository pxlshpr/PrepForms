import SwiftUI
import PrepDataTypes

class Ingredients: ObservableObject {
    
    @Published var foodItems: [IngredientItem] = []
    
    init() {
    }
    
    var isEmpty: Bool {
        true
    }
}
