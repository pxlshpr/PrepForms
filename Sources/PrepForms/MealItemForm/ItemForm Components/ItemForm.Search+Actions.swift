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
        viewModel.setFood(food)

        if isInitialFoodSearch {
            viewModel.path = [.mealItemForm]
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
        FoodForm.ViewModel.shared.reset()
        
        Haptics.feedback(style: .soft)
        
        showingAddFood = true
    }
    
    func didTapScanFoodLabel() {
        FoodForm.Fields.shared.reset()
        FoodForm.Sources.shared.reset()
        FoodForm.ViewModel.shared.reset(startWithCamera: true)

        Haptics.feedback(style: .heavy)
        showingAddFood = true

//        searchIsFocused = false
//        showingAddHeroButton = false
    }

}
