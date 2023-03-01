import SwiftUI
import PrepCoreDataStack
import PrepDataTypes
import SwiftHaptics
import SwiftUISugar
import ActivityIndicatorView
import Camera
import SwiftSugar
import PrepViews

struct RecipeForm: View {
    
    @State var showingFoodSearch = false
    @State var showingAddRecipe = false
    @State var searchIsFocused: Bool = false
    
    init() {
    }

    var body: some View {
        NavigationStack {
            FormStyledScrollView {
                FormStyledSection {
                    Button("Add Food") {
                        showingFoodSearch = true
                    }
                }
            }
            .sheet(isPresented: $showingFoodSearch) { foodSearch }
            .sheet(isPresented: $showingAddRecipe) { recipeForm }
            .navigationTitle("New Recipe")
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
//            Haptics.feedback(style: .soft)
//            viewModel.setFood(food)
//
//            if isInitialFoodSearch {
//                viewModel.path = [.mealItemForm]
//            } else {
//                dismiss()
//            }
    }
    
    func didTapFoodBadge(_ food: Food) {
//            Haptics.feedback(style: .soft)
//            foodToShowMacrosFor = food
    }
    
    func didTapClose() {
//            Haptics.feedback(style: .soft)
//            actionHandler(.dismiss)
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
