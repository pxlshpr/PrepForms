import SwiftUI
import SwiftHaptics
import PrepCoreDataStack
import PrepDataTypes
import SwiftUISugar

public struct MealItemFormSearch: View {
    
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject var viewModel: MealItemViewModel
    @State var foodToShowMacrosFor: Food? = nil
    @State var searchIsFocused = false
    @State var showingAddFood = false
    let isInitialFoodSearch: Bool
    let actionHandler: (MealItemFormAction) -> ()
    
    public init(
        viewModel: MealItemViewModel,
        isInitialFoodSearch: Bool = false,
        actionHandler: @escaping (MealItemFormAction) -> ()
    ) {
        print("💭 MealItemFormSearch.init()")
        self.viewModel = viewModel
        self.isInitialFoodSearch = isInitialFoodSearch
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
        //TODO: Bring this back once we can tell if the search field is focused and
//        .interactiveDismissDisabled(!viewModel.path.isEmpty)
//        .interactiveDismissDisabled(!viewModel.path.isEmpty || searchIsFocused)
    }

    var navigationStack: some View {
        NavigationStack(path: $viewModel.path) {
            foodSearch
                .navigationDestination(for: MealItemFormRoute.self) { route in
                    navigationDestination(for: route)
                }
        }
    }
    
    @ViewBuilder
    func navigationDestination(for route: MealItemFormRoute) -> some View {
        switch route {
        case .mealItemForm:
            MealItemForm(
                viewModel: viewModel,
                isEditing: false,
                actionHandler: actionHandler
            )
        case .food:
            MealItemFormSearch(
                viewModel: viewModel,
                actionHandler: actionHandler
            )
        case .meal:
            mealPicker
        case .quantity:
            MealItemFormQuantity(viewModel: viewModel)
        }
    }
    
    var mealPicker: some View {
        MealItemFormMealPicker(didTapDismiss: {
            actionHandler(.dismiss)
        }, didTapMeal: { pickedMeal in
            NotificationCenter.default.post(
                name: .didPickDayMeal,
                object: nil,
                userInfo: [Notification.Keys.dayMeal: pickedMeal]
            )
        })
        .environmentObject(viewModel)
    }

    var foodSearch: some View {
        func didTapFood(_ food: Food) {
            Haptics.feedback(style: .soft)
            viewModel.setFood(food)

            if isInitialFoodSearch {
                viewModel.path = [.mealItemForm]
            } else {
                dismiss()
            }
        }
        
        func didTapMacrosIndicatorForFood(_ food: Food) {
            Haptics.feedback(style: .soft)
            foodToShowMacrosFor = food
        }
        
        func didTapClose() {
            Haptics.feedback(style: .soft)
            actionHandler(.dismiss)
        }
        
        func didTapAddFood() {
            FoodForm.Fields.shared.reset()
            FoodForm.Sources.shared.reset()
            FoodForm.ViewModel.shared.reset()
            
            /// Actually shows the `View` for the `FoodForm` that we were passed in
            showingAddFood = true
        }

        return FoodSearch(
            dataProvider: DataManager.shared,
            isRootInNavigationStack: isInitialFoodSearch,
            shouldDelayContents: isInitialFoodSearch,
            focusOnAppear: isInitialFoodSearch,
            searchIsFocused: $searchIsFocused,
//            didTapAdd: didTapAdd,
            didTapClose: didTapClose,
            didTapFood: didTapFood,
            didTapMacrosIndicatorForFood: didTapMacrosIndicatorForFood,
            didTapAddFood: didTapAddFood
        )
        .sheet(item: $foodToShowMacrosFor) { macrosView(for: $0) }
        .sheet(isPresented: $showingAddFood) { foodForm }
        .navigationBarBackButtonHidden(viewModel.food == nil)
    }
    
    var foodForm: some View {
        func didSaveFood(_ formOutput: FoodFormOutput) {
            Haptics.successFeedback()
            FoodFormManager.shared.save(formOutput)
        }
        
        return FoodForm(didSave: didSaveFood)
    }
    
    var plateFormSheet: some View {
        NavigationStack {
            FormStyledScrollView {
                FormStyledSection {
                    Button("Add Food") {
                        
                    }
                }
            }
            .navigationTitle("New Plate")
        }
    }

    var recipeFormSheet: some View {
        RecipeForm()
    }


    
//    func didTapAdd(_ foodType: FoodType) {
//        actionHandler(.add(foodType))
//    }

    func macrosView(for food: Food) -> some View {
        Text("Macros for: \(food.name)")
            .presentationDetents([.medium, .large])
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

