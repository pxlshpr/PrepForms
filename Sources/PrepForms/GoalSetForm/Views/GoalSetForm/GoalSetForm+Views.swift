import SwiftUI
import PrepDataTypes
import PrepViews
import SwiftHaptics
import EmojiPicker
import SwiftUISugar

extension GoalSetForm {
    
    var shouldShowEnergyInPicker: Bool {
        !goalSetViewModel.goalViewModels.containsEnergy
    }
    
    func shouldShowMacroInPicker(_ macro: Macro) -> Bool {
        !goalSetViewModel.containsMacro(macro)
    }

    var nutrientsPicker: some View {
        NutrientsPicker(
            supportsEnergyAndMacros: true,
            shouldShowEnergy: shouldShowEnergyInPicker,
            shouldShowMacro: shouldShowMacroInPicker,
//            shouldDisableLastMacroOrEnergy: true,
            hasUnusedMicros: hasUnusedMicros,
            hasMicronutrient: hasMicronutrient,
            didAddNutrients: goalSetViewModel.didAddNutrients
        )
    }
    
    var emojiPicker: some View {
        EmojiPicker(
            focusOnAppear: false,
            includeCancelButton: true) { emoji in
                Haptics.successFeedback()
                showingEmojiPicker = false
                goalSetViewModel.emoji = emoji
            }
    }
    
    @ViewBuilder
    func goalForm(for goal: GoalViewModel) -> some View {
        if goal.type.isEnergy {
            EnergyGoalForm(goal: goal, didTapDelete: didTapDeleteOnGoal)
                .environmentObject(goalSetViewModel)
//                .onDisappear {
//                    isFocused = false
//                }
        } else if goal.type.isMacro {
            NutrientGoalForm(goal: goal, didTapDelete: didTapDeleteOnGoal)
                .environmentObject(goalSetViewModel)
        } else {
            NutrientGoalForm(goal: goal, didTapDelete: didTapDeleteOnGoal)
                .environmentObject(goalSetViewModel)
        }
    }
    
    func didTapDeleteOnGoal(_ goal: GoalViewModel) {
        goalSetViewModel.path = []
        withAnimation {
            goalSetViewModel.goalViewModels.removeAll(where: { $0.type.identifyingHashValue == goal.type.identifyingHashValue })
        }
    }
    
    
    var trailingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            closeButton
        }
    }
    
    var closeButton: some View {
        Button {
            Haptics.feedback(style: .soft)
            dismiss()
        } label: {
            CloseButtonLabel(forNavigationBar: true)
        }
    }
    
    //TODO: Get view model to only show this if we have goals that aren't fixed
    var calculatedButton: some View {
        Button {
            Haptics.feedback(style: .rigid)
            withAnimation {
                showingEquivalentValues.toggle()
            }
        } label: {
            Image(systemName: "equal.square\(showingEquivalentValues ? ".fill" : "")")
        }
    }
    
    @ViewBuilder
    var addButton: some View {
        if !goalSetViewModel.goalViewModels.isEmpty {
            Button {
                presentNutrientsPicker()
            } label: {
                Image(systemName: "plus")
            }
        }
    }

    @ViewBuilder
    var addCell: some View {
        if !goalSetViewModel.goalViewModels.isEmpty {
            addGoalsButton
        }
    }

    
    @ViewBuilder
    var emptyContent: some View {
        if goalSetViewModel.goalViewModels.isEmpty {
            emptyPrompt
        }
    }
    
    var emptyPrompt: some View {
        VStack {
            Text("You haven't added any goals yet")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(Color(.tertiaryLabel))
            addGoalsButton
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .foregroundColor(Color(.quaternarySystemFill))
        )
        .cornerRadius(10)
        .padding(.bottom, 10)
    }
    
    var addGoalsButton: some View {
        var label: some View {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Goals")
                    .fontWeight(.bold)
            }
            .foregroundColor(.accentColor)
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.accentColor.opacity(
                        colorScheme == .dark ? 0.1 : 0.15
                    ))
            )
        }
        
        var button: some View {
            Button {
                presentNutrientsPicker()
            } label: {
                label
            }
            .buttonStyle(.borderless)
        }
        
        return button
    }
    
    var addGoalsButton_legacy: some View {
        Button {
            presentNutrientsPicker()
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Goals")
            }
            .foregroundColor(.white)
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .foregroundColor(Color.accentColor)
            )
        }
        .buttonStyle(.borderless)
    }
    
    func presentNutrientsPicker() {
        Haptics.feedback(style: .soft)
        showingNutrientsPicker = true
    }
}
