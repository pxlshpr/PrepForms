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
        
        @State var presentedSheet: Sheet? = nil
        @State var presentedFullScreenSheet: Sheet? = nil
        @State var hasAppearedDelayed: Bool = false
        
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
            print("💭 ItemForm.FoodSearch.init() \(id)")
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
    }

    var navigationStack: some View {
        NavigationStack(path: $viewModel.path) {
            foodSearch
                .navigationDestination(for: ItemFormRoute.self) { route in
                    navigationDestination(for: route)
                }
        }
    }
    
    var navigationView: some View {
        NavigationView {
            foodSearch
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
///        .sheet(item: $presentedSheet) { sheet(for: $0) }
        .fullScreenCover(item: $presentedFullScreenSheet) { sheet(for: $0) }
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
    
    func present(_ sheet: Sheet) {
        
        if presentedSheet != nil {
            presentedSheet = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                Haptics.feedback(style: .soft)
                presentedSheet = sheet
            }
        } else if presentedFullScreenSheet != nil {
            presentedFullScreenSheet = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                Haptics.feedback(style: .soft)
                presentedSheet = sheet
            }
        } else {
            Haptics.feedback(style: .soft)
            withAnimation(.interactiveSpring()) {
                presentedSheet = sheet
            }
        }
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
        } else if presentedSheet != nil {
            presentedSheet = nil
            delayedPresent()
        } else {
            present()
        }
    }
    
    @ViewBuilder
    func navigationDestination(for route: ItemFormRoute) -> some View {
        switch route {
        case .mealItemForm:
            itemForm
        case .food:
            itemFormSearch
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

