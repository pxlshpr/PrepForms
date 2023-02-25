import Foundation

extension EnergyGoalForm {

    func appeared() {
        pickedMealEnergyGoalType = MealEnergyTypeOption(goalViewModel: goal) ?? .fixed
        pickedDietEnergyGoalType = DietEnergyTypeOption(goalViewModel: goal) ?? .fixed
        pickedDelta = EnergyDeltaOption(goalViewModel: goal) ?? .below
        refreshBool.toggle()
    }
    
    func dietEnergyGoalChanged(_ newValue: DietEnergyTypeOption) {
        goal.energyGoalType = self.energyGoalType
    }
    
    func mealEnergyGoalChanged(_ newValue: MealEnergyTypeOption) {
        goal.energyGoalType = self.energyGoalType
    }
    
    func deltaChanged(to newValue: EnergyDeltaOption) {
        goal.energyGoalType = self.energyGoalType
    }
}
