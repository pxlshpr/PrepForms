import SwiftUI
import SwiftHaptics
import NamePicker
import SwiftUISugar
import PrepViews

//import PrepGoalSetsList

public struct MealForm_Legacy2: View {

    @StateObject var model: MealFormModel

    @Environment(\.dismiss) var dismiss
    @FocusState var isFocused: Bool
    @State var showingDeleteConfirmation = false
    @State var hasFocusedOnAppear: Bool = false
    @State var hasCompletedFocusedOnAppearAnimation: Bool = false
    
    @State var collapsedButtons: Bool = true
    
    @State var refreshDatePicker: Bool = false
    
    let keyboardWillShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
    let keyboardWillHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
    let keyboardDidHide = NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)
    let keyboardDidShow = NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)

    @State var delayedSaveAndDismiss: Bool = false

    @State var focusOnPop: Bool = false
    
    @State var path: [MealFormRoute] = []
    
    enum MealFormRoute: Hashable {
        case namePicker
        case timePicker
    }
    
    public init(
        mealBeingEdited: DayMeal? = nil,
        date: Date,
        recents: [String] = [],
        presets: [String]? = nil,
        getTimelineItemsHandler: GetTimelineItemsHandler? = nil,
        didSave: @escaping (String, Date, GoalSet?) -> ()
    ) {
        let model = MealFormModel(
            mealBeingEdited: mealBeingEdited,
            date: date,
            recents: recents,
            presets: presets,
            getTimelineItemsHandler: getTimelineItemsHandler,
            didSave: didSave
        )
        
        _model = StateObject(wrappedValue: model)
    }
    
    public var body: some View {
        NavigationStack(path: $path) {
//        NavigationView {
            content
                .background(Color(.systemGroupedBackground))
                .navigationTitle(model.navigationTitle)
                .navigationBarTitleDisplayMode(.large)
                .toolbar { navigationLeadingButton }
                .navigationBarTitleDisplayMode(.inline)
                .onReceive(keyboardWillHide, perform: keyboardWillHide)
                .onReceive(keyboardWillShow, perform: keyboardWillShow)
                .onReceive(keyboardDidHide, perform: keyboardDidHide)
                .onReceive(keyboardDidShow, perform: keyboardDidShow)
                .navigationDestination(for: MealFormRoute.self, destination: destination)
        }
    }
    
    @ViewBuilder
    func destination(for route: MealFormRoute) -> some View {
        switch route {
        case .namePicker:
            namePicker
        case .timePicker:
            timePicker
        }
    }
    
    func keyboardWillHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation(.interactiveSpring()) {
                self.collapsedButtons = false
            }
        }
    }

    func keyboardWillShow(_ notification: Notification) {
        guard hasCompletedFocusedOnAppearAnimation else { return }
        withAnimation(.interactiveSpring()) {
            self.collapsedButtons = true
        }
    }

    func keyboardDidHide(_ notification: Notification) {
        if delayedSaveAndDismiss {
//            saveAndDismiss()
        }
    }
    
    func keyboardDidShow(_ notification: Notification) {
        if delayedSaveAndDismiss {
            actuallySaveAndDismiss()
            delayedSaveAndDismiss = false
//            saveAndDismiss()
        }
    }


    var navigationLeadingButton: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarLeading) {
//            closeButton
        }
    }
    
    var saveButton: some View {
        Button {
            saveAndDismiss()
        } label: {
            Text(model.saveButtonTitle)
                .bold()
        }
        .disabled(!model.isDirty)
    }
    
    var closeButton: some View {
        Button {
            Haptics.feedback(style: .soft)
            dismiss()
        } label: {
            CloseButtonLabel()
        }
    }
    
    var navigationTrailingButton: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            saveButton
        }
    }
    
    var saveButtons: some View {
        var saveButton: some View {
            Button {
                Haptics.successFeedback()
                saveAndDismiss()
            } label: {
                Text(model.saveButtonTitle)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.vertical)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(.accentColor)
                    )
                    .padding(.horizontal)
                    .padding(.horizontal)
            }
            .buttonStyle(.borderless)
            
//            FormPrimaryButton(title: model.saveButtonTitle) {
//                Haptics.successFeedback()
//                saveAndDismiss()
//            }
        }
        
        var cancelButton: some View {
            FormSecondaryButton(title: "Cancel") {
                Haptics.feedback(style: .soft)
                dismiss()
//                actionHandler(.dismiss)
            }
        }

        var deleteButton: some View {
            FormSecondaryButton(title: "Delete", foregroundColor: NutrientMeter.Model.Colors.Excess.fill) {
                Haptics.selectionFeedback()
                showingDeleteConfirmation = true
            }
        }
        
        @ViewBuilder
        var background: some View {
            if collapsedButtons {
                Color.clear
                    .background(.thinMaterial)
            }
        }
        
        var collapsedButtons: Bool {
            hasCompletedFocusedOnAppearAnimation && !isFocused
        }
        
        @ViewBuilder
        var divider: some View {
            if collapsedButtons {
                Divider()
            }
        }

        return VStack(spacing: 0) {
            divider
            VStack {
                saveButton
                    .padding(.top)
                HStack {
                    cancelButton
                    deleteButton
                }
                .padding(.horizontal, 50)
//                privateButton
//                    .padding(.vertical)
            }
//            .padding(.bottom, 30)
        }
        .background(background)
    }

    @ViewBuilder
    var buttonsLayer: some View {
//            if canBeSaved {
            VStack {
                Spacer()
                saveButtons
            }
//                .edgesIgnoringSafeArea(.bottom)
            .transition(.move(edge: .bottom))
//            }
    }

    var content: some View {
        
        var deleteConfirmationActions: some View {
            Button("Delete Meal", role: .destructive) {
                Haptics.errorFeedback()
                //TODO: Actually delete
                dismiss()
            }
        }

        var deleteConfirmationMessage: some View {
            Text("Are you sure you want to delete this meal?")
        }

        var formLayer: some View {
            form
//                .safeAreaInset(edge: .bottom) { bottomSafeAreaInset }
                .navigationTitle(model.navigationTitle)
//                .toolbar { trailingContents }
                .scrollDismissesKeyboard(.interactively)
                .confirmationDialog(
                    "",
                    isPresented: $showingDeleteConfirmation,
                    actions: { deleteConfirmationActions },
                    message: { deleteConfirmationMessage }
                )
        }
        
        var tappedDelete: (() -> ())? {
            if model.isEditing {
                return {
                    Haptics.warningFeedback()
                    showingDeleteConfirmation = true
                }
            } else {
                return nil
            }
        }
        
        var tappedCancel: () -> () {
            return {
                Haptics.feedback(style: .soft)
                dismiss()
            }
        }
        
        let saveIsDisabledBinding = Binding<Bool>(
            get: { !model.isDirty },
            set: { _ in }
        )
        
        var infoBinding: Binding<FormSaveInfo?> {
            Binding<FormSaveInfo?>(
                get: {
                    guard model.name.isEmpty else {
                        return nil
                    }
                    return FormSaveInfo(title: "Name Required", systemImage: "exclamationmark.triangle.fill")
                },
                set: { _ in }
            )
        }
        
        var cancelAction: FormConfirmableAction {
            FormConfirmableAction(
                shouldConfirm: model.shouldConfirmCancellation,
                handler: tappedCancel
            )
        }
        
        var saveAction: FormConfirmableAction {
            FormConfirmableAction(
                handler: { saveAndDismiss() }
            )
        }
        
        var deleteAction: FormConfirmableAction? {
            if model.isEditing {
                return FormConfirmableAction(
                    handler: { tappedDelete?() }
                )
            } else {
                return nil
            }
        }
        
        return ZStack {
            formLayer
            FormSaveLayer(
                collapsed: $collapsedButtons,
                saveIsDisabled: saveIsDisabledBinding,
                info: infoBinding,
                preconfirmationAction: {
                    /// This is to ensure that the date picker is dismissed if a confirmation button
                    /// is tapped while it's presented (otherwise causing the dismissal to fail)
                    refreshDatePicker.toggle()
                },
                cancelAction: cancelAction,
                saveAction: saveAction,
                deleteAction: deleteAction
            )
//            buttonsLayer
        }
    }

    var form: some View {
        FormStyledScrollView {
            nameSection
            timeSection
//            detailsSection
//            goalSetSection
        }
    }
    
    var nameSection: some View {
        FormStyledSection(header: Text("Name")) {
            nameRow
        }
    }
    
    
    var timeSection: some View {
        FormStyledSection(header: Text("Time")) {
            timeRow
        }
    }
    
    var detailsSection: some View {
        var divider: some View {
            Divider()
                .padding(.vertical, 5)
                .padding(.leading, 20)
        }
        
        return FormStyledSection(horizontalPadding: 0) {
            VStack {
                nameRow
                    .padding(.horizontal, 17)
                divider
                timeRow
                    .padding(.horizontal, 17)
//                .padding(.bottom, 5)
            }
        }
    }
    
    var nameRow: some View {
        HStack {
            TextField("Required", text: $model.name)
                .multilineTextAlignment(.leading)
                .focused($isFocused)
                .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { obj in
                    if let textField = obj.object as? UITextField {
                        textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
                    }
                }
                .font(.title2)
                .fontWeight(.semibold)
//            NavigationLink {
//                namePicker
//                    .onAppear {
//                        if isFocused {
//                            focusOnPop = true
//                        }
//                    }
//                    .onDisappear {
//                        if focusOnPop {
//                            isFocused = true
//                            focusOnPop = false
//                        }
//                    }
            Button {
                if isFocused {
                    isFocused = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        path.append(.namePicker)
                    }
                } else {
                    path.append(.namePicker)
                }
            } label: {
                Image(systemName: "square.grid.3x2")
            }
        }
        .introspectTextField { uiTextField in
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                if !hasFocusedOnAppear {
                    uiTextField.becomeFirstResponder()
                    hasFocusedOnAppear = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeIn) {
                            hasCompletedFocusedOnAppearAnimation = true
                        }
                    }
                }
//                }
        }
//        .onAppear {
//            isFocused = true
//        }
    }
    
    var timeRow: some View {
        HStack {
            datePickerTime
                .frame(maxWidth: .infinity, alignment: .leading)
//            NavigationLink {
//                timePicker
            Button {
                if isFocused {
                    isFocused = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        path.append(.timePicker)
                    }
                } else {
                    path.append(.timePicker)
                }
            } label: {
                Image(systemName: "calendar.day.timeline.left")
            }
        }
    }
    
    var goalSetSection: some View {
        var pickerRow: some View {
            NavigationLink {
                goalSetPicker
            } label: {
                HStack {
                    Text("Type")
                        .foregroundColor(.secondary)
                    Spacer()
                    goalSetLabel
                    Image(systemName: "chevron.right")
                        .imageScale(.small)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
        }
        
        @ViewBuilder
        var goalSetLabel: some View {
            if let goalSet = model.goalSet {
                Text("\(goalSet.emoji) \(goalSet.name)")
                    .foregroundColor(.primary)
            } else {
                Text("Select")
                    .foregroundColor(.accentColor)
//                    .foregroundColor(Color(.secondaryLabel))
            }
        }
        
        var durationRow: some View {
            HStack {
                Text("Workout Duration")
                    .foregroundColor(.secondary)
                Spacer()
                durationPicker
            }
        }
        
        var durationPicker: some View {
            HStack {
                Text("1 hour")
                Image(systemName: "chevron.up.chevron.down")
                    .font(.footnote)
                    .foregroundColor(Color(.tertiaryLabel))
                Text("30 min.")
                Image(systemName: "chevron.up.chevron.down")
                    .font(.footnote)
                    .foregroundColor(Color(.tertiaryLabel))
            }
        }
        
        var divider: some View {
            Divider()
                .padding(.vertical, 5)
                .padding(.leading, 20)
        }
        
        @ViewBuilder
        var footer: some View {
            if model.shouldShowDurationPicker {
                Text("Workout duration is used to calculate the carbohydrate goal for this meal type.")
//                Text("Workout duration is used to calculate the carbohydrate, protein and sodium goals for this meal type.")
            }
        }
        
        return FormStyledSection(footer: footer, horizontalPadding: 0) {
            VStack {
                pickerRow
                    .padding(.horizontal, 17)
                if model.shouldShowDurationPicker {
                    divider
                    durationRow
                        .padding(.horizontal, 17)
                }
            }
        }
    }
    
    func buttonLabel(_ string: String) -> some View {
        Text(string)
          .foregroundColor(Color(.secondaryLabel))
          .padding(.vertical, 6)
          .padding(.horizontal, 8)
          .background(
//            Capsule(style: .continuous)
            RoundedRectangle(cornerRadius: 5.0, style: .continuous)
                  .fill(Color(.secondarySystemFill))
          )
    }
    
    func button(
        increment: Int? = nil,
        decrement: Int? = nil,
        hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .soft
    ) -> some View {
        Button {
            Haptics.feedback(style: hapticStyle)
            model.didTapTimeButton()
        } label: {
            let systemName: String
            if let increment = increment {
                systemName = "goforward.\(increment)"
            } else if let decrement = decrement {
                systemName = "gobackward.\(decrement)"
            } else {
                systemName = "questionmark.circle"
            }
            return Image(systemName: systemName)
                .font(.title2)
                .padding(.horizontal, 7)
//                .padding(3)
        }
        .foregroundColor(Color(.tertiaryLabel))
        .buttonStyle(BorderlessButtonStyle())
    }
    
    var datePicker: some View {
        DatePicker(
            "",
            selection: $model.time,
            in: model.dateRangeForPicker,
            displayedComponents: [.date]
        )
        .datePickerStyle(.compact)
        .labelsHidden()
    }
    var datePickerTime: some View {
        DatePicker(
            "",
            selection: $model.time,
            in: model.dateRangeForPicker,
            displayedComponents: [.date, .hourAndMinute]
        )
        .datePickerStyle(.compact)
        .labelsHidden()
        .onChange(of: model.time, perform: onChangeOfTime)
        .id(refreshDatePicker)
    }
    
    func onChangeOfTime(_ time: Date) {
        /// For some reason, not having this `onChange` modifier doesn't update the `time` when we pick one using the `DatePicker`, so we're leaving it in here
    }

    var addButton: some View {
        FormPrimaryButton(title: "Add") {
            saveAndDismiss()
        }
        .animation(.none, value: isFocused)
    }
    
    //MARK: - Pickers
    
    var namePicker: some View {
        NamePicker(
            name: $model.name,
            showTextField: false,
            showClearButton: true,
//            focusOnAppear: true,
            recentStrings: model.recents,
            presetStrings: model.presets
        )
        .navigationTitle("Meal Name")
        .navigationBarTitleDisplayMode(.large)
    }
    
    var timePicker: some View {
        TimeForm(
            name: model.name,
            time: model.timeBinding,
            date: model.date,
            getTimelineItemsHandler: model.getTimelineItemsHandler
        )
    }
    
    var goalSetPicker: some View {
        EmptyView()
//        GoalSetPicker(
//            meal: nil,
//            showCloseButton: false,
//            selectedGoalSet: model.goalSet,
//            didSelectGoalSet: didSelectGoalSet
//        )
    }
    
    func didSelectGoalSet(_ goalSet: GoalSet?, day: Day?) {
        model.goalSet = goalSet
    }
    
    //MARK: - Actions
    func didTapAddMealButton(notification: Notification) {
        saveAndDismiss()
    }

    func actuallySaveAndDismiss() {
        dismiss()
        if model.isEditing {
            Haptics.successFeedback()
        }
        model.tappedAdd()
    }
    
    func saveAndDismiss() {
        
        if isFocused && !collapsedButtons {
            isFocused = false
            delayedSaveAndDismiss = true
        } else {
            actuallySaveAndDismiss()
        }
    }
}

//MARK: - 👁‍🗨 Previews
import PrepDataTypes

struct MealFormPreview: View {
    
    @State var showingMealForm = true
    
    var body: some View {
        NavigationView {
            Color.clear
                .navigationTitle("Meal Form")
                .sheet(isPresented: $showingMealForm) { mealForm }
        }
    }
    
    var mealForm: some View {
        MealForm_Legacy2(
            date: Date(),
            recents: ["Recents", "go here"],
            presets: Presets,
            getTimelineItemsHandler: getTimelineItems) { name, date, goalSet in
                
            }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }
    
    func getTimelineItems(_ date: Date) -> [TimelineItem] {
        var items: [TimelineItem] = []
        for i in 0...10 {
            items.append(TimelineItem(
                name: "Meal \(i)",
                date: Date().startOfDay.addingTimeInterval(Double(i*3600))
            ))
        }
        return items
    }
}

struct MealForm_Previews: PreviewProvider {
    static var previews: some View {
        MealFormPreview()
    }
}
