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
        
        @State var presentedFullScreenSheet: Sheet? = nil

        let isInitialFoodSearch: Bool
        let forIngredient: Bool
        let actionHandler: (ItemFormAction) -> ()
        
        let id = UUID()
        
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
            id: id,
            dataProvider: DataManager.shared,
            isRootInNavigationStack: isInitialFoodSearch,
            shouldShowPlatesInFilter: !forIngredient,
            shouldDelayContents: isInitialFoodSearch,
            focusOnAppear: isInitialFoodSearch,
            searchIsFocused: $searchIsFocused,
            actionHandler: handleFoodSearchAction
        )
//        .sheet(item: $foodToShowMacrosFor) { macrosView(for: $0) }
        .navigationBarBackButtonHidden(viewModel.food == nil)
        .toolbar { trailingContent }
        .fullScreenCover(item: $presentedFullScreenSheet) {
            sheet(for: $0)
        }
    }

    @ViewBuilder
    func sheet(for sheet: Sheet) -> some View {
        switch sheet {
        case .foodForm: foodForm
        case .recipeForm: recipeForm
        case .plateForm: plateForm
        }
    }

    enum Sheet: String, Identifiable  {
        case foodForm
        case recipeForm
        case plateForm
        
        public var id: String { rawValue }
    }
    
    func presentFullScreen(_ sheet: Sheet, delayIfPresented: Bool = true) {
        
        func present() {
            Haptics.feedback(style: .soft)
            presentedFullScreenSheet = sheet
        }
        
        func delayedPresent() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                present()
            }
        }
        
        guard delayIfPresented else {
            present()
            return
        }
        
        if presentedFullScreenSheet != nil {
            presentedFullScreenSheet = nil
            delayedPresent()
//        } else if presentedSheet != nil {
//            presentedSheet = nil
//            delayedPresent()
        } else {
            present()
        }
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

