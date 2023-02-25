import Foundation
import PrepDataTypes

enum DietNutrientGoal: CaseIterable {
    case fixed
    case quantityPerBodyMass
    case quantityPerEnergy
    case percentageOfEnergy
    
    init?(goalViewModel: GoalViewModel) {
        switch goalViewModel.nutrientGoalType {
        case .fixed:
            self = .fixed
        case .quantityPerBodyMass:
            self = .quantityPerBodyMass
        case .percentageOfEnergy:
            self = .percentageOfEnergy
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
        case .quantityPerEnergy:
            return "\(unit) / energy"
        case .percentageOfEnergy:
            return "% of energy"
        }
    }
    
    func pickerDescription(nutrientUnit: NutrientUnit) -> String {
        switch self {
        case .fixed, .quantityPerBodyMass, .quantityPerEnergy:
            return nutrientUnit.shortDescription
        case .percentageOfEnergy:
            return "% of energy"
        }
    }
}
