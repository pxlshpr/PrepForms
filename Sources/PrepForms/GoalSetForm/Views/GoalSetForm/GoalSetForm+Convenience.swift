import SwiftUI
import PrepDataTypes

extension GoalSetForm {
    func hasUnusedMicros(in group: NutrientTypeGroup, matching searchString: String) -> Bool {
        group.nutrients.contains(where: {
            if searchString.isEmpty {
                return !hasMicronutrient($0)
            } else {
                return !hasMicronutrient($0) && $0.matchesSearchString(searchString)
            }
        })
    }
    
    func hasMicronutrient(_ nutrientType: NutrientType) -> Bool {
        goalSetViewModel.containsMicro(nutrientType)
    }
}
