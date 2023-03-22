//import Foundation
//
//extension EnergyGoalForm {
//
//    func appeared() {
//        pickedMealEnergyGoalType = MealEnergyTypeOption(goalModel: goal) ?? .fixed
//        pickedDietEnergyGoalType = DietEnergyTypeOption(goalModel: goal) ?? .fixed
//        pickedDelta = EnergyDeltaOption(goalModel: goal) ?? .below
//        refreshBool.toggle()
//    }
//    
//    func dietEnergyGoalChanged(_ newValue: DietEnergyTypeOption) {
//        goal.energyGoalType = self.energyGoalType
//    }
//    
//    func mealEnergyGoalChanged(_ newValue: MealEnergyTypeOption) {
//        goal.energyGoalType = self.energyGoalType
//    }
//    
//    func deltaChanged(to newValue: EnergyDeltaOption) {
//        goal.energyGoalType = self.energyGoalType
//    }
//}
