import Foundation
import PrepDataTypes

enum DietEnergyTypeOption: CaseIterable {
    
    case fixed
    case fromMaintenance
    case percentageFromMaintenance
    
    func description(userEnergyUnit energyUnit: EnergyUnit) -> String {
        switch self {
        case .fixed:
            return energyUnit.shortDescription
        case .fromMaintenance:
            return energyUnit.shortDescription + " from maintenance"
        case .percentageFromMaintenance:
            return "% from maintenance"
        }
    }
    
    func shortDescription(userEnergyUnit energyUnit: EnergyUnit) -> String {
        switch self {
        case .fixed, .fromMaintenance:
            return energyUnit.shortDescription
        case .percentageFromMaintenance:
            return "%"
        }
    }
    
    init?(goalViewModel: GoalViewModel) {
        switch goalViewModel.energyGoalType {
        case .fixed:
            self = .fixed
        case .fromMaintenance:
            self = .fromMaintenance
        case .percentFromMaintenance:
            self = .percentageFromMaintenance
        default:
            return nil
        }
    }
}
