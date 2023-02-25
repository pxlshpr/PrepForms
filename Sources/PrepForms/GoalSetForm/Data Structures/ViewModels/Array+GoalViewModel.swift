import PrepDataTypes

extension Array where Element == GoalViewModel {
    var containsEnergy: Bool {
        contains(where: { $0.type.isEnergy })
    }
    
    func containsMacro(_ macro: Macro) -> Bool {
        contains(where: { $0.type.macro == macro })
    }
    
    func containsMicro(_ nutrientType: NutrientType) -> Bool {
        contains(where: { $0.type.nutrientType == nutrientType })
    }
    
    func update(with goal: GoalViewModel) {
        guard let index = firstIndex(where: {
            if goal.type.isEnergy && $0.type.isEnergy { return true }
            if goal.type.macro == $0.type.macro { return true }
            if goal.type.nutrientType == $0.type.nutrientType { return true }
            return false
        }) else {
            return
        }
        self[index].lowerBound = goal.lowerBound
    }
}
