//import Foundation
//import PrepDataTypes
//
//enum DietNutrientGoal: String, CaseIterable, Identifiable {
//    case fixed
//    case quantityPerBodyMass
//    case quantityPerEnergy
//    case percentageOfEnergy
//    
//    var id: String { rawValue }
//    
//    init?(goalModel: GoalModel) {
//        switch goalModel.nutrientGoalType {
//        case .fixed:
//            self = .fixed
//        case .quantityPerBodyMass:
//            self = .quantityPerBodyMass
//        case .percentageOfEnergy:
//            self = .percentageOfEnergy
//        default:
//            return nil
//        }
//    }
//    
//    func menuDescription(nutrientUnit: NutrientUnit) -> String {
//        let unit = nutrientUnit.shortDescription
//        switch self {
//        case .fixed:
//            return unit
//        case .quantityPerBodyMass:
//            return "\(unit) / body mass"
//        case .quantityPerEnergy:
//            return "\(unit) / energy goal"
//        case .percentageOfEnergy:
//            return "% of energy goal"
//        }
//    }
//    
//    func pickerDescription(nutrientUnit: NutrientUnit) -> String {
//        switch self {
//        case .fixed, .quantityPerBodyMass, .quantityPerEnergy:
//            return nutrientUnit.shortDescription
//        case .percentageOfEnergy:
//            return "% of energy goal"
//        }
//    }
//}
