import SwiftUI
import SwiftHaptics
import PrepViews
import SwiftUISugar
import PrepDataTypes

extension MealForm {
    struct TimeForm: View {

        @StateObject var viewModel: ViewModel

        @Environment(\.dismiss) var dismiss
        @Environment(\.colorScheme) var colorScheme
        @FocusState var isFocused: Bool
        
        @State var hasFocusedOnAppear: Bool = false
        @State var hasCompletedFocusedOnAppearAnimation: Bool = false
        
        let date: Date
        @Binding var time: Date
        @Binding var existingMealTimes: [Date]
        
        @State var lastTime: Date = Date()
        @State var refreshDatePicker: Bool = false

        init(date: Date, time: Binding<Date>, existingMealTimes: Binding<[Date]>) {
            self.date = date
            let viewModel = ViewModel(initialTime: time.wrappedValue)
            _viewModel = StateObject(wrappedValue: viewModel)
            _existingMealTimes = existingMealTimes
            _time = time
        }
        
        class ViewModel: ObservableObject {
            let initialTime: Date
            @Published var internalTime: Date

            init(initialTime: Date) {
                self.initialTime = initialTime
                self.internalTime = initialTime
            }
            
            var shouldDisableDone: Bool {
                if initialTime == internalTime {
                    return true
                }

                return false
            }
        }
    }
}

extension MealForm.TimeForm {
    
    var body: some View {
        QuickForm(title: "Time") {
            timeSection
            saveButton
        }
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: isFocused, perform: isFocusedChanged)
        .onChange(of: viewModel.internalTime, perform: timeChanged)
        .presentationDetents([.height(368)])
        .presentationDragIndicator(.hidden)
    }
    
    var saveActionBinding: Binding<FormConfirmableAction?> {
        Binding<FormConfirmableAction?>(
            get: {
                .init(
                    isDisabled: viewModel.shouldDisableDone,
                    buttonImage: "checkmark") {
                        tappedDone()
                    }
            },
            set: { _ in }
        )
    }
    var doneButton: some View {
        FormInlineDoneButton(disabled: viewModel.shouldDisableDone) {
            tappedDone()
        }
    }
    
    func tappedDone() {
        refreshDatePicker.toggle()
        dismissAfterSetting(viewModel.internalTime)
    }
    
    var timeSection: some View {
        FormStyledSection {
            VStack {
                HStack {
                    Text("Time")
                        .foregroundColor(.secondary)
                    datePicker
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                timeSlider
            }
        }
    }
    
    var datePicker: some View {
        DatePicker(
            "",
            selection: $viewModel.internalTime,
            in: dateRangeForPicker,
            displayedComponents: [.date, .hourAndMinute]
        )
        .datePickerStyle(.compact)
        .labelsHidden()
        .onChange(of: viewModel.internalTime, perform: onChangeOfTime)
        .id(refreshDatePicker)
    }
    
    var timeSlider: some View {
        TimeSlider(
            date: self.date,
            existingTimeSlots: existingTimeSlots,
            currentTime: $viewModel.internalTime,
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
        viewModel.internalTime.timeSlot(within: date)
    }
    
    var existingTimeSlots: [Int] {
        existingMealTimes.map {
            $0.timeSlot(within: date)
        }
    }
    
    func timeChanged(_ newTime: Date) {
        let timeSlot = newTime.timeSlot(within: date)
        if existingTimeSlots.contains(timeSlot) {
            guard let nearestAvailable = nearestAvailableTimeSlot(
                to: timeSlot,
                existingTimeSlots: existingTimeSlots,
                ignoring: currentTimeSlot,
                searchingBothDirections: true
            ) else {
//            guard let nearestAvailable = nearestAvailableTimeSlot(to: timeSlot) else {
                viewModel.internalTime = lastTime
                return
            }
            viewModel.internalTime = date.timeForTimeSlot(nearestAvailable)
        }
    }
    
    
    func dismissAfterSetting(_ time: Date) {
        Haptics.feedback(style: .rigid)
        self.time = time
        dismiss()
    }
    

    func isFocusedChanged(_ newValue: Bool) {
        if !isFocused {
            dismiss()
        }
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
            dismissAfterSetting(viewModel.internalTime)
        } label: {
            Text("Done")
                .bold()
                .foregroundColor((colorScheme == .light && viewModel.shouldDisableDone) ? .black : .white)
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
        .disabled(viewModel.shouldDisableDone)
        .opacity(viewModel.shouldDisableDone ? (colorScheme == .light ? 0.2 : 0.2) : 1)
    }
}
