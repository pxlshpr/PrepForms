//import Foundation
//import PrepDataTypes
//
//enum MealNutrientGoal: String, CaseIterable, Identifiable {
//    case fixed
//    case quantityPerBodyMass
//    case quantityPerWorkoutDuration
//    
//    var id: String { rawValue }
//    
//    init?(goalModel: GoalModel) {
//        switch goalModel.nutrientGoalType {
//        case .fixed:
//            self = .fixed
//        case .quantityPerWorkoutDuration:
//            self = .quantityPerWorkoutDuration
//        case .quantityPerBodyMass:
//            self = .quantityPerBodyMass
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
//        case .quantityPerWorkoutDuration:
//            return "\(unit) / workout duration"
//        }
//    }
//    
//    func pickerDescription(nutrientUnit: NutrientUnit) -> String {
//        switch self {
//        case .fixed, .quantityPerBodyMass, .quantityPerWorkoutDuration:
//            return nutrientUnit.shortDescription
//        }
//    }
//}
