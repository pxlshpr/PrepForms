import SwiftUI
import PrepDataTypes
import SwiftHaptics
import SwiftSugar
import PrepCoreDataStack

extension ParentFoodForm {
    class Model: ObservableObject {
        
        let forRecipe: Bool
        let existingFood: Food?
        
        @Published var items: [IngredientItem] = []
        @Published var itemsWithRecalculatedBadges: [IngredientItem] = []
        @Published var sortOrder: IngredientSortOrder = .none
        @Published var itemFormModel: ItemFormModel

        @Published var presentedSheet: ParentFoodFormSheet? = nil
        @Published var showingFoodLabel: Bool
        @Published var showingCancelConfirmation = false
        @Published var showingSaveSheet = false

        
        @Published var showingBadges: Bool
        @Published var showingEmojis: Bool
        @Published var showingDetails: Bool

        init(
            forRecipe: Bool,
            existingFood: Food? = nil
        ) {
            self.existingFood = existingFood
            self.forRecipe = forRecipe
            
            self.itemFormModel = ItemFormModel(
                existingIngredientItem: nil,
                parentFoodType: forRecipe ? .recipe : .plate
            )
            
            if let existingFood, let ingredientItems = existingFood.ingredientItems {
                showingFoodLabel = !ingredientItems.isEmpty
            } else {
                showingFoodLabel = false
            }

            showingBadges = UserManager.showingIngredientsBadges
            showingEmojis = UserManager.showingIngredientsEmojis
            showingDetails = UserManager.showingIngredientsDetails
            
            NotificationCenter.default.addObserver(self, selector: #selector(didUpdateUser), name: .didUpdateUser, object: nil)
        }
    }
}

extension ParentFoodForm.Model {
    var title: String {
        "\(isEditing ? "Edit" : "New") \(entityName)"
    }
    
    var entityName: String {
        forRecipe ? "Recipe" : "Plate"
    }
    
    var isEditing: Bool {
        existingFood != nil
    }
    
    var ingredientsTitle: String {
        forRecipe ? "Ingredients" : "Foods"
    }
    
    var addTitle: String {
        "Add \(forRecipe ? "an Ingredient" : "a Food")"
    }
    
    var isEmpty: Bool {
        items.isEmpty
    }
}

extension ParentFoodForm.Model {
    
    @objc func didUpdateUser(_ notification: Notification) {
        withAnimation {
            showingBadges = UserManager.showingIngredientsBadges
            showingEmojis = UserManager.showingIngredientsEmojis
            showingDetails = UserManager.showingIngredientsDetails
        }
    }
    
    func add(_ item: IngredientItem) {
        var item = item
        item.energyInKcal = item.scaledValueForEnergyInKcal
        self.items.append(item)
        resortItems()
    }

    func removeEditingItem() {
        guard let id = itemFormModel.existingIngredientItem?.id,
              let index = items.firstIndex(where: { $0.id == id })
        else { return }
        let _ = self.items.remove(at: index)
    }

    func update(_ item: IngredientItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else {
            return
        }
        var item = item
        item.energyInKcal = item.scaledValueForEnergyInKcal
        item.badgeWidth = 0 /// so that its animated properly when filled
        self.items[index] = item
        resortItems()
    }
    
    func prepareForAdding() {
        self.itemFormModel = ItemFormModel(
            existingIngredientItem: nil,
            parentFoodType: forRecipe ? .recipe : .plate
        )
    }

    func prepareForEditing(_ item: IngredientItem) {
        self.itemFormModel = ItemFormModel(
            existingIngredientItem: item,
            parentFoodType: forRecipe ? .recipe : .plate
        )
    }
    
    var sortBinding: Binding<IngredientSortOrder> {
        Binding<IngredientSortOrder>(
            get: { self.sortOrder },
            set: { newValue in
                Haptics.feedback(style: .soft)
                self.sortOrder = newValue
            }
        )
    }
    
    var sortOrderTitle: String {
        if sortOrder != .none {
            return "Sort: \(sortOrder.description)"
        } else {
            return "Sort"
        }
    }

    func resortItems() {
        switch sortOrder {
        case .name:
            items.sort(by: { $0.food.name < $1.food.name })
        case .energy:
            items.sort(by: { $0.energyInKcal > $1.energyInKcal })
        case .carbPortion:
            items.sort(by: { $0.food.carbPortion > $1.food.carbPortion })
        case .fatPortion:
            items.sort(by: { $0.food.fatPortion > $1.food.fatPortion })
        case .proteinPortion:
            items.sort(by: { $0.food.proteinPortion > $1.food.proteinPortion })
        default:
            break
        }
    }
    
    func recalculateBadgeWdiths(delay: Double = 0) {
        
        Task.detached(priority: .background) {
            try await sleepTask(delay, tolerance: 0.1)
            var copy = self.items
            
            let start = CFAbsoluteTimeGetCurrent()
            
            let energyValues = copy.energyValuesInKcalDecreasing
            for i in copy.indices {
                copy[i].badgeWidth = calculateMacrosIndicatorWidth(
                    for: copy[i].energyInKcal,
                    within: energyValues
                )
            }
            
            print("🔹 Took: \(CFAbsoluteTimeGetCurrent()-start)s")
            
            await MainActor.run { [copy] in
                self.itemsWithRecalculatedBadges = copy
//                self.items = copy
            }
        }
    }
    
    func present(_ sheet: ParentFoodFormSheet) {
        
        if presentedSheet != nil {
            presentedSheet = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                Haptics.feedback(style: .soft)
                self.presentedSheet = sheet
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

extension Array where Element == IngredientItem {
    var energyValuesInKcalDecreasing: [Double] {
        let scaled = self.map { $0.energyInKcal }
        let sorted = scaled.sorted { $0 > $1 }
        return sorted
    }
}
