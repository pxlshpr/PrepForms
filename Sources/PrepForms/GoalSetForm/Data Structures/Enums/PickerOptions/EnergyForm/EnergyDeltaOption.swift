//import Foundation
//
//enum EnergyDeltaOption: String, CaseIterable, Identifiable {
//    case below
//    case above
//    case around /// used for deviation, ie. plus or minus
//
//    var id: String { rawValue }
//    
//    var description: String {
//        switch self {
//        case .above:
//            return "above"
//        case .below:
//            return "below"
//        case .around:
////            return "above or below"
//            return "within"
//        }
//    }
//    
//    var systemImage: String {
//        switch self {
//        case .below:      return "arrow.turn.right.down"
//        case .above:      return "arrow.turn.right.up"
//        case .around:     return "arrow.left.and.right"
//        }
//    }
//
//    init?(goalModel: GoalModel) {
//        switch goalModel.energyGoalType {
//        case .fromMaintenance(_, let delta):
//            self = delta.deltaPickerOption
//        case .percentFromMaintenance(let delta):
//            self = delta.deltaPickerOption
//        default:
//            return nil
//        }
//    }
//}
