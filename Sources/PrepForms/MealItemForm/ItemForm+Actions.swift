import SwiftUI
import SwiftUISugar
import FoodLabel
import PrepViews
import PrepDataTypes
import SwiftHaptics
import PrepCoreDataStack

extension ItemForm {
    
    func tappedQuantity() {
        showingQuantityForm = true
    }
    
    func tappedSave() {
        Haptics.feedback(style: .soft)
        if viewModel.forIngredient {
            //TODO: IngredientItem
        } else {
            if let mealItem = viewModel.mealaFoodItem {
                actionHandler(.save(mealItem, viewModel.dayMeal))
            }
        }
        actionHandler(.dismiss)
    }
    
    func tappedClose() {
        Haptics.feedback(style: .soft)
        actionHandler(.dismiss)
    }
    
    func tappedDelete() {
        Haptics.selectionFeedback()
        showingDeleteConfirmation = true
    }

    func delete() {
        Haptics.successFeedback()
        
        if viewModel.forIngredient {
            //TODO: IngredientItem
        } else {
            if let mealItem = viewModel.mealaFoodItem {
                DataManager.shared.deleteMealItem(mealItem, in: viewModel.dayMeal)
            }
        }
    }

    func didTapGoalSetButton(forMeal: Bool) {
//        if forMeal {
//            showingMealTypesPicker = true
//        } else {
//            showingDietsPicker = true
//        }
    }
}
