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
        if model.forIngredient {
            guard let ingredientItem = model.ingredientItem else {
                print("Error: Saving ItemForm for ingredient item without IngredientItem")
                return
            }
            actionHandler(.saveIngredientItem(ingredientItem))
        } else {
            guard let mealItem = model.mealItem,
                  let dayMeal = model.dayMeal
            else {
                print("Error: Saving ItemForm for meal item without MealItem or DayMeal")
                return
            }
            actionHandler(.saveMealItem(mealItem, dayMeal))
        }
        actionHandler(.dismiss)
    }
    
    func tappedClose() {
        Haptics.feedback(style: .soft)
        actionHandler(.dismiss)
    }
    
    func tappedDelete() {
        Haptics.selectionFeedback()
        if model.forIngredient {
//            delete()
            showingDeleteConfirmation = true
        } else {
            showingDeleteConfirmation = true
        }
    }

    func delete() {
        Haptics.successFeedback()
        
        if model.forIngredient {
            actionHandler(.delete)
        } else {
            guard let mealItem = model.mealItem,
                  let dayMeal = model.dayMeal
            else {
                print("Deleting ItemForm for MealItem without MealItem or DayMeal")
                return
            }
            DataManager.shared.deleteMealItem(mealItem, in: dayMeal)
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
