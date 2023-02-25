import SwiftUI
import SwiftUISugar
import PrepDataTypes
import SwiftHaptics
import PrepCoreDataStack

public typealias ExistingMealTimesFunction = ((Date) async throws -> [Date])

public struct MealForm: View {

    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    let date: Date
    let existingMeal: DayMeal?
    
//    let existingDayMeals: [DayMeal]
    
    @State var name: String
    @State var time: Date
    
    @State var showingNameForm = false
    @State var showingTimeForm = false

    //TODO: Remove this!
//    let existingMealTimesFunction: ExistingMealTimesFunction?
    let existingMealTimes: [Date]

    let didSaveMeal: (String, Date, GoalSet?) -> ()

    @State var lastTime: Date = Date()
    @State var refreshDatePicker: Bool = false
    
    @State var nameIsDirty = false
    @State var ignoreNextNameChange = false

    public init(
        existingMeal: DayMeal? = nil,
        date: Date,
        recents: [String] = [],
        presets: [String]? = nil,
        existingMealTimes: [Date],
//        existingMealTimesFunction: ExistingMealTimesFunction? = nil,
        didSaveMeal: @escaping (String, Date, GoalSet?) -> ()
    ) {
        self.date = date
//        self.existingMealTimesFunction = existingMealTimesFunction
//        self.existingDayMeals = existingDayMeals
        
        self.existingMeal = existingMeal
        self.didSaveMeal = didSaveMeal
        
        self.existingMealTimes = existingMealTimes

        if let existingMeal {
            _name = State(initialValue: existingMeal.name)
            _time = State(initialValue: Date(timeIntervalSince1970: existingMeal.time))
        } else {
            let time = newMealTime(for: date, existingMealTimes: existingMealTimes)
            _name = State(initialValue: newMealName(for: time))
            _time = State(initialValue: time)
        }        
    }

    public var body: some View {
        quickForm
//            .presentationDetents([.height(370)])
            .presentationDetents(undimmed: [.height(400)])
            .presentationDragIndicator(.hidden)
            .sheet(isPresented: $showingNameForm) { nameForm }
//            .task { getExistingMealTimes() }
            .sheet(isPresented: $showingTimeForm) { timeForm }
            .onChange(of: time, perform: timeChanged)
            .onChange(of: name, perform: nameChanged)
    }
    
    func nameChanged(_ newValue: String) {
        guard !ignoreNextNameChange else {
            return
        }
        nameIsDirty = true
    }
    
//    func getExistingMealTimes() {
//        guard let existingMealTimesFunction else { return }
//        Task {
//            let existingMealTimes = try await existingMealTimesFunction(date)
//            await MainActor.run {
//                self.existingMealTimes = existingMealTimes
//                if existingMeal == nil {
//                    /// We're assuming that the fetch of the existing meals happens quickly enough that
//                    /// `time` hasn't been changed yet—if it ends up taking long enough for the user to have made
//                    /// a change, only do this if the user hasn't changed the value already.
//                    self.time = newMealTime(for: date, existingMealTimes: existingMealTimes)
//                }
//            }
//        }
//    }

    
    var nameForm: some View {
        NameForm(name: $name)
    }
    
    var timeForm: some View {
        TimeForm(
            date: date,
            time: $time,
            existingMealTimes: .constant(existingMealTimes)
        )
    }

    var quickForm: some View {
        QuickForm(
            title: existingMeal == nil ? "New Meal" : "Edit Meal",
            deleteAction: deleteActionBinding
        ) {
//            nameCell
//            timeCell
            legacySection
            saveButton
        }
    }
    
    var disclosureArrow: some View {
        Image(systemName: "chevron.forward")
            .font(.system(size: 14))
            .foregroundColor(Color(.tertiaryLabel))
            .fontWeight(.semibold)
    }

    var nameCell: some View {
        var label: some View {
            ZStack {
                HStack {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Spacer().frame(width: 2)
                            HStack(spacing: 4) {
                                Text("Name")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color(.tertiaryLabel))
                            }
                            Spacer()
                            disclosureArrow
                        }
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            if !name.isEmpty {
                                Text(name)
                                    .foregroundColor(.primary)
                                    .font(.system(size: 28, weight: .medium, design: .rounded))
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
            .padding(.horizontal, 20)
        }
        
        return Button {
            Haptics.feedback(style: .soft)
            showingNameForm = true
        } label: {
            label
        }
    }

    var timeCell: some View {
        var label: some View {
            var timeString: String {
                let formatter = DateFormatter()
                formatter.dateFormat = "h:mm"
                return formatter.string(from: time)
            }
            
            var amPmString: String {
                let formatter = DateFormatter()
                formatter.dateFormat = "a"
                return formatter.string(from: time).lowercased()
            }
            
            return ZStack {
                HStack {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Spacer().frame(width: 2)
                            HStack(spacing: 4) {
                                Text("Time")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color(.tertiaryLabel))
                            }
                            Spacer()
                            disclosureArrow
                        }
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text(timeString)
                                .foregroundColor(.primary)
                                .font(.system(size: 28, weight: .medium, design: .rounded))
                            Text(amPmString)
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .bold()
                                .foregroundColor(Color(.secondaryLabel))
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
            .padding(.horizontal, 20)
        }
        
        return Button {
            Haptics.feedback(style: .soft)
            showingTimeForm = true
        } label: {
            label
        }
    }

    var legacySection: some View {
        FormStyledSection {
            Grid(alignment: .leading) {
                GridRow {
                    Text("Name")
                        .foregroundColor(.secondary)
                    fieldButton(name, isRequired: true) {
                        Haptics.feedback(style: .soft)
                        showingNameForm = true
                    }
                }
                GridRow {
                    Text("Time")
                        .foregroundColor(.secondary)
                    datePicker
                }
                GridRow {
                    timeSlider
                        .gridCellColumns(2)
                }
            }
        }
    }
    
//    var deleteActionBinding: Binding<FormConfirmableAction?> {
//        Binding<FormConfirmableAction?>(
//            get: {
//                .init(
//                    shouldConfirm: true,
//                    confirmationMessage: "Are you sure you want to delete this meal?",
//                    confirmationButtonTitle: "Delete Meal",
//                    isDisabled: false,
//                    buttonImage: "trash.fill",
//                    handler: {
//                        guard let existingMeal else {
//                            return
//                        }
//                        do {
//                            try DataManager.shared.deleteMeal(existingMeal)
//                        } catch {
//                            cprint("Couldn't delete meal: \(error)")
//                        }
//                    }
//                )
//            },
//            set: { _ in }
//        )
//    }

    var datePicker: some View {
        DatePicker(
            "",
            selection: $time,
            in: dateRangeForPicker,
            displayedComponents: [.date, .hourAndMinute]
        )
        .datePickerStyle(.compact)
        .labelsHidden()
        .onChange(of: time, perform: onChangeOfTime)
        .id(refreshDatePicker)
    }
    
    var timeSlider: some View {
        TimeSlider(
            date: self.date,
            existingTimeSlots: existingTimeSlots,
            currentTime: $time,
            currentTimeSlot: currentTimeSlot
        )
    }
    
    func onChangeOfTime(_ time: Date) {
        /// For some reason, not having this `onChange` modifier doesn't update the `time` when we pick one using the `DatePicker`, so we're leaving it in here
    }

    var dateRangeForPicker: ClosedRange<Date> {
        let start = date.startOfDay
        let end = date.moveDayBy(1).atEndOfWeeHours
        return start...end
    }
    
//    func nearestAvailableTimeSlot(to timeSlot: Int) -> Int? {
//
//        func timeSlotIsAvailable(_ timeSlot: Int) -> Bool {
//            timeSlot != self.currentTimeSlot && !existingTimeSlots.contains(timeSlot)
//        }
//
//        /// First search forwards till the end
//        for t in timeSlot..<K.numberOfSlots {
//            if timeSlotIsAvailable(t) {
//                return t
//            }
//        }
//        /// If we still haven't find one, go backwards
//        for t in (0..<timeSlot-1).reversed() {
//            if timeSlotIsAvailable(t) {
//                return t
//            }
//        }
//        return nil
//    }
    
    var currentTimeSlot: Int {
        time.timeSlot(within: date)
    }
    
    var existingTimeSlots: [Int] {
        existingMealTimes.map {
            $0.timeSlot(within: date)
        }
    }
    
    func timeChanged(_ newTime: Date) {
        /// Adjust to nearestAvailableTimeslot
        let timeSlot = newTime.timeSlot(within: date)
        if existingTimeSlots.contains(timeSlot) {
            guard let nearestAvailable = nearestAvailableTimeSlot(
                to: timeSlot,
                existingTimeSlots: existingTimeSlots,
                ignoring: currentTimeSlot,
                searchingBothDirections: true
            ) else {
//            guard let nearestAvailable = nearestAvailableTimeSlot(to: timeSlot) else {
                self.time = lastTime
                return
            }
            self.time = date.timeForTimeSlot(nearestAvailable)
        }
        
        /// If user hasn't changed the name yet, keep adjusting it to the time-based preset
        if !nameIsDirty && existingMeal == nil {
            ignoreNextNameChange = true
            self.name = newMealName(for: newTime)
        }
    }
    
    var deleteActionBinding: Binding<FormConfirmableAction?> {
        Binding<FormConfirmableAction?>(
            get: {
                guard existingMeal != nil else {
                    return nil
                }
                return FormConfirmableAction(
                    shouldConfirm: true,
                    confirmationMessage: "Are you sure you want to delete this meal?",
                    confirmationButtonTitle: "Delete Meal",
                    isDisabled: false,
                    buttonImage: "trash.fill",
                    handler: {
                        guard let existingMeal else {
                            return
                        }
                        do {
                            try DataManager.shared.deleteMeal(existingMeal)
                        } catch {
                            cprint("Couldn't delete meal: \(error)")
                        }
                    }
                )
            },
            set: { _ in }
        )
    }

    func tappedSave() {
        /// This is to ensure that the date picker is dismissed if a confirmation button
        /// is tapped while it's presented (otherwise causing the dismissal to fail)
        refreshDatePicker.toggle()
        Haptics.successFeedback()
        didSaveMeal(name, time, nil)
        dismiss()
    }
    
    var saveIsDisabled: Bool {
        if name.isEmpty {
            return true
        }
        
        if let existingMeal {
            if existingMeal.name == name
                && existingMeal.timeDate.equalsIgnoringSeconds(time) {
                return true
            }
        }
        
        return false
    }
    
    var saveButton: some View {
        var buttonWidth: CGFloat {
            UIScreen.main.bounds.width - (20 * 2.0)
        }
        
        var xPosition: CGFloat {
            UIScreen.main.bounds.width / 2.0
        }
        
        var yPosition: CGFloat {
            (52.0/2.0) + 16.0
        }
        
        var shadowOpacity: CGFloat {
            0
        }
        
        var buttonHeight: CGFloat {
            52
        }
        
        var buttonCornerRadius: CGFloat {
            10
        }
        
        var shadowSize: CGFloat {
            2
        }

        return Button {
            tappedSave()
        } label: {
            Text(existingMeal == nil ? "Add" : "Save")
                .bold()
                .foregroundColor((colorScheme == .light && saveIsDisabled) ? .black : .white)
                .frame(width: buttonWidth, height: buttonHeight)
                .background(
                    RoundedRectangle(cornerRadius: buttonCornerRadius)
                        .foregroundStyle(Color.accentColor.gradient)
                    //                    .foregroundColor(.accentColor)
                        .shadow(color: Color(.black).opacity(shadowOpacity), radius: shadowSize, x: 0, y: shadowSize)
                )
        }
        .buttonStyle(.borderless)
        .position(x: xPosition, y: yPosition)
        .disabled(saveIsDisabled)
        .opacity(saveIsDisabled ? (colorScheme == .light ? 0.2 : 0.2) : 1)
    }
    
    func fieldButton(_ string: String, isRequired: Bool = false, action: @escaping () -> ()) -> some View {
        let fill: Color = colorScheme == .light
        ? Color(hex: "EFEFF0")
        : Color(.secondarySystemFill)
        
        return Button {
//            Haptics.feedback(style: .soft)
            action()
        } label: {
            Text(!string.isEmpty ? string : (isRequired ? "Required" : "Optional"))
                .foregroundColor(!string.isEmpty ? .primary : Color(.tertiaryLabel))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .foregroundColor(fill)
                )
        }
    }
}

public func newMealTime(for date: Date, existingMealTimes: [Date] = []) -> Date {
    
//    func nextAvailableTimeSlot(to time: Date, within date: Date, existingMealTimes: [Date]) -> Int? {
//        let timeSlot = time.timeSlot(within: date) + 1
//        let existingTimeSlots = existingMealTimes.compactMap {
//            $0.timeSlot(within: date)
//        }
//        return nearestAvailableTimeSlot(to: timeSlot, existingTimeSlots: existingTimeSlots)
//    }
//
//    func nearestAvailableTimeSlot(to timeSlot: Int, existingTimeSlots: [Int], allowSearchingBackwards: Bool = false) -> Int? {
//
//        /// First search forwards till the end
//        for t in timeSlot..<K.numberOfSlots {
//            if !existingTimeSlots.contains(t) {
//                return t
//            }
//        }
//
//        guard allowSearchingBackwards else { return nil }
//
//        /// Search backwards
//        for t in (0..<timeSlot-1).reversed() {
//            if !existingTimeSlots.contains(t) {
//                return t
//            }
//        }
//
//        return nil
//    }
    
    if date.isToday {
        
        guard let timeSlot = nearestAvailableTimeSlot(
            to: Date(),
            within: date,
            existingMealTimes: existingMealTimes,
            skippingFirstTimeSlot: true
        ) else {
//        guard let timeSlot = nextAvailableTimeSlot(to: Date(), within: date, existingMealTimes: existingMealTimes) else {
            /// Fallback when all timeSlots are taken
            return Date()
        }
        return date.timeForTimeSlot(timeSlot)
        
    } else {
        
        let lastMealTimeOrNoon = existingMealTimes.sorted(by: { $0 < $1 }).last ?? date.h(12, m: 0, s: 0)
        guard let timeSlot = nearestAvailableTimeSlot(
            to: lastMealTimeOrNoon,
            within: date,
            existingMealTimes: existingMealTimes,
            searchingBothDirections: true
        ) else {
            /// Fallback when all timeSlots are taken
            return date.h(12, m: 0, s: 0)
        }
        return date.timeForTimeSlot(timeSlot)

    }
}
