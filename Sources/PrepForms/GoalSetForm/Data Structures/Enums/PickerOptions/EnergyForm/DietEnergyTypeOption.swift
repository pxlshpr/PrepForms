import Foundation
import PrepDataTypes

enum DietEnergyTypeOption: String, CaseIterable, Identifiable {
    
    case fixed
    case fromMaintenance
    case percentageFromMaintenance
    
    var id: String { rawValue }
    
    func description(energyUnit: EnergyUnit) -> String {
        switch self {
        case .fixed:
            return energyUnit.shortDescription
        case .fromMaintenance:
            return energyUnit.shortDescription + " from maintenance"
        case .percentageFromMaintenance:
            return "% from maintenance"
        }
    }
    
    func shortDescription(energyUnit: EnergyUnit) -> String {
        switch self {
        case .fixed, .fromMaintenance:
            return energyUnit.shortDescription
        case .percentageFromMaintenance:
            return "%"
        }
    }
    
    init?(goalModel: GoalModel) {
        switch goalModel.energyGoalType {
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
