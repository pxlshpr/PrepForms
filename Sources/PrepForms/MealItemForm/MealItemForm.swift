import SwiftUI
import SwiftUISugar
import FoodLabel
import PrepViews
import PrepDataTypes
import SwiftHaptics
import PrepCoreDataStack

public enum MealItemFormAction {
//    case add(FoodType)
    case save(MealFoodItem, DayMeal)
    case delete
    case dismiss
}

public struct MealItemForm: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @FocusState var isFocused: Bool

    @ObservedObject var viewModel: MealItemViewModel
    @State var showingDeleteConfirmation = false
    let alreadyInNavigationStack: Bool
    let actionHandler: (MealItemFormAction) -> ()

    //TODO: Are these needed here anymore?
    @State var showingUnitPicker = false
    @State var showingMealTypesPicker = false
    @State var showingDietsPicker = false
    @State var showingEquivalentQuantities: Bool = false

    @State var showingQuantityForm = false
    
    public init(
        viewModel: MealItemViewModel,
        isEditing: Bool = false,
        actionHandler: @escaping ((MealItemFormAction) -> ())
    ) {
        self.viewModel = viewModel
        self.actionHandler = actionHandler
        alreadyInNavigationStack = !isEditing
    }
    
    @ViewBuilder
    public var body: some View {
        Group {
            if alreadyInNavigationStack {
                content
            } else {
                navigationStack
            }
        }
    }
    
    var navigationStack: some View {
        NavigationStack(path: $viewModel.path) {
            content
                .background(background)
                .navigationDestination(for: MealItemFormRoute.self, destination: navigationDestination)
        }
    }
    
    var trailingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            HStack(spacing: 2) {
                if viewModel.isEditing {
                    deleteButton
                }
                closeButton
            }
        }
    }
    
    var closeButton: some View {
        Button {
            Haptics.feedback(style: .soft)
            tappedClose()
        } label: {
            CloseButtonLabel(forNavigationBar: true)
        }
    }
    
    var background: some View {
        FormBackground()
            .edgesIgnoringSafeArea(.all)
    }

    var bottomButtonsLayer: some View {
        VStack {
            Spacer()
            bottomButtons
        }
        .edgesIgnoringSafeArea(.bottom)
        .transition(.move(edge: .bottom))
    }
    
    @ViewBuilder
    func navigationDestination(for route: MealItemFormRoute) -> some View {
        switch route {
        case .food:
            MealItemFormSearch(
                viewModel: viewModel,
                actionHandler: actionHandler
            )
        case .meal:
            mealPicker
        case .mealItemForm:
            EmptyView()
        case .quantity:
            MealItemFormQuantity(viewModel: viewModel)
        }
    }
    
    var saveButtons: some View {
        var saveButton: some View {
            FormPrimaryButton(title: viewModel.saveButtonTitle) {
                Haptics.feedback(style: .soft)
                actionHandler(.save(viewModel.mealFoodItem, viewModel.dayMeal))
                actionHandler(.dismiss)
            }
        }
        
        var cancelButton: some View {
            FormSecondaryButton(title: "Cancel") {
                actionHandler(.dismiss)
            }
        }

        var deleteButton: some View {
            FormSecondaryButton(title: "Delete") {
                tappedDelete()
            }
        }

        return VStack(spacing: 0) {
            Divider()
            VStack {
                saveButton
                    .padding(.top)
                deleteButton
//                cancelButton
//                privateButton
//                    .padding(.vertical)
            }
            .padding(.bottom, 30)
        }
        .background(.thinMaterial)
    }
    
    var optionalTappedDelete: (() -> ())? {
        if viewModel.isEditing {
            return tappedDelete
        } else {
            return nil
        }
    }

    var deleteAction: FormConfirmableAction? {
        guard viewModel.isEditing else { return nil }
        return FormConfirmableAction(
            handler: { optionalTappedDelete?() }
        )
    }
    
    @ViewBuilder
    var deleteButton: some View {
        if let deleteAction {
            deleteButton(deleteAction)
        }
    }

    func deleteButton(_ action: FormConfirmableAction) -> some View {
        var shadowSize: CGFloat { 2 }

        var confirmationActions: some View {
            Button(action.confirmationButtonTitle ?? "Delete", role: .destructive) {
                action.handler()
                dismiss()
            }
        }

        var confirmationMessage: some View {
            Text(action.confirmationMessage ?? "Are you sure?")
        }

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
//            .confirmationDialog(
//                "",
//                isPresented: $showingDeleteConfirmation,
//                actions: { confirmationActions },
//                message: { confirmationMessage }
//            )
        }

        return Button {
            if action.shouldConfirm {
                Haptics.warningFeedback()
                showingDeleteConfirmation = true
            } else {
                action.handler()
            }
        } label: {
            label
        }
    }
    
    var saveLayer: some View {
        
        var infoBinding: Binding<FormSaveInfo?> {
            Binding<FormSaveInfo?>(
                get: {
                    guard !viewModel.amountIsValid else {
                        return nil
                    }
                    return FormSaveInfo(title: "Quantity Required", systemImage: "exclamationmark.triangle.fill")
                },
                set: { _ in }
            )
        }
        
        var cancelAction: FormConfirmableAction {
            FormConfirmableAction(
                handler: tappedClose
            )
        }
        
        var saveAction: FormConfirmableAction {
            FormConfirmableAction(
                handler: { tappedSave() }
            )
        }
        
        return FormSaveLayer(
            showDismissButton: false,
            collapsed: .constant(false),
            saveIsDisabled: Binding<Bool>(
                get: { !viewModel.isDirty },
                set: { _ in }
            ),
            saveTitle: viewModel.saveButtonTitle,
            info: infoBinding,
            cancelAction: cancelAction,
            saveAction: saveAction
//            deleteAction: deleteAction
        )
    }
    
    func delete() {
        Haptics.successFeedback()
        DataManager.shared.deleteMealItem(
            viewModel.mealFoodItem,
            in: viewModel.dayMeal
        )
    }
    
    var content: some View {
        var deleteConfirmationActions: some View {
            Button("Delete Entry", role: .destructive) {
                delete()
                actionHandler(.dismiss)
            }
        }

        var deleteConfirmationMessage: some View {
            Text("Are you sure you want to delete this entry?")
        }
        
        func tappedQuantityForm() {
            showingQuantityForm = true
        }

        var formLayer: some View {
            MealItemFormNew(
                viewModel: viewModel,
                tappedSave: tappedSave,
                tappedQuantityForm: tappedQuantityForm
            )
            .safeAreaInset(edge: .bottom) { bottomSafeAreaInset }
            .navigationTitle(viewModel.navigationTitle)
            .scrollDismissesKeyboard(.interactively)
            .sheet(isPresented: $showingUnitPicker) { unitPicker }
            .sheet(isPresented: $showingEquivalentQuantities) { equivalentSizesSheet }
            .sheet(isPresented: $showingQuantityForm) { quantityForm }
            .confirmationDialog(
                "",
                isPresented: $showingDeleteConfirmation,
                actions: { deleteConfirmationActions },
                message: { deleteConfirmationMessage }
            )
        }
        
        return ZStack {
            formLayer
//            saveLayer
        }
        .toolbar { trailingContent }
    }
    
    @ViewBuilder
    var quantityForm: some View {
        if let food = viewModel.food {
            MealItemFormNew.QuantityForm(
                food: food,
                double: viewModel.amountValue.value,
                unit: viewModel.unit.formUnit
            ) { double, unit in
                viewModel.amount = double
                viewModel.didPickUnit(unit)
            }
        }
    }
    
    //MARK: - Details
    
    var detailsSection: some View {
        var divider: some View {
            Divider()
                .padding(.top, 5)
                .padding(.bottom, 10)
        }
        
        var amountRow: some View {
            HStack {
                Text("Quantity")
                    .foregroundColor(.secondary)
                    .onTapGesture {
                        Haptics.feedback(style: .soft)
                        isFocused = true
                    }
//                equivalentSizesButton
                Spacer()
                textField
                unitButton
            }
        }
        
        return FormStyledSection(horizontalPadding: 0) {
            VStack {
                foodLink
                    .padding(.horizontal, 17)
                divider
                    .padding(.leading, 50)
                mealLink
                    .padding(.horizontal, 17)
                divider
                    .padding(.leading, 20)
                amountRow
                    .padding(.horizontal, 17)
                .padding(.bottom, 5)
            }
        }
    }
    
    @ViewBuilder
    var equivalentSizesButton: some View {
        if !viewModel.equivalentQuantities.isEmpty {
            Button {
                Haptics.feedback(style: .soft)
                withAnimation {
                    showingEquivalentQuantities.toggle()
                }
            } label: {
//                Image(systemName: "square.grid.3x2")
                Image(systemName: "rectangle.grid.2x2")
                    .font(.caption)
                    .imageScale(.medium)
            }
        }
    }
    
    var equivalentSizesSheet: some View {
        var footer: some View {
            Text("These are quantities in the other units for this food that equals what you've entered. Select one to use it instead.")
        }
        
        return NavigationView {
            FormStyledScrollView {
                FormStyledSection(footer: footer, horizontalPadding: 0) {
                    FlowLayout(
                        mode: .scrollable,
                        items: viewModel.equivalentQuantities,
                        itemSpacing: 4,
                        shouldAnimateHeight: .constant(true)
                    ) { quantity in
                        quantityButton(for: quantity)
                    }
                    .padding(.horizontal, 17)
                }
            }
            .navigationTitle("Similar Quantities")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.height(400)])
        .presentationDragIndicator(.hidden)
    }
    
    func quantityButton(for quantity: FoodQuantity) -> some View {
        Button {
            Haptics.feedback(style: .rigid)
            viewModel.didPickQuantity(quantity)
            showingEquivalentQuantities = false
        } label: {
            ZStack {
                Capsule(style: .continuous)
                    .foregroundColor(Color(.secondarySystemFill))
                HStack(spacing: 5) {
                    Text(quantity.value.cleanAmount)
                        .foregroundColor(Color(.tertiaryLabel))
                    Text(quantity.unit.shortDescription)
                        .foregroundColor(Color(.secondaryLabel))
                }
                .frame(height: 25)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
            }
            .fixedSize(horizontal: true, vertical: true)
        }
    }

    @ViewBuilder
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

    
    @ViewBuilder
    var foodLink: some View {
        if let food = viewModel.food {
            Button {
                viewModel.path.append(.food)
            } label: {
                HStack {
                    FoodCell(
                        food: food,
                        showMacrosIndicator: false
                    )
                    .animation(.default, value: viewModel.amount)
                    .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    NutritionSummary(
                        dataProvider: viewModel,
                        showMacrosIndicator: true
                    )
                    .animation(.default, value: viewModel.amount)
                    .fixedSize(horizontal: true, vertical: false)
                    navigationLinkArrow
                }
                .multilineTextAlignment(.leading)
            }
        }
    }
    
    var mealLink: some View {
        Button {
            viewModel.path.append(.meal)
        } label: {
            HStack {
                Text("Meal")
                    .foregroundColor(.secondary)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(viewModel.dayMeal.name)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.accentColor)
                    Text(viewModel.dayMeal.timeString)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 3)
                        .padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .foregroundColor(Color(.secondarySystemFill))
                        )
                }
                navigationLinkArrow
            }
//                Text("10:30 am • Pre-workout Meal")
                .frame(maxWidth: .infinity, alignment: .leading)
//                    .foregroundColor(.accentColor)
        }
    }
    
    var formLayer: some View {
        form
//            .safeAreaInset(edge: .bottom) { bottomSafeAreaInset }
            .navigationTitle(viewModel.navigationTitle)
            .scrollDismissesKeyboard(.interactively)
            .sheet(isPresented: $showingUnitPicker) { unitPicker }
            .sheet(isPresented: $showingEquivalentQuantities) { equivalentSizesSheet }
    }
    
    var form: some View {
        FormStyledScrollView {
            detailsSection
//            portionAwareness
            deleteButtonSection
        }
    }
    
    @ViewBuilder
    var deleteButtonSection: some View {
        if viewModel.isEditing {
            FormStyledSection {
                Button(role: .destructive) {
//                    actionHandler(.delete)
                    delete()
                    actionHandler(.dismiss)
                } label: {
                    HStack {
                        Label("Delete", systemImage: "trash")
                            .imageScale(.small)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
            }
        }
    }
    var bottomSafeAreaInset: some View {
        Spacer()
            .frame(height: 80)
    }
    var portionAwareness: some View {
        let lastUsedGoalSetBinding = Binding<GoalSet?>(
            get: { DataManager.shared.lastUsedGoalSet },
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
    }
    
    func didTapGoalSetButton(forMeal: Bool) {
//        if forMeal {
//            showingMealTypesPicker = true
//        } else {
//            showingDietsPicker = true
//        }
    }
    
    var mealPicker: some View {
        MealItemFormMealPicker(didTapDismiss: {
            actionHandler(.dismiss)
        }, didTapMeal: { pickedMeal in
            NotificationCenter.default.post(
                name: .didPickDayMeal,
                object: nil,
                userInfo: [Notification.Keys.dayMeal: pickedMeal]
            )
        })
        .environmentObject(viewModel)
    }
    
//    var deleteButton: some View {
//        Button {
//            actionHandler(.delete)
//            actionHandler(.dismiss)
//        } label: {
//            Text("Delete")
//                .foregroundColor(.red)
//        }
//    }

    func tappedSave() {
        Haptics.feedback(style: .soft)
        actionHandler(.save(viewModel.mealFoodItem, viewModel.dayMeal))
        actionHandler(.dismiss)
    }
    
    func tappedClose() {
        Haptics.feedback(style: .soft)
        actionHandler(.dismiss)
    }
    
    func tappedDelete() {
        Haptics.selectionFeedback()
        showingDeleteConfirmation = true
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
        
        var actualTextField: some View {
            TextField("Required", text: binding)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 16, weight: .regular, design: .default))
                .frame(height: 30)
                .focused($isFocused)
                .keyboardType(.decimalPad)
                .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { obj in
                    if let textField = obj.object as? UITextField {
                        textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
                    }
                }
        }
        
        var animatedNumber: some View {
            Color.clear
                .animatedMealItemAmount(value: viewModel.amount ?? 0)
        }
        
        return ZStack {
            if viewModel.isAnimatingAmountChange, viewModel.amount?.isInteger == true {
                animatedNumber
            } else {
                actualTextField
            }
        }
        .animation(.default, value: viewModel.amount)
    }

    
    var unitButton: some View {
        Button {
            showingUnitPicker = true
        } label: {
            HStack(spacing: 5) {
                Text(viewModel.unitDescription)
                    .multilineTextAlignment(.trailing)
                Image(systemName: "chevron.up.chevron.down")
                    .imageScale(.small)
            }
        }
        .buttonStyle(.borderless)
    }
}

extension Double {
    var isInteger: Bool {
        floor(self) == self
    }
}

extension MealItemForm {
    
    var bottomButtons: some View {
        VStack(spacing: 0) {
            Divider()
            stepButtons
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 10)
                .padding(.bottom, 35)
        }
        .background(.thinMaterial)
    }
    
    var dotSeparator: some View {
        Text("•")
            .font(.system(size: 20))
            .foregroundColor(Color(.quaternaryLabel))
    }
    
    var stepButtons: some View {
        HStack {
            stepButton(step: -50)
            stepButton(step: -10)
            stepButton(step: -1)
//            dotSeparator
            unitBottomButton
            similarSizesBottomButton
//            dotSeparator
            stepButton(step: 1)
            stepButton(step: 10)
            stepButton(step: 50)
        }
    }

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
            disabled ? .thin : .semibold
        }
        
        return Button {
            Haptics.feedback(style: .soft)
            viewModel.stepAmount(by: step)
        } label: {
            HStack(spacing: 1) {
                Text(sign)
//                    .font(.system(.caption, design: .rounded, weight: .regular))
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                Text(number)
//                    .font(.system(.footnote, design: .rounded, weight: fontWeight))
                    .font(.system(size: 11, weight: fontWeight, design: .rounded))
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
        .disabled(disabled)
    }
    
    var unitBottomButton: some View {
        Button {
            Haptics.feedback(style: .soft)
            showingUnitPicker = true
        } label: {
            Image(systemName: "chevron.up.chevron.down")
                .imageScale(.medium)
//                .foregroundColor(.white)
                .foregroundColor(.accentColor)
                .frame(width: 44, height: 44)
                .background(colorScheme == .light ? .ultraThickMaterial : .ultraThinMaterial)
//                .background(Color.accentColor)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(
                            Color.accentColor.opacity(0.7),
                            style: StrokeStyle(lineWidth: 0.5, dash: [3])
                        )
                )
        }
    }
    
    var similarSizesBottomButton: some View {
        Button {
            Haptics.feedback(style: .soft)
            showingEquivalentQuantities = true
        } label: {
            Image(systemName: "square.grid.3x2")
                .imageScale(.medium)
//                .foregroundColor(.white)
                .foregroundColor(.accentColor)
                .frame(width: 44, height: 44)
                .background(colorScheme == .light ? .ultraThickMaterial : .ultraThinMaterial)
//                .background(Color.accentColor)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(
                            Color.accentColor.opacity(0.7),
                            style: StrokeStyle(lineWidth: 0.5, dash: [3])
                        )
                )
        }
    }
}

struct AnimatableMealItemAmountModifier: AnimatableModifier {
    
    var value: Double
    
    let fontSize: CGFloat = 16
    
    var animatableData: Int {
        get { Int(value.rounded()) }
        set { value = Double(newValue) }
    }
    
    var uiFont: UIFont {
        UIFont.systemFont(ofSize: fontSize, weight: .regular)
    }
    
    var size: CGSize {
        uiFont.fontSize(for: value.cleanAmount)
    }

    func body(content: Content) -> some View {
        content
            .frame(width: 100, height: 30)
            .overlay(
                HStack {
                    Spacer()
                    Text(value.cleanAmount)
                        .font(.system(size: fontSize, weight: .regular, design: .default))
                        .offset(x: 1)
                }
            )
    }
}

extension Int: VectorArithmetic {
    mutating public func scale(by rhs: Double) {
        self = Int(Double(self) * rhs)
    }

    public var magnitudeSquared: Double {
        Double(self * self)
    }
}

extension View {
    func animatedMealItemAmount(value: Double) -> some View {
        modifier(AnimatableMealItemAmountModifier(value: value))
    }
}
