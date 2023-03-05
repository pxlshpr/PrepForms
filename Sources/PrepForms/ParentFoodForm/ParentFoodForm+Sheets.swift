import SwiftUI
import PrepCoreDataStack
import PrepDataTypes
import SwiftHaptics
import SwiftUISugar
import ActivityIndicatorView
import Camera
import SwiftSugar
import PrepViews
import FoodLabel
import EmojiPicker

extension ParentFoodForm {
    
    @ViewBuilder
    func sheet(for sheet: ParentFoodFormSheet) -> some View {
        switch sheet {
        case .name : nameForm
        case .detail : detailForm
        case .brand : brandForm
        case .emoji : emojiPicker
        case .foodSearch : foodSearchForm
        case .ingredientEdit : ingredientEditSheet
        }
    }
    
    var nameForm: some View {
        DetailsNameForm(title: "Name", isRequired: true, name: $fields.name)
    }
    
    var detailForm: some View {
        DetailsNameForm(title: "Detail", isRequired: false, name: $fields.detail)
    }
    
    var brandForm: some View {
        DetailsNameForm(title: "Brand", isRequired: false, name: $fields.brand)
    }
    
    var emojiPicker: some View {
        EmojiPicker(
            categories: [.foodAndDrink, .animalsAndNature],
            focusOnAppear: true,
            includeCancelButton: true
        ) { emoji in
            Haptics.successFeedback()
            fields.emoji = emoji
            model.presentedSheet = nil
        }
    }
    
    var foodSearchForm: some View {
//        NewItemForm { action in
//            handleItemAction(action, forEdit: false)
//            model.presentedSheet = nil
//        }
        ItemForm.FoodSearch(
            model: model.itemFormModel,
            isInitialFoodSearch: true,
            forIngredient: true,
            actionHandler: { handleItemAction($0, forEdit: false) }
        )
    }

    var ingredientEditSheet: some View {
        ItemForm(
            model: model.itemFormModel,
            isEditing: true,
            forIngredient: true,
            actionHandler: { handleItemAction($0, forEdit: true) }
        )
    }
}

struct NewItemForm: View {
    let actionHandler: (ItemFormAction) -> ()
    var body: some View {
        Button("Add it") {
            let food = DataManager.shared.recentFoods.first!
            let ingredientItem = IngredientItem(
                food: food.ingredientFood,
                amount: .init(value: 1, formUnit: food.defaultFormUnit),
                sortPosition: 1,
                isSoftDeleted: false,
                badgeWidth: 0,
                energyInKcal: 0,
                parentFoodId: nil
            )
            actionHandler(.saveIngredientItem(ingredientItem))
        }
    }
}
