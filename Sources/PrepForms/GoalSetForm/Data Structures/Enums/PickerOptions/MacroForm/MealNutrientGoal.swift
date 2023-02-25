import Foundation
import PrepDataTypes

enum MealNutrientGoal: CaseIterable {
    case fixed
    case quantityPerBodyMass
    case quantityPerWorkoutDuration
    
    init?(goalViewModel: GoalViewModel) {
        switch goalViewModel.nutrientGoalType {
        case .fixed:
            self = .fixed
        case .quantityPerWorkoutDuration:
            self = .quantityPerWorkoutDuration
        case .quantityPerBodyMass:
            self = .quantityPerBodyMass
        default:
            return nil
        }
    }
    
    func menuDescription(nutrientUnit: NutrientUnit) -> String {
        let unit = nutrientUnit.shortDescription
        switch self {
        case .fixed:
            return unit
        case .quantityPerBodyMass:
            return "\(unit) / body mass"
        case .quantityPerWorkoutDuration:
            return "\(unit) / workout duration"
        }
    }
    
    func pickerDescription(nutrientUnit: NutrientUnit) -> String {
        switch self {
        case .fixed, .quantityPerBodyMass, .quantityPerWorkoutDuration:
            return nutrientUnit.shortDescription
        }
    }
}
