//import SwiftUI
//import SwiftUISugar
//import SwiftHaptics
//import PrepDataTypes
//
//struct EnergyGoalForm: View {
//    
//    @Environment(\.dismiss) var dismiss
//    
//    @EnvironmentObject var model: GoalSetForm.Model
//    @ObservedObject var goal: GoalModel
//    @State var pickedMealEnergyGoalType: MealEnergyTypeOption
//    @State var pickedDietEnergyGoalType: DietEnergyTypeOption
//    @State var pickedDelta: EnergyDeltaOption
//    
//    @State var showingTDEEForm: Bool = false
//    
//    @State var refreshBool = false
//    @State var shouldResignFocus = false
//    
//    let didTapDelete: (GoalModel) -> ()
//    
//    init(goal: GoalModel, didTapDelete: @escaping ((GoalModel) -> ())) {
//        self.goal = goal
//        //TODO: This isn't being updated after creating it and going back to the GoalSetForm
//        // We may need to use a binding to the goal here instead and have bindings on the `GoalModel` that set and return the picker options (like MealEnergyGoalTypePickerOption). That would also make things cleaner and move it to the view model.
//        let mealEnergyGoalType = MealEnergyTypeOption(goalModel: goal) ?? .fixed
//        let dietEnergyGoalType = DietEnergyTypeOption(goalModel: goal) ?? .fixed
//        let delta = EnergyDeltaOption(goalModel: goal) ?? .below
//        _pickedMealEnergyGoalType = State(initialValue: mealEnergyGoalType)
//        _pickedDietEnergyGoalType = State(initialValue: dietEnergyGoalType)
//        _pickedDelta = State(initialValue: delta)
//        
//        self.didTapDelete = didTapDelete
//    }
//}
