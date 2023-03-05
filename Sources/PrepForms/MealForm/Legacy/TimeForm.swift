import SwiftUI
import SwiftHaptics
import Timeline
import SwiftSugar
import PrepDataTypes

public typealias GetTimelineItemsHandler = ((Date) async throws -> [TimelineItem])

struct TimeForm: View {
    
    @Environment(\.dismiss) var dismiss

    @StateObject var model = Model()
    
    @State var initialTime: Date
    let name: String
    let date: Date
    @Binding var time: Date
    @State var pickerTime: Date
    @StateObject var newMeal: TimelineItem
    
    let getTimelineItemsHandler: GetTimelineItemsHandler?
    @State var timelineItems: [TimelineItem] = []
    
    init(name: String, time: Binding<Date>, date: Date, getTimelineItemsHandler: GetTimelineItemsHandler? = nil) {
        self.date = date
        self.name = name
        self.getTimelineItemsHandler = getTimelineItemsHandler
        _initialTime = State(initialValue: time.wrappedValue)
        _time = time
        _pickerTime = State(initialValue: time.wrappedValue)
        
        let newMeal = TimelineItem(id: UUID().uuidString,
                                   name: name,
                                   date: time.wrappedValue,
                                   type: .meal,
                                   isNew: true)
        _newMeal = StateObject(wrappedValue: newMeal)
    }
    
    var body: some View {
        timeline
//            .background(Color(.tertiarySystemGroupedBackground))
            .toolbar { bottomToolbarContent }
            .toolbar { navigationTrailingContent }
            .toolbar { navigationLeadingContent }
//            .navigationTitle("Time:")
//            .toolbar { navigationTitleContent }
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: pickerTime) { newValue in
                attemptToChangeTimeTo(newValue)
            }
            .onChange(of: time) { newValue in
                withAnimation {
                    newMeal.date = newValue
                }
            }
            .onChange(of: model.time) { newValue in
                attemptToChangeTimeTo(newValue)
                Haptics.feedback(style: .soft)
//                time = newValue
            }
            .onAppear(perform: appeared)
    }
    
    var timeline: some View {
        Timeline(
            items: timelineItems,
            newItem: newMeal,
            didTapInterval: didTapInterval,
            didTapOnNewItem: didTapOnNewItem,
            didTapNow: didTapNow
        )
        .background(Color(.systemGroupedBackground))
    }
    
    func didTapOnNewItem() {
        Haptics.successFeedback()
        dismiss()
    }
    
    //MARK: - UI Components
    var navigationTrailingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            nowButton
        }
    }
    
    @ViewBuilder
    var doneButton: some View {
        if !time.equalsIgnoringSeconds(initialTime) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "checkmark")
            }
            .transition(.scale)
        }
    }
    var navigationTitleContent: some ToolbarContent {
        ToolbarItemGroup(placement: .principal) {
            datePicker
        }
    }

    var navigationLeadingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarLeading) {
            timePicker
        }
    }

    var bottomToolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            button(decrement: 60, hapticStyle: .heavy)
            button(decrement: 15)
            Text("•")
                .foregroundColor(Color(.quaternaryLabel))
            button(increment: 15)
            button(increment: 60, hapticStyle: .heavy)
            Spacer()
            doneButton
        }
    }
    
    @ViewBuilder
    var nowButton: some View {
        if !time.isNowToTheMinute {
            Button("Now") {
                Haptics.successFeedback()
                attemptToChangeTimeTo(Date())
            }
            .transition(.scale)
        }
    }
    
    func button(increment: Int? = nil, decrement: Int? = nil, hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .soft) -> some View {
        Button {
            let interval: TimeInterval
            if let increment = increment {
                interval = TimeInterval(increment)
            } else if let decrement = decrement {
                interval = TimeInterval(-decrement)
            } else {
                interval = 0
            }
            attemptToChangeTimeTo(time.addingTimeInterval(interval * 60))
//            time = time.addingTimeInterval(interval * 60)
//            model.time = time
            Haptics.feedback(style: hapticStyle)
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
        .buttonStyle(BorderlessButtonStyle())
    }
    
    var datePicker: some View {
        let start = date.startOfDay
        let end = date.moveDayBy(1).atEndOfWeeHours
        let range = start...end
        return DatePicker(
            "",
            selection: $pickerTime,
            in: range,
            displayedComponents: [.date]
        )
        .datePickerStyle(.compact)
        .labelsHidden()
    }
    
    var timePicker: some View {
        let start = date.startOfDay
        let end = date.moveDayBy(1).atEndOfWeeHours
        let range = start...end
        return DatePicker("",
                   selection: $pickerTime,
                   in: range,
                   displayedComponents: [.date, .hourAndMinute])
            .datePickerStyle(.compact)
            .labelsHidden()
    }
    
    //MARK: - Actions
    
    func appeared() {
        getTimelineItems()
    }
    
    func getTimelineItems() {
        guard let getTimelineItemsHandler else {
            timelineItems = []
            return
        }
        Task {
            let timelineItems = try await getTimelineItemsHandler(date)
            await MainActor.run {
                self.timelineItems = timelineItems
            }
        }
    }
}

extension TimeForm {
    func didTapInterval(between item1: TimelineItem, and item2: TimelineItem) {
        guard !(item1.isNew || item2.isNew) else {
            return
        }
        guard item2.date > item1.date else {
            return
        }
        let midPoint = ((item2.date.timeIntervalSince1970 - item1.date.timeIntervalSince1970) / 2.0) + item1.date.timeIntervalSince1970
        let midPointDate = Date(timeIntervalSince1970: midPoint)
        withAnimation {
            model.time = midPointDate
        }
    }
    
    func didTapNow() {
        model.time = Date()
    }
}
