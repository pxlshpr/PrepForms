import SwiftUI
import SwiftHaptics
import PrepCoreDataStack
import PrepDataTypes
import SwiftUISugar

extension ItemForm.FoodSearch {
    
    func handleFoodSearchAction(_ action: FoodSearch.Action) {
        switch action {
        case .dismiss:
            didTapClose()
        case .tappedFood(let food):
            didTapFood(food)
        case .tappedFoodBadge(let food):
            didTapFoodBadge(food)
        case .tappedAddFood:
            didTapAddFood()
        }
    }
    
    func didTapFood(_ food: Food) {
        Haptics.feedback(style: .soft)
        model.setFood(food)

        if isInitialFoodSearch {
            model.showingItem = true
//            model.path = [.mealItemForm]
        } else {
            dismiss()
        }
    }
    
    func didTapFoodBadge(_ food: Food) {
        Haptics.feedback(style: .soft)
        foodToShowMacrosFor = food
    }
    
    func didTapClose() {
        Haptics.feedback(style: .soft)
        actionHandler(.dismiss)
    }
    
    func didTapAddFood() {
        FoodForm.Fields.shared.reset()
        FoodForm.Sources.shared.reset()
        FoodForm.Model.shared.reset()
        
        Haptics.feedback(style: .soft)
        presentFullScreen(.foodForm)
    }
    
    func didTapAddRecipe() {
        Haptics.feedback(style: .soft)
        presentFullScreen(.recipeForm)
//        present(.recipeForm)
    }
    
    func didTapAddPlate() {
        Haptics.feedback(style: .soft)
        presentFullScreen(.plateForm)
//        present(.plateForm)
    }
    
    func didTapScanFoodLabel() {
        FoodForm.Fields.shared.reset()
        FoodForm.Sources.shared.reset()
        FoodForm.Model.shared.reset(startWithCamera: true)

        Haptics.feedback(style: .heavy)
        presentFullScreen(.foodForm)

//        searchIsFocused = false
//        showingAddHeroButton = false
    }

}
