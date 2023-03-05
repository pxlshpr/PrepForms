import Foundation
import PrepDataTypes

enum MealEnergyTypeOption: CaseIterable {
    
    case fixed
    
    func description(userEnergyUnit energyUnit: EnergyUnit) -> String {
        switch self {
        case .fixed: return energyUnit.shortDescription
        }
    }
    
    init?(goalModel: GoalModel) {
        switch goalModel.energyGoalType {
        case .fixed:
            self = .fixed
        default:
            return nil
        }
    }
}
