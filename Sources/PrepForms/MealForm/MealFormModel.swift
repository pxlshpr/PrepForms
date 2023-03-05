import SwiftUI
import PrepDataTypes

public class MealFormModel: ObservableObject {
    
    let mealBeingEdited: DayMeal?
    let date: Date
    
    let recents: [String]
    let presets: [String]

    @Published var name = ""
    @Published var time: Date
    
    @Published var goalSet: GoalSet?
    
    let didSave: (String, Date, GoalSet?) -> ()
    let getTimelineItemsHandler: GetTimelineItemsHandler?

    let initialName: String?
    let initialTime: Date?
    
    public init(
        mealBeingEdited: DayMeal?,
        date: Date,
        recents: [String] = [],
        presets: [String]? = nil,
        getTimelineItemsHandler: GetTimelineItemsHandler? = nil,
        didSave: @escaping (String, Date, GoalSet?) -> ()
    ) {
        /// Keep in mind that this could be the day before what is indicated in `time`
        /// if we're adding a meal in the wee-hours
        self.date = date
        self.mealBeingEdited = mealBeingEdited
        
        if let mealBeingEdited {
            self.time = Date(timeIntervalSince1970: mealBeingEdited.time)
            self.name = mealBeingEdited.name
            
            self.initialTime = nil
            self.initialName = nil
        } else {
            let name = newMealName(for: date)
            self.time = date
            self.name = name
            
            self.initialTime = date
            self.initialName = name
        }
        
        self.recents = recents
        self.presets = presets ?? Presets
        self.didSave = didSave
        self.getTimelineItemsHandler = getTimelineItemsHandler
    }
    
}

extension MealFormModel {
    func didTapTimeButton(
        increment: Int? = nil,
        decrement: Int? = nil
    ) {
        let interval: TimeInterval
        if let increment = increment {
            interval = TimeInterval(increment)
        } else if let decrement = decrement {
            interval = TimeInterval(-decrement)
        } else {
            interval = 0
        }
        let newTime = time.addingTimeInterval(interval * 60)
        self.time = newTime
        //            self.pickerTime = newTime
    }
    
    var dateRangeForPicker: ClosedRange<Date> {
        let start = date.startOfDay
        let end = date.moveDayBy(1).atEndOfWeeHours
        return start...end
    }
    
    var timeBinding: Binding<Date> {
        Binding<Date>(
            get: {
                return self.time
            },
            set: { newValue in
                self.time = newValue
            }
        )
    }
    
    var timeString: String {
        if time.startOfDay == Date().startOfDay {
            return "Today \(time.shortTimeString)"
        } else {
            return time.shortString
        }
    }
    
    func tappedAdd() {
        didSave(name, time, goalSet)
    }
    
    var shouldShowDurationPicker: Bool {
        guard let goalSet else { return false }
        return goalSet.containsWorkoutDurationDependentGoal
    }
    
    var isEditing: Bool {
        mealBeingEdited != nil
    }
    
    var navigationTitle: String {
        isEditing ? "Edit Meal" : "Add Meal"
    }
    
    var saveButtonTitle: String {
        isEditing ? "Save" : "Add"
    }
    
    var isDirty: Bool {
        
        guard let mealBeingEdited else {
            return !name.isEmpty
        }
        return (mealBeingEdited.name != name && !name.isEmpty)
        || mealBeingEdited.time != time.timeIntervalSince1970
        || mealBeingEdited.goalSet?.id != goalSet?.id
    }
    
    var shouldConfirmCancellation: Bool {
        if isEditing {
            return isDirty
        } else {
            if initialName == name, initialTime == time {
                return false
            } else if name.isEmpty {
                return false
            } else {
                return true
            }
        }
    }
}

let Presets = ["Breakfast", "Lunch", "Dinner", "Pre-workout Meal", "Post-workout Meal", "Intra-workout Snack", "Snack", "Dinner Out", "Supper", "Midnight Snack"]
