import SwiftUI
import SwiftHaptics
import PrepCoreDataStack
import PrepDataTypes
import SwiftUISugar

public struct ItemFoodSearch: View {

    @Environment(\.dismiss) var dismiss
    
    @ObservedObject var viewModel: ItemFormModel
    let isInitialFoodSearch: Bool
    let forIngredient: Bool
    let actionHandler: (ItemFormAction) -> ()

    @State var foodToShowMacrosFor: Food? = nil
    @State var searchIsFocused = false
    @State var presentedSheet: ItemFormSheet? = nil
    @State var presentedFullScreenSheet: ItemFormSheet? = nil
    @State var hasAppearedDelayed: Bool = false

    public init(
        viewModel: ItemFormModel,
        isInitialFoodSearch: Bool = false,
        forIngredient: Bool = false,
        actionHandler: @escaping (ItemFormAction) -> ()
    ) {
        self.viewModel = viewModel
        self.isInitialFoodSearch = isInitialFoodSearch
        self.forIngredient = forIngredient
        self.actionHandler = actionHandler
    }
    
    public var body: some View {
        Group {
            if isInitialFoodSearch {
                navigationStack
            } else {
                foodSearch
            }
        }
    }
    
    @State var showingSomething = false
    
    var navigationStack: some View {
        NavigationStack(path: $viewModel.path) {
            foodSearch
//                .navigationDestination(for: ItemFormRoute.self) { route in
//                    EmptyView()
//                }
                .navigationDestination(isPresented: $showingSomething) {
                    EmptyView()
                }
//                .navigationDestination(for: ItemFormRoute.self) { route in
//                    navigationDestination(for: route)
//                }
        }
    }
    
    var foodSearch: some View {
        FoodSearch(
            id: UUID(),
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

    var itemForm: some View {
        EmptyView()
//        ItemForm(
//            viewModel: viewModel,
//            isEditing: false,
//            actionHandler: actionHandler
//        )
    }
    
    var itemFormSearch: some View {
        EmptyView()
//        ItemForm.FoodSearch(
//            viewModel: viewModel,
//            forIngredient: forIngredient,
//            actionHandler: actionHandler
//        )
    }
    var mealPicker: some View {
        EmptyView()
//        ItemForm.MealPicker(didTapDismiss: {
//            actionHandler(.dismiss)
//        }, didTapMeal: { pickedMeal in
//            NotificationCenter.default.post(
//                name: .didPickDayMeal,
//                object: nil,
//                userInfo: [Notification.Keys.dayMeal: pickedMeal]
//            )
//        })
//        .environmentObject(viewModel)
    }

    func handleFoodSearchAction(_ action: FoodSearch.Action) {
//        switch action {
//        case .dismiss:
//            didTapClose()
//        case .tappedFood(let food):
//            didTapFood(food)
//        case .tappedFoodBadge(let food):
//            didTapFoodBadge(food)
//        case .tappedAddFood:
//            didTapAddFood()
//        }
    }
    
    var trailingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            addMenu
        }
    }
    
    func didTapAddRecipe() {
        Haptics.feedback(style: .soft)
        presentFullScreen(.recipeForm)
    }
    
    var addMenu: some View {
        var label: some View {
            Image(systemName: "plus")
                .frame(width: 50, height: 50, alignment: .trailing)
        }
        
        var addFoodButton: some View {
            Button {
//                didTapAddFood()
            } label: {
                Label("Food", systemImage: FoodType.food.systemImage)
            }
        }
        
        var scanFoodLabelButton: some View {
            Button {
//                didTapScanFoodLabel()
            } label: {
                Label("Scan Food Label", systemImage: "text.viewfinder")
            }
        }
        
        var addPlateButton: some View {
            Button {
//                didTapAddPlate()
            } label: {
                Label("Plate", systemImage: FoodType.plate.systemImage)
            }
        }
        
        var addRecipeButton: some View {
            Button {
                didTapAddRecipe()
            } label: {
                Label("Recipe", systemImage: FoodType.recipe.systemImage)
            }
        }
        
        return Menu {
            Section("Create New") {
                addFoodButton
                addRecipeButton
                if !forIngredient {
                    addPlateButton
                }
            }
            scanFoodLabelButton
        } label: {
            label
        }
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture().onEnded {
            Haptics.selectionFeedback()
        })
    }
    
    public var body_legacy: some View {
        Button("Show Recipe Form") {
            presentFullScreen(.recipeForm)
        }
//        .fullScreenCover(isPresented: $showingRecipeForm) { recipeForm }
        .fullScreenCover(item: $presentedFullScreenSheet) { sheet(for: $0) }
    }
    
    @ViewBuilder
    func sheet(for sheet: ItemFormSheet) -> some View {
        switch sheet {
//        case .foodForm: foodForm
        case .recipeForm: recipeForm
//        case .plateForm: plateForm
        default: EmptyView()
        }
    }

    var recipeForm: some View {
        ParentFoodForm(
            forRecipe: true,
            actionHandler: { _ in }
        )
    }
    
    func presentFullScreen(_ sheet: ItemFormSheet, delayIfPresented: Bool = true) {
        
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
    
}
