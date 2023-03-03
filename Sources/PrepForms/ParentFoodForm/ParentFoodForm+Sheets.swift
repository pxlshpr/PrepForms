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
    func sheet(for sheet: Sheet) -> some View {
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
            present(.emoji)
        }
    }
    
    var foodSearchForm: some View {
        ItemForm.FoodSearch(
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
    
    func present(_ sheet: Sheet) {
        
        if presentedSheet != nil {
            presentedSheet = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                Haptics.feedback(style: .soft)
                presentedSheet = sheet
            }
//        } else if presentedFullScreenSheet != nil {
//            presentedFullScreenSheet = nil
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                Haptics.feedback(style: .soft)
//                presentedSheet = sheet
//            }
        } else {
            Haptics.feedback(style: .soft)
            withAnimation(.interactiveSpring()) {
                presentedSheet = sheet
            }
        }
    }
}
