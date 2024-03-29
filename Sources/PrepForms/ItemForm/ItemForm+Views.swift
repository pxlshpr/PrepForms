import SwiftUI
import PrepDataTypes
import PrepCoreDataStack
import SwiftHaptics
import PrepViews
import SwiftUISugar

extension ItemForm {

    var scrollView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Group {
                    foodButton
                    if let dayMeal = model.dayMeal {
                        mealButton(dayMeal: dayMeal)
                    }
                }
                .padding(.horizontal, 20)
                if hasAppeared {
                    portionAwareness
                        .transition(.opacity)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Spacer()
                    .frame(height: bottomHeight)
            }
        }
        .scrollContentBackground(.hidden)
        .background(background)
    }
    
    var saveLayer: some View {
        VStack {
            Spacer()
            VStack(spacing: 0) {
                Divider()
                amountButton
                stepButtons
                    .padding(.bottom, 10)
                saveButton
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 34)
            .background(
                Color.clear
                    .background(.thinMaterial)
            )
            .readSize { size in
                cprint("bottomHeight is: \(size.height)")
                bottomHeight = size.height / 2.0
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    //MARK: - Sheets
    @ViewBuilder
    var quantityForm: some View {
        if let food = model.food {
            QuantityForm(
                food: food,
                double: model.amountValue.value,
                unit: model.unit.formUnit
            ) { double, unit in
                model.amount = double
                model.didPickUnit(unit)
            }
        }
    }
        
    var mealPicker: some View {
        MealPicker(didTapDismiss: {
            actionHandler(.dismiss)
        }, didTapMeal: { pickedMeal in
            NotificationCenter.default.post(
                name: .didPickDayMeal,
                object: nil,
                userInfo: [Notification.Keys.dayMeal: pickedMeal]
            )
        })
        .environmentObject(model)
    }

    //MARK: - Cells
    func foodCell(_ food: Food) -> some View {
        var emoji: some View {
            Text(food.emoji)
        }
        
        var macroColor: Color {
            return food.primaryMacro.textColor(for: colorScheme)
        }
        
        var detailTexts: some View {
            var view = Text("")
            if let detail = food.detail, !detail.isEmpty {
                view = view
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                + Text(detail)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            if let brand = food.brand, !brand.isEmpty {
                view = view
                + Text(food.hasDetail ? ", " : "")
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                + Text(brand)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
            }
            return view
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        
        return ZStack {
            HStack {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Spacer().frame(width: 2)
                        HStack(spacing: 4) {
                            Text("Food")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(.tertiaryLabel))
                        }
                        Spacer()
                        emoji
//                        disclosureArrow
                    }
                    VStack(alignment: .leading) {
                        Text(food.name)
                            .foregroundColor(macroColor)
                            .font(.system(size: 28, weight: .medium, design: .rounded))
                            .multilineTextAlignment(.leading)
                        if food.hasDetails {
                            detailTexts
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 13)
        .padding(.top, 13)
//        .background(Color(.secondarySystemGroupedBackground))
        .background(FormCellBackground())
        .cornerRadius(10)
        .padding(.bottom, 10)
    }
    
    func mealCell(dayMeal: DayMeal) -> some View {
        ZStack {
            HStack {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Spacer().frame(width: 2)
                        HStack(spacing: 4) {
                            Text("Meal")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(.tertiaryLabel))
                        }
                        Spacer()
                        Text(dayMeal.timeString)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .bold()
                            .foregroundColor(Color(.secondaryLabel))
//                        disclosureArrow
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(dayMeal.name)
                            .font(.system(size: 28, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 13)
        .padding(.top, 13)
//        .background(Color(.secondarySystemGroupedBackground))
        .background(FormCellBackground())
        .cornerRadius(10)
        .padding(.bottom, 10)
    }
    
    //MARK: - Components

    var portionAwareness: some View {
        let lastUsedGoalSetBinding = Binding<GoalSet?>(
            get: {
                DataManager.shared.lastUsedGoalSet
            },
            set: { _ in }
        )
        
        var itemPortion: some View {
            let itemBinding = Binding<MealItem>(
                get: { model.mealItem! },
                set: { _ in }
            )
            let dayMealBinding = Binding<DayMeal>(
                get: { model.dayMeal! },
                set: { _ in }
            )
            return ItemPortion(
                foodItem: itemBinding,
                meal: dayMealBinding,
                day: $model.day,
                lastUsedGoalSet: lastUsedGoalSetBinding,
                units: UserManager.units,
//                biometrics: model.day?.biometrics //TODO: We need to load the Day's biometrics here once supported
                biometrics: UserManager.biometrics,
                didTapGoalSetButton: didTapGoalSetButton
            )
        }
        
        var ingredientPortion: some View {
            let itemBinding = Binding<IngredientItem>(
                get: { model.ingredientItem! },
                set: { _ in }
            )
            return IngredientPortion(
                ingredientItem: itemBinding,
                lastUsedGoalSet: lastUsedGoalSetBinding,
                units: UserManager.units,
//                biometrics: model.day?.biometrics //TODO: We need to load the Day's biometrics here once supported
                biometrics: UserManager.biometrics,
                didTapGoalSetButton: didTapGoalSetButton
            )
        }
        
        return Group {
            if !model.forIngredient, model.mealItem != nil {
                itemPortion
            } else if model.ingredientItem != nil {
                ingredientPortion
            } else {
                EmptyView()
            }
        }
        .padding(.top, 15)
    }
    
    var stepButtons: some View {
        func stepButton(step: Int) -> some View {
            var number: String {
                "\(abs(step))"
            }
            var sign: String {
                step > 0 ? "+" : "-"
            }
            
            var disabled: Bool {
                !model.amountCanBeStepped(by: step)
            }
            var fontWeight: Font.Weight {
//                disabled ? .thin : .semibold
                .semibold
            }
            
            var label: some View {
                HStack(spacing: 1) {
                    Text(sign)
                        .font(.system(.body, design: .rounded, weight: .regular))
//                        .font(.system(size: 13, weight: .regular, design: .rounded))
                    Text(number)
                        .font(.system(.callout, design: .rounded, weight: fontWeight))
//                        .font(.system(size: 11, weight: fontWeight, design: .rounded))
                }
                .monospacedDigit()
                .frame(maxWidth: .infinity)
                .frame(height: 44)
    //            .frame(width: 44, height: 44)
                .foregroundColor(.accentColor)
                .background(
                    ZStack {
                        if colorScheme == .dark {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(Color(.systemFill).opacity(0.5))
                        }
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(Color.accentColor.opacity(colorScheme == .dark ? 0.1 : 0.15))
                    }
                )
            }
            
            var label_legacy: some View {
                HStack(spacing: 1) {
                    Text(sign)
                        .font(.system(.caption, design: .rounded, weight: .regular))
//                        .font(.system(size: 13, weight: .regular, design: .rounded))
                    Text(number)
                        .font(.system(.footnote, design: .rounded, weight: fontWeight))
//                        .font(.system(size: 11, weight: fontWeight, design: .rounded))
                }
                .monospacedDigit()
                .foregroundColor(.accentColor)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
    //            .frame(width: 44, height: 44)
                .background(colorScheme == .light ? .ultraThickMaterial : .ultraThinMaterial)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(
                            Color.accentColor.opacity(0.7),
                            style: StrokeStyle(lineWidth: 0.5, dash: [3])
                        )
                )
            }
            
            return Button {
                Haptics.feedback(style: .soft)
                model.stepAmount(by: step)
            } label: {
                label
            }
            .disabled(disabled)
        }
        
        return HStack {
            stepButton(step: -50)
            stepButton(step: -10)
            stepButton(step: -1)
            stepButton(step: 1)
            stepButton(step: 10)
            stepButton(step: 50)
        }
    }
    
    var amountField: some View {
        HStack {
            Text("Quantity")
                .font(.system(.title3, design: .rounded, weight: .semibold))
//                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(Color(.secondaryLabel))
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Color.clear
                    .animatedMealItemQuantity(
                        value: model.internalAmountDouble!,
                        unitString: model.unitDescription,
                        isAnimating: model.isAnimatingAmountChange
                    )
            }
        }
        .padding(.vertical, 15)
    }
    
    //MARK: - Buttons
    
    var closeButton: some View {
        Button {
            tappedClose()
        } label: {
            CloseButtonLabel()
        }
    }

    var deleteButton: some View {
        var label: some View {
            HStack {
                Image(systemName: "trash.circle.fill")
                    .font(.system(size: 24))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        Color.red.opacity(0.75),
                        Color(.quaternaryLabel).opacity(0.5)
                    )
            }
        }

        return Button {
            tappedDelete()
        } label: {
            label
        }
    }
    
    var saveButton: some View {
        var saveIsDisabled: Bool {
            !model.isDirty
        }
        
        return Button {
            tappedSave()
        } label: {
            Text(model.saveButtonTitle)
                .bold()
                .foregroundColor((colorScheme == .light && saveIsDisabled) ? .black : .white)
                .frame(height: 52)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundStyle(Color.accentColor.gradient)
                )
        }
        .buttonStyle(.borderless)
        .disabled(saveIsDisabled)
        .opacity(saveIsDisabled ? (colorScheme == .light ? 0.2 : 0.2) : 1)
    }

    @ViewBuilder
    var foodButton: some View {
        if let food = model.food {
            Button {
                Haptics.feedback(style: .soft)
                if model.isRootInNavigationStack {
                    model.path.append(.food)
                } else {
                    dismiss()
//                    model.path.removeLast()
                }
            } label: {
                foodCell(food)
            }
        }
    }
    
    func mealButton(dayMeal: DayMeal) -> some View {
        Button {
            Haptics.feedback(style: .soft)
            showingMealPicker = true
        } label: {
            mealCell(dayMeal: dayMeal)
        }
    }
    
    var amountButton: some View {
        Button {
            Haptics.feedback(style: .soft)
            tappedQuantity()
        } label: {
            amountField
        }
    }
    
    //MARK: - Helpers
    
    var disclosureArrow: some View {
        Image(systemName: "chevron.forward")
            .font(.system(size: 14))
            .foregroundColor(Color(.tertiaryLabel))
            .fontWeight(.semibold)
    }
    
    var background: some View {
        FormBackground()
            .edgesIgnoringSafeArea(.all)
    }
}
