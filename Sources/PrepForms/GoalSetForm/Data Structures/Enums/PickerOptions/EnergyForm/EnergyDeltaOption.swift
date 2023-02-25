import Foundation

enum EnergyDeltaOption: CaseIterable {
    case below
    case above
    
    var description: String {
        switch self {
        case .above:
            return "above"
        case .below:
            return "below"
        }
    }
    
    init?(goalViewModel: GoalViewModel) {
        switch goalViewModel.energyGoalType {
        case .fromMaintenance(_, let delta):
            self = delta.deltaPickerOption
        case .percentFromMaintenance(let delta):
            self = delta.deltaPickerOption
        default:
            return nil
        }
    }
}
