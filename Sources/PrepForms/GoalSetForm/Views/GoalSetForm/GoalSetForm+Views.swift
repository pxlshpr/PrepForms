import SwiftUI
import PrepDataTypes
import PrepViews
import SwiftHaptics
import EmojiPicker
import SwiftUISugar

extension GoalSetForm {
    
    var shouldShowEnergyInPicker: Bool {
        !model.goalModels.containsEnergy
    }
    
    func shouldShowMacroInPicker(_ macro: Macro) -> Bool {
        !model.containsMacro(macro)
    }

    var nutrientsPicker: some View {
        NutrientsPicker(
            supportsEnergyAndMacros: true,
            shouldShowEnergy: shouldShowEnergyInPicker,
            shouldShowMacro: shouldShowMacroInPicker,
//            shouldDisableLastMacroOrEnergy: true,
            hasUnusedMicros: hasUnusedMicros,
            hasMicronutrient: hasMicronutrient,
            didAddNutrients: model.didAddNutrients
        )
    }
    
    var emojiPicker: some View {
        EmojiPicker(
            focusOnAppear: false,
            includeCancelButton: true) { emoji in
                Haptics.successFeedback()
                presentedSheet = nil
                model.emoji = emoji
            }
    }
    
    func goalForm(_ goalModel: GoalModel) -> some View {
        GoalForm(
            goalModel: goalModel,
            didTapDelete: didTapDeleteOnGoal
        )
        .environmentObject(model)
//        if let goalModel = model.goalModelToShowFormFor {
//        } else {
//            EmptyView()
//        }
    }
    
    func didTapDeleteOnGoal(_ goalModel: GoalModel) {
        Haptics.feedback(style: .soft)
        presentedSheet = nil
        withAnimation {
            model.delete(goalModel)
        }
    }
    
    var trailingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            closeButton
                .blur(radius: model.showingWizardOverlay ? 5 : 0)
        }
    }
    
    var closeButton: some View {
        Button {
            Haptics.feedback(style: .soft)
            dismiss()
        } label: {
            CloseButtonLabel()
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
    
//    @ViewBuilder
//    var addButton: some View {
//        if !model.goalModels.isEmpty {
//            Button {
//                presentNutrientsPicker()
//            } label: {
//                Image(systemName: "plus")
//            }
//        }
//    }

    @ViewBuilder
    var addCell: some View {
        if !model.goalModels.isEmpty {
            HStack {
                addGoalsButton
                Spacer()
            }
        }
    }

    
    @ViewBuilder
    var emptyContent: some View {
        if model.goalModels.isEmpty {
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
        present(.nutrientsPicker)
//        showingNutrientsPicker = true
    }
}
