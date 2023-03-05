import SwiftUI
import PrepDataTypes
import FoodLabelScanner

class DensityFormModel: ObservableObject {
    
    let handleNewDensity: (FoodDensity?) -> ()
    let initialField: Field?
    
    @Published var weightAmount: Double? = nil
    @Published var weightUnit: WeightUnit = .g
    @Published var volumeAmount: Double? = nil
    @Published var volumeUnit: VolumeUnit = .cup

    init(
        initialField: Field?,
        handleNewDensity: @escaping (FoodDensity?) -> Void
    ) {
        self.handleNewDensity = handleNewDensity
        self.initialField = initialField
        
        if let initialField, let initialDensity = initialField.foodDensity {
            self.weightAmount = initialDensity.weightAmount
            self.weightUnit = initialDensity.weightUnit
            self.volumeAmount = initialDensity.volumeAmount
            self.volumeUnit = initialDensity.volumeExplicitUnit.volumeUnit
        }
    }
    
    func save() {
        handleNewDensity(foodDensity)
    }
    
    var foodDensity: FoodDensity? {
        guard let weightAmount, let volumeAmount else { return nil }
        return FoodDensity(
            weightAmount,
            weightUnit,
            volumeAmount,
            volumeUnit.volumeExplicitUnit
        )
    }
    
    var isEditing: Bool {
        initialField?.isValid == true
    }
    
    var title: String {
        "Unit Conversion"
//        isEditing ? "Edit Conversion" : "Set Conversion"
    }
    
    var saveButtonTitle: String {
        isEditing ? "Save" : "Add"
    }

    var matchesInitialField: Bool {
        guard let initialDensity = initialField?.foodDensity else { return false }
        return initialDensity == self.foodDensity
    }
    
    var weightDescription: String {
        guard let weightAmount else { return "" }
        return "\(weightAmount.cleanAmount) \(weightUnit.shortDescription)"
    }

    var volumeDescription: String {
        guard let volumeAmount else { return "" }
        return "\(volumeAmount.cleanAmount) \(volumeUnit.shortDescription)"
    }

    var hasMissingRequiredFields: Bool {
        weightAmount == nil || volumeAmount == nil
    }
    
    var shouldDisableDone: Bool {
        if matchesInitialField {
            return true
        }
        
        if hasMissingRequiredFields {
            return true
        }
        return false
    }
}
