import SwiftUI
import SwiftUISugar
import SwiftHaptics
import PrepDataTypes

struct EnergyGoalForm: View {
    
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var viewModel: GoalSetViewModel
    @ObservedObject var goal: GoalViewModel
    @State var pickedMealEnergyGoalType: MealEnergyTypeOption
    @State var pickedDietEnergyGoalType: DietEnergyTypeOption
    @State var pickedDelta: EnergyDeltaOption
    
    @State var showingTDEEForm: Bool = false
    
    @State var refreshBool = false
    @State var shouldResignFocus = false
    
    let didTapDelete: (GoalViewModel) -> ()
    
    init(goal: GoalViewModel, didTapDelete: @escaping ((GoalViewModel) -> ())) {
        self.goal = goal
        //TODO: This isn't being updated after creating it and going back to the GoalSetForm
        // We may need to use a binding to the goal here instead and have bindings on the `GoalViewModel` that set and return the picker options (like MealEnergyGoalTypePickerOption). That would also make things cleaner and move it to the view model.
        let mealEnergyGoalType = MealEnergyTypeOption(goalViewModel: goal) ?? .fixed
        let dietEnergyGoalType = DietEnergyTypeOption(goalViewModel: goal) ?? .fixed
        let delta = EnergyDeltaOption(goalViewModel: goal) ?? .below
        _pickedMealEnergyGoalType = State(initialValue: mealEnergyGoalType)
        _pickedDietEnergyGoalType = State(initialValue: dietEnergyGoalType)
        _pickedDelta = State(initialValue: delta)
        
        self.didTapDelete = didTapDelete
    }
}
