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
            viewModel.present(.emoji)
        }
    }
    
    var foodSearchForm: some View {
        ItemForm.FoodSearch(
            nestLevel: nestLevel + 1,
            viewModel: viewModel.itemFormViewModel,
            isInitialFoodSearch: true,
            forIngredient: true,
            actionHandler: { handleItemAction($0, forEdit: false) }
        )
    }

    var ingredientEditSheet: some View {
        ItemForm(
            viewModel: viewModel.itemFormViewModel,
            isEditing: true,
            forIngredient: true,
            actionHandler: { handleItemAction($0, forEdit: true) }
        )
    }
}
