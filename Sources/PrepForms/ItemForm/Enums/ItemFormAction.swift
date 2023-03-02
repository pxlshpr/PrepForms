import Foundation
import PrepDataTypes

public enum ItemFormAction {
    case saveMealItem(MealItem, DayMeal)
    case saveIngredientItem(IngredientItem)
    case delete
    case dismiss
}
