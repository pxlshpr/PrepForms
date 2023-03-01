import SwiftUI
import PrepDataTypes
import PrepCoreDataStack
import PrepViews

extension ItemForm {
    public class ViewModel: ObservableObject {
        
        let date: Date
        
        @Published var path: [ItemFormRoute]
        
        @Published var food: Food?
        @Published var dayMeals: [DayMeal]
        
        @Published var unit: FoodQuantity.Unit = .serving
        
        @Published var internalAmountDouble: Double? = 1
        @Published var internalAmountString: String = "1"
        
        @Published var dayMeal: DayMeal
        
        @Published var day: Day? = nil
        
        @Published var mealFoodItem: MealFoodItem
        
        @Published var isAnimatingAmountChange = false
        var startedAnimatingAmountChangeAt: Date = Date()
        
        let existingMealFoodItem: MealFoodItem?
        let initialDayMeal: DayMeal?
        
        let isRootInNavigationStack: Bool
        
        public init(
            existingMealFoodItem: MealFoodItem?,
            date: Date,
            dayMeal: DayMeal? = nil,
            food: Food? = nil,
            amount: FoodValue? = nil,
            initialPath: [ItemFormRoute] = []
        ) {
            self.path = initialPath
            self.date = date
            
            let day = DataManager.shared.day(for: date)
            self.day = day
            self.dayMeals = day?.meals ?? []
            
            self.food = food
            
            let dayMealToSet = dayMeal ?? DayMeal(name: "New Meal", time: Date().timeIntervalSince1970)
            self.dayMeal = dayMealToSet
            self.initialDayMeal = dayMeal
            
            //TODO: Handle this in a better way
            /// [ ] Try making `mealFoodItem` nil and set it as that if we don't get a food here
            /// [ ] Try and get this fed in with an existing `FoodItem`, from which we create this when editing!
            self.mealFoodItem = MealFoodItem(
                food: food ?? Food.placeholder,
                amount: .init(0, .g),
                isSoftDeleted: false,
                energyInKcal: 0,
                mealId: dayMealToSet.id
            )
            
            self.existingMealFoodItem = existingMealFoodItem
            
            self.isRootInNavigationStack = existingMealFoodItem != nil || food != nil
            
            if let amount, let food,
               let unit = FoodQuantity.Unit(foodValue: amount, in: food)
            {
                self.amount = amount.value
                self.unit = unit
            } else {
                setDefaultUnit()
            }
            setFoodItem()
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(didPickDayMeal),
                name: .didPickDayMeal,
                object: nil
            )
        }
    }
}

extension ItemForm.ViewModel {
    
    @objc func didPickDayMeal(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let dayMeal = userInfo[Notification.Keys.dayMeal] as? DayMeal
        else { return }
        
        self.dayMeal = dayMeal
    }

    //TODO: MealItemAdd – Use this when setting food
    func setFood(_ food: Food) {
        self.food = food
        setDefaultUnit()
        setFoodItem()
    }
    
    func setDefaultUnit() {
        guard let food else { return }
        let amountQuantity = DataManager.shared.lastUsedQuantity(for: food) ?? food.defaultQuantity
        guard let amountQuantity else { return }
        
        self.amount = amountQuantity.value
        self.unit = amountQuantity.unit
    }
    
    var amountIsValid: Bool {
        guard let amount else { return false }
        return amount > 0
    }
    
    var isDirty: Bool {        
        guard let existing = existingMealFoodItem else {
            return amountIsValid
        }
        
        return existing.food.id != food?.id
        || (existing.amount != amountValue && amountIsValid)
        || initialDayMeal?.id != dayMeal.id
    }

    var amount: Double? {
        get {
            return internalAmountDouble
        }
        set {
            internalAmountDouble = newValue
            internalAmountString = newValue?.cleanAmount ?? ""
            setFoodItem()
        }
    }

    var animatedAmount: Double? {
        get {
            return internalAmountDouble
        }
        set {
            withAnimation {
                internalAmountDouble = newValue
            }
            internalAmountString = newValue?.cleanAmount ?? ""
            setFoodItem()
        }
    }

    func setFoodItem() {
        guard let food else { return }
        self.mealFoodItem = MealFoodItem(
            id: existingMealFoodItem?.id ?? UUID(),
            food: food,
            amount: amountValue,
            markedAsEatenAt: existingMealFoodItem?.markedAsEatenAt ?? nil,
            sortPosition: existingMealFoodItem?.sortPosition ?? 1,
            isSoftDeleted: existingMealFoodItem?.isSoftDeleted ?? false,
            energyInKcal: existingMealFoodItem?.energyInKcal ?? 0,
            mealId: dayMeal.id
        )
    }
    
    var amountString: String {
        get { internalAmountString }
        set {
            guard !newValue.isEmpty else {
                internalAmountDouble = nil
                internalAmountString = newValue
                setFoodItem()
                return
            }
            guard let double = Double(newValue) else {
                return
            }
            self.internalAmountDouble = double
            self.internalAmountString = newValue
            setFoodItem()
        }
    }
    
    var timelineItems: [TimelineItem] {
        dayMeals.map { TimelineItem(dayMeal: $0) }
    }
    
    var amountTitle: String? {
        guard let internalAmountDouble else {
            return nil
        }
        return "\(internalAmountDouble.cleanAmount) \(unit.shortDescription)"
    }
    
    var amountDetail: String? {
        //TODO: Get the primary equivalent value here
        ""
    }
    
    var isEditing: Bool {
        existingMealFoodItem != nil
    }
    
    var savePrefix: String {
        dayMeal.time < Date().timeIntervalSince1970 ? "Log" : "Prep"
    }
    
    var navigationTitle: String {
        guard !isEditing else {
            return "Edit Entry"
        }
        return "\(savePrefix) Food"
    }
    
    var saveButtonTitle: String {
//        isEditing ? "Save" : "Add"
        isEditing ? "Save" : "\(savePrefix) this Food"
    }
    
    func stepAmount(by step: Int) {
        programmaticallyChangeAmount(to: (amount ?? 0) + Double(step))
    }
    
    func programmaticallyChangeAmount(to newAmount: Double) {
        isAnimatingAmountChange = true
        startedAnimatingAmountChangeAt = Date()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
//            self.amount = newAmount
            self.animatedAmount = newAmount

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                guard Date().timeIntervalSince(self.startedAnimatingAmountChangeAt) >= 0.55
                else { return }
                self.isAnimatingAmountChange = false
            }
        }
    }
    
    func amountCanBeStepped(by step: Int) -> Bool {
        let amount = self.internalAmountDouble ?? 0
        return amount + Double(step) > 0
    }
    
    var unitDescription: String {
        unit.shortDescription
    }
    
    var shouldShowServingInUnitPicker: Bool {
        guard let food else { return false }
        return food.info.serving != nil
    }
    
    var foodSizes: [FormSize] {
        food?.formSizes ?? []
    }
    
    var servingDescription: String? {
        food?.servingDescription(using: DataManager.shared.userVolumeUnits)
    }
    
    func didPickUnit(_ formUnit: FormUnit) {
        guard
            let food,
            let unit = FoodQuantity.Unit(
                formUnit: formUnit,
                food: food,
                userVolumeUnits: DataManager.shared.userVolumeUnits
            )
        else {
            return
        }
        
        self.unit = unit
        setFoodItem()
    }
    
    func didPickQuantity(_ quantity: FoodQuantity) {
//        programmaticallyChangeAmount(to: quantity.value)
        self.amount = quantity.value
        self.unit = quantity.unit
        setFoodItem()
    }
    var amountHeaderString: String {
        unit.unitType.description
    }
    
    var shouldShowWeightUnits: Bool {
        food?.canBeMeasuredInWeight ?? false
    }
    
    var shouldShowVolumeUnits: Bool {
        food?.canBeMeasuredInVolume ?? false
    }
    
    var amountValue: FoodValue {
        FoodValue(
            value: amount ?? 0,
            foodQuantityUnit: unit,
            userUnits: DataManager.shared.user?.units ?? .standard
        )
    }
    
//    var foodItemBinding: Binding<MealFoodItem> {
//        Binding<MealFoodItem>(
//            get: {
//                cprint("Getting MealFoodItem")
//                return MealFoodItem(
//                    food: self.food,
//                    amount: self.amountValue
//                )
//            },
//            set: { _ in }
//        )
//    }
//
//    var dayMeal: DayMeal? {
//        guard let meal else { return nil }
//        return DayMeal(from: meal)
//    }
}

extension FoodValue {
    init(
        value: Double,
        foodQuantityUnit unit: FoodQuantity.Unit,
        userUnits: UserUnits
    ) {
        
        let volumeExplicitUnit: VolumeExplicitUnit?
        if let volumeUnit = unit.formUnit.volumeUnit {
            volumeExplicitUnit = userUnits.volume.volumeExplicitUnit(for: volumeUnit)
        } else {
            volumeExplicitUnit = nil
        }

        let sizeUnitVolumePrefixExplicitUnit: VolumeExplicitUnit?
        if let volumeUnit = unit.formUnit.sizeUnitVolumePrefixUnit {
            sizeUnitVolumePrefixExplicitUnit = userUnits.volume.volumeExplicitUnit(for: volumeUnit)
        } else {
            sizeUnitVolumePrefixExplicitUnit = nil
        }

        self.init(
            value: value,
            unitType: unit.unitType,
            weightUnit: unit.formUnit.weightUnit,
            volumeExplicitUnit: volumeExplicitUnit,
            sizeUnitId: unit.formUnit.size?.id,
            sizeUnitVolumePrefixExplicitUnit: sizeUnitVolumePrefixExplicitUnit
        )
    }
}

extension ItemForm.ViewModel {
    var equivalentQuantities: [FoodQuantity] {
        guard let currentQuantity else { return [] }
        let quantities = currentQuantity.equivalentQuantities(using: DataManager.shared.userVolumeUnits)
        return quantities
    }
    
    var currentQuantity: FoodQuantity? {
        guard
            let food,
            let internalAmountDouble
        else { return nil }
        
        return FoodQuantity(
            value: internalAmountDouble,
            unit: unit,
            food: food
        )
    }    
}

extension ItemForm.ViewModel: NutritionSummaryProvider {
    public var energyAmount: Double {
        mealFoodItem.scaledValue(for: .energy)
    }
    
    public var carbAmount: Double {
        mealFoodItem.scaledValue(for: .carb)
    }
    
    public var fatAmount: Double {
        mealFoodItem.scaledValue(for: .fat)
    }
    
    public var proteinAmount: Double {
        mealFoodItem.scaledValue(for: .protein)
    }
}

extension Food {
    static var placeholder: Food {
        self.init(
            id: UUID(),
            type: .food,
            name: "",
            emoji: "",
            detail: "",
            brand: "",
            numberOfTimesConsumedGlobally: 0,
            numberOfTimesConsumed: 0,
            lastUsedAt: 0,
            firstUsedAt: 0,
            info: .init(
                amount: .init(.init(0)),
                nutrients: .init(
                    energyInKcal: 0,
                    carb: 0,
                    protein: 0,
                    fat: 0,
                    micros: []
                ),
                sizes: [],
                barcodes: []
            ),
            publishStatus: .hidden,
            jsonSyncStatus: .synced,
            childrenFoods: [],
            dataset: nil,
            barcodes: nil,
            syncStatus: .synced,
            updatedAt: 0
        )
    }
}
