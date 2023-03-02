import SwiftUI
import SwiftHaptics
import PrepCoreDataStack
import PrepDataTypes
import SwiftUISugar

extension ItemForm {
    public struct FoodSearch: View {
        
        @Environment(\.dismiss) var dismiss
        
        @ObservedObject var viewModel: ViewModel
        @State var foodToShowMacrosFor: Food? = nil
        @State var searchIsFocused = false
        
        @State var showingFoodForm = false
        @State var showingRecipeForm = false
        @State var showingPlateForm = false

        let isInitialFoodSearch: Bool
        let forIngredient: Bool
        let actionHandler: (ItemFormAction) -> ()
        
        public init(
            viewModel: ViewModel,
            isInitialFoodSearch: Bool = false,
            forIngredient: Bool = false,
            actionHandler: @escaping (ItemFormAction) -> ()
        ) {
            print("💭 ItemForm.FoodSearch.init()")
            self.viewModel = viewModel
            self.isInitialFoodSearch = isInitialFoodSearch
            self.forIngredient = forIngredient
            self.actionHandler = actionHandler
        }
    }
}

extension ItemForm.FoodSearch {
    
    public var body: some View {
        Group {
            if isInitialFoodSearch {
                navigationStack
            } else {
                foodSearch
            }
        }
        //TODO: Bring this back once we can tell if the search field is focused and
//        .interactiveDismissDisabled(!viewModel.path.isEmpty)
//        .interactiveDismissDisabled(!viewModel.path.isEmpty || searchIsFocused)
    }

    var navigationStack: some View {
        NavigationStack(path: $viewModel.path) {
            foodSearch
                .navigationDestination(for: ItemFormRoute.self) { route in
                    navigationDestination(for: route)
                }
        }
    }
    
    var foodSearch: some View {
        FoodSearch(
            dataProvider: DataManager.shared,
            isRootInNavigationStack: isInitialFoodSearch,
            shouldShowPlatesInFilter: !forIngredient,
            shouldDelayContents: isInitialFoodSearch,
            focusOnAppear: isInitialFoodSearch,
            searchIsFocused: $searchIsFocused,
            actionHandler: handleFoodSearchAction
        )
        .sheet(item: $foodToShowMacrosFor) { macrosView(for: $0) }
        .navigationBarBackButtonHidden(viewModel.food == nil)
        .toolbar { trailingContent }
        .fullScreenCover(isPresented: $showingFoodForm) { foodForm }
        .sheet(isPresented: $showingRecipeForm) { recipeForm }
        .sheet(isPresented: $showingPlateForm) { plateForm }
    }
    
    @ViewBuilder
    func navigationDestination(for route: ItemFormRoute) -> some View {
        switch route {
        case .mealItemForm:
            ItemForm(
                viewModel: viewModel,
                isEditing: false,
                actionHandler: actionHandler
            )
        case .food:
            ItemForm.FoodSearch(
                viewModel: viewModel,
                forIngredient: forIngredient,
                actionHandler: actionHandler
            )
        case .meal:
            mealPicker
        }
    }
}

extension Food {
    var defaultFormUnit: FormUnit {
        if let _ = info.serving {
            return .serving
        } else if let formUnit = FormUnit(foodValue: info.amount, in: info.sizes) {
            return formUnit
        } else {
            return .weight(.g)
        }
    }
}

