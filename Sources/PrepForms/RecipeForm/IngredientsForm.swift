import SwiftUI
import PrepCoreDataStack
import PrepDataTypes

public struct IngredientFoodItem: Identifiable, Hashable, Codable, Equatable {
    public var id: UUID
    public var food: Food
    public var amount: FoodValue
    public var sortPosition: Int
    public var badgeWidth: CGFloat
    public var energyInKcal: Double
    public var parentFoodId: UUID?
}

struct IngredientsForm: View {
    
    struct Cell: View {
        
        let item: IngredientFoodItem
        
        var body: some View {
            Text("Food")
        }
    }
    
    @ObservedObject var ingredients: Ingredients
    
    @State var showingFoodSearch = false
    @State var showingAddRecipe = false

    @State var searchIsFocused: Bool = false
    

    init(ingredients: Ingredients) {
        self.ingredients = ingredients
    }
    
    var body: some View {
        content
            .sheet(isPresented: $showingFoodSearch) { foodSearch }
            .sheet(isPresented: $showingAddRecipe) { recipeForm }
    }
    
    var content: some View {
        List {
            ForEach(ingredients.foodItems) { foodItem in
                Cell(item: foodItem)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .trailing)
                        )
                    )
            }
        }
    }
    
    var recipeForm: some View {
        RecipeForm()
    }
    
    var foodSearch: some View {
        NavigationStack {
            FoodSearch(
                dataProvider: DataManager.shared,
                isRootInNavigationStack: true,
                shouldDelayContents: true,
                focusOnAppear: true,
                searchIsFocused: $searchIsFocused,
                actionHandler: handleFoodSearchAction
            )
        }
    }
    
    func didTapFood(_ food: Food) {
//        Haptics.feedback(style: .soft)
//        viewModel.setFood(food)
//
//        if isInitialFoodSearch {
//            viewModel.path = [.mealItemForm]
//        } else {
//            dismiss()
//        }
    }
    
    func didTapFoodBadge(_ food: Food) {
//        Haptics.feedback(style: .soft)
//        foodToShowMacrosFor = food
    }
    
    func didTapClose() {
//        Haptics.feedback(style: .soft)
//        actionHandler(.dismiss)
    }
    
    func didTapAdd(_ foodType: FoodType) {
        switch foodType {
        case .food:
            break
        case .recipe:
            showingAddRecipe = true
        case .plate:
            break
        }
    }
    
    func handleFoodSearchAction(_ action: FoodSearch.Action) {
        switch action {
        case .dismiss:
            didTapClose()
        case .tappedFood(let food):
            didTapFood(food)
        case .tappedFoodBadge(let food):
            didTapFoodBadge(food)
        case .tappedAddFood:
            break
        }
    }
}
