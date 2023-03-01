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
        
        /// Actually shows the `View` for the `FoodForm` that we were passed in
        showingAddFood = true
    }
    
    func didTapScanFoodLabel() {
        //TODO: Bring this back
        FoodForm.Fields.shared.reset()
        FoodForm.Sources.shared.reset()
        FoodForm.ViewModel.shared.reset(startWithCamera: true)

        /// Actually shows the `View` for the `FoodForm` that we were passed in
        showingAddFood = true

        /// Resigns focus on search and hides the hero button
//        searchIsFocused = false
//        showingAddHeroButton = false

    }

}
