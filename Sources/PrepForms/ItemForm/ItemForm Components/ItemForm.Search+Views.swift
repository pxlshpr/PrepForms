import SwiftUI
import SwiftHaptics
import PrepCoreDataStack
import PrepDataTypes
import SwiftUISugar

extension ItemForm.FoodSearch {
    
    var mealPicker: some View {
        ItemForm.MealPicker(didTapDismiss: {
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
    
    var foodForm: some View {
        func didSaveFood(_ formOutput: FoodFormOutput) {
            Haptics.successFeedback()
            FoodFormManager.shared.save(formOutput)
        }
        
        return FoodForm(didSave: didSaveFood)
    }
    
    var recipeForm: some View {
        func didSaveFood(_ formOutput: FoodFormOutput) {
//            Haptics.successFeedback()
//            FoodFormManager.shared.save(formOutput)
        }
        
        return ParentFoodForm(forRecipe: true)
    }

    var plateForm: some View {
        func didSaveFood(_ formOutput: FoodFormOutput) {
//            Haptics.successFeedback()
//            FoodFormManager.shared.save(formOutput)
        }
        
        return ParentFoodForm(forRecipe: false)
    }

    func macrosView(for food: Food) -> some View {
        Text("Macros for: \(food.name)")
            .presentationDetents([.medium, .large])
    }
    
    var trailingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            addMenu
        }
    }
    
    var addMenu: some View {
        var label: some View {
            Image(systemName: "plus")
                .frame(width: 50, height: 50, alignment: .trailing)
        }
        
        var addFoodButton: some View {
            Button {
                didTapAddFood()
            } label: {
                Label("Food", systemImage: FoodType.food.systemImage)
            }
        }
        
        var scanFoodLabelButton: some View {
            Button {
                didTapScanFoodLabel()
            } label: {
                Label("Scan Food Label", systemImage: "text.viewfinder")
            }
        }
        
        var addPlateButton: some View {
            Button {
                didTapAddPlate()
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
}
