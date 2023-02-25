import SwiftUI
import PrepDataTypes
import PrepCoreDataStack
import SwiftHaptics

struct MealItemFormNew: View {
    
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: MealItemViewModel
    @State var showingQuantityForm = false
    @State var showingFoodLabel = false
    @State var hasAppeared: Bool = false
    
    @State var bottomHeight: CGFloat = 0.0
    
    let tappedSave: () -> ()
    
    var body: some View {
        content
            .sheet(isPresented: $showingQuantityForm) { quantityForm }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    withAnimation {
                        hasAppeared = true
                    }
                }
            }
    }
    
    var content: some View {
        ZStack {
            scrollView
            saveLayer
        }
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
    
    var saveButton: some View {
        var saveIsDisabled: Bool {
            !viewModel.isDirty
        }
        
        return Button {
            tappedSave()
        } label: {
            Text(viewModel.saveButtonTitle)
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

    
    var scrollView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                Group {
                    foodButton
                    mealButton
//                    amountButton
//                    stepButtons
                }
                .padding(.horizontal, 20)
//                Divider()
//                    .padding(.top, 20)
                if hasAppeared {
                    portionAwareness
                        .transition(.opacity)
//                        .transition(.move(edge: .bottom))
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
    
    @ViewBuilder
    var foodButton: some View {
        if let food = viewModel.food {
            Button {
                Haptics.feedback(style: .soft)
                if viewModel.isRootInNavigationStack {
                    viewModel.path.append(.food)
                } else {
                    viewModel.path.removeLast()
                }
            } label: {
                foodCell(food)
            }
        }
    }
    
    var mealButton: some View {
        Button {
            Haptics.feedback(style: .soft)
            viewModel.path.append(.meal)
        } label: {
            mealCell
        }
    }
    
    var amountButton: some View {
        Button {
            Haptics.feedback(style: .soft)
            showingQuantityForm = true
        } label: {
//            amountCell
            amountField
        }
    }
    
    var portionAwareness: some View {
        let lastUsedGoalSetBinding = Binding<GoalSet?>(
            get: {
                DataManager.shared.lastUsedGoalSet
            },
            set: { _ in }
        )
        return PortionAwareness(
            foodItem: $viewModel.mealFoodItem,
            meal: $viewModel.dayMeal,
            day: $viewModel.day,
            lastUsedGoalSet: lastUsedGoalSetBinding,
            userUnits: DataManager.shared.user?.units ?? .standard,
//            bodyProfile: viewModel.day?.bodyProfile //TODO: We need to load the Day's bodyProfile here once supported
            bodyProfile: DataManager.shared.user?.bodyProfile,
            didTapGoalSetButton: didTapGoalSetButton
        )
        .padding(.top, 15)
    }
    
    func didTapGoalSetButton(forMeal: Bool) {
//        if forMeal {
//            showingMealTypesPicker = true
//        } else {
//            showingDietsPicker = true
//        }
    }

    var background: some View {
        FormBackground()
            .edgesIgnoringSafeArea(.all)
    }
    
    @ViewBuilder
    var quantityForm: some View {
        if let food = viewModel.food {
            QuantityForm(
                food: food,
                double: viewModel.amountValue.value,
                unit: viewModel.unit.formUnit
            ) { double, unit in
                viewModel.amount = double
                viewModel.didPickUnit(unit)
            }
        }
    }
    
    var disclosureArrow: some View {
        Image(systemName: "chevron.forward")
            .font(.system(size: 14))
            .foregroundColor(Color(.tertiaryLabel))
            .fontWeight(.semibold)
    }
    
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
    
    var mealCell: some View {
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
                        Text(viewModel.dayMeal.timeString)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .bold()
                            .foregroundColor(Color(.secondaryLabel))
//                        disclosureArrow
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(viewModel.dayMeal.name)
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
    
    var stepButtons: some View {
        func stepButton(step: Int) -> some View {
            var number: String {
                "\(abs(step))"
            }
            var sign: String {
                step > 0 ? "+" : "-"
            }
            
            var disabled: Bool {
                !viewModel.amountCanBeStepped(by: step)
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
                viewModel.stepAmount(by: step)
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
    
    var amountCell: some View {
        ZStack {
            HStack {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Spacer().frame(width: 2)
                        HStack(spacing: 4) {
                            Text("Quantity")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(.tertiaryLabel))
                        }
                        Spacer()
                        disclosureArrow
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        if viewModel.amountIsValid {
                            Color.clear
                                .animatedMealItemQuantity(
                                    value: viewModel.internalAmountDouble!,
                                    unitString: viewModel.unitDescription,
                                    isAnimating: viewModel.isAnimatingAmountChange
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)
//                            Text(viewModel.amountString)
//                                .foregroundColor(.primary)
//                                .font(.system(size: 28, weight: .medium, design: .rounded))
//                            Text(viewModel.unitDescription)
//                                .font(.system(size: 17, weight: .semibold, design: .rounded))
//                                .bold()
//                                .foregroundColor(Color(.secondaryLabel))
                        } else {
                            Text("Required")
                                .foregroundColor(Color(.tertiaryLabel))
                                .font(.system(size: 28, weight: .medium, design: .rounded))
                        }
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
                        value: viewModel.internalAmountDouble!,
                        unitString: viewModel.unitDescription,
                        isAnimating: viewModel.isAnimatingAmountChange
                    )
            }
        }
        .padding(.vertical, 15)
    }
}

import PrepViews
import SwiftUISugar

struct MealItemFormQuantity: View {
    @ObservedObject var viewModel: MealItemViewModel
    @FocusState var isFocused: Bool
    @State var showingUnitPicker = false
}

extension MealItemFormQuantity {
    var body: some View {
        FormStyledScrollView {
            textFieldSection
        }
        .navigationTitle("Quantity")
        .sheet(isPresented: $showingUnitPicker) { unitPicker }
        .onAppear(perform: appeared)
    }
    
    func appeared() {
        isFocused = true
    }
    
    var textFieldSection: some View {
        return Group {
            FormStyledSection {
                HStack {
                    textField
                    unitView
                }
            }
        }
    }
    
    var textField: some View {
        let binding = Binding<String>(
            get: { viewModel.amountString },
            set: { newValue in
                withAnimation {
                    viewModel.amountString = newValue
                }
            }
        )
        
        var font: Font {
            return viewModel.amountString.isEmpty ? .body : .largeTitle
        }

        return TextField("Required", text: binding)
            .multilineTextAlignment(.leading)
            .focused($isFocused)
            .font(font)
            .keyboardType(.decimalPad)
            .frame(minHeight: 50)
            .scrollDismissesKeyboard(.interactively)
            .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { obj in
                if let textField = obj.object as? UITextField {
                    textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
                }
            }
    }
    
    var unitView: some View {
        var unitButton: some View {
            Button {
                showingUnitPicker = true
            } label: {
                HStack(spacing: 5) {
                    Text(viewModel.unitDescription)
                        .multilineTextAlignment(.trailing)
//                        .foregroundColor(.secondary)
                        .font(.title3)
                    Image(systemName: "chevron.up.chevron.down")
                        .imageScale(.small)
                }
                .bold()
            }
            .buttonStyle(.borderless)
        }
        
        return Group {
//            if supportedUnits.count > 1 {
                unitButton
//            } else {
//                Text(viewModel.unitDescription)
//                    .multilineTextAlignment(.trailing)
//                    .foregroundColor(.secondary)
//                    .font(.title3)
//            }
        }
    }
    
    var unitPicker: some View {
        UnitPickerGridTiered(
            pickedUnit: viewModel.unit.formUnit,
            includeServing: viewModel.shouldShowServingInUnitPicker,
            includeWeights: viewModel.shouldShowWeightUnits,
            includeVolumes: viewModel.shouldShowVolumeUnits,
            sizes: viewModel.foodSizes,
            servingDescription: viewModel.servingDescription,
            allowAddSize: false,
            didPickUnit: viewModel.didPickUnit
        )
    }
}

struct AnimatableMealItemQuantityModifier: AnimatableModifier {
    
    @Environment(\.colorScheme) var colorScheme
    
    var value: Double
    var unitString: String
    var isAnimating: Bool
    
    let fontSize: CGFloat = 28
    let fontWeight: Font.Weight = .medium
    
    var animatableData: Double {
        get { value }
        set { value = newValue }
    }
    
    var uiFont: UIFont {
        UIFont.systemFont(ofSize: fontSize, weight: fontWeight.uiFontWeight)
    }
    
    var size: CGSize {
        uiFont.fontSize(for: value.formattedNutrient)
    }
    
    let unitFontSize: CGFloat = 17
    let unitFontWeight: Font.Weight = .semibold
    
    var unitUIFont: UIFont {
        UIFont.systemFont(ofSize: unitFontSize, weight: unitFontWeight.uiFontWeight)
    }
    
    var unitWidth: CGFloat {
        unitUIFont.fontSize(for: unitString).width
    }
    
    var amountString: String {
        if isAnimating {
            return value.formattedMealItemAmount
        } else {
            return value.cleanAmount
        }
    }
    
    func body(content: Content) -> some View {
        content
//            .frame(width: size.width, height: size.height)
//            .frame(width: 200 + unitWidth, height: size.height)
            .frame(maxWidth: .infinity)
            .frame(height: size.height)
            .overlay(
                HStack {
                    Spacer()
                    
                    HStack(alignment: .center, spacing: 4) {
                        Text(amountString)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.primary)
//                            .foregroundColor(.accentColor)
                            .font(.system(size: fontSize, weight: fontWeight, design: .rounded))
                        Text(unitString)
                            .font(.system(size: unitFontSize, weight: unitFontWeight, design: .rounded))
                            .lineLimit(3)
                            .minimumScaleFactor(0.5)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .bold()
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(Color(.systemFill).opacity(0.5))
                    )
                }
            )
    }
}

public extension View {
    func animatedMealItemQuantity(value: Double, unitString: String, isAnimating: Bool) -> some View {
        modifier(AnimatableMealItemQuantityModifier(value: value, unitString: unitString, isAnimating: isAnimating))
    }
}
