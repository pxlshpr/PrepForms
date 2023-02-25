import Foundation

extension TimeForm {
    
    func attemptToChangeTimeTo(_ time: Date) {

        let newTime = time

        //TODO: CoreData
//        let meals = Store.meals(onDate: currentDate)
//        for meal in meals {
//
//            /// If it is less than 5 minutes before another meal, choose either 5 minutes before that meal, or 5 minutes after it if that makes it out of bounds for the day
//            /// Keep doing this until we're not conflicting with any other meals
//            if meal.isLessThanOrEqualTo5MinutesAfter(time) {
//                newTime = meal.timeDate.minus5Minutes
//                var goBackwards = true
//                if newTime.isOutOfBoundsFrom(currentDate) {
//                    goBackwards = false
//                }
//                while meals.containsMealWithin5MinutesOf(newTime) {
//                    if goBackwards {
//                        newTime = newTime.minus5Minutes
//                        if newTime.isOutOfBoundsFrom(currentDate) {
//                            goBackwards = false
//                        }
//                    } else {
//                        newTime = newTime.plus5Minutes
//                        if newTime.isOutOfBoundsFrom(currentDate) {
//                            //TODO: Handle cases where we can't go any further (day is completely full)
//                            return
//                        }
//                    }
//                }
//                break
//            }
//
//            /// Otherwise, if it is less than 5 minutes after another meal, choose either 5 minutes after that meal, or 5 minutes before it if that makes it out of bounds for the day
//            /// Keep doing this until we're not conflicting with any other meals
//            else if meal.isLessThanOrEqualTo5MinutesBefore(time) {
//                newTime = meal.timeDate.plus5Minutes
//                var goForwards = true
//                if newTime.isOutOfBoundsFrom(currentDate) {
//                    goForwards = false
//                }
//                while meals.containsMealWithin5MinutesOf(newTime) {
//                    if goForwards {
//                        newTime = newTime.plus5Minutes
//                        if newTime.isOutOfBoundsFrom(currentDate) {
//                            goForwards = false
//                        }
//                    } else {
//                        newTime = newTime.minus5Minutes
//                        if newTime.isOutOfBoundsFrom(currentDate) {
//                            //TODO: Handle cases where we can't go any further (day is completely full)
//                            return
//                        }
//                    }
//                }
//                break
//            }
//        }
//
//        /// If it is out of bounds for the day by being less than 12 am, set it at 12 am—unles we have a meal existing there—in which case keep increasing this by 5 minutes until we find an empty slot
//        if time.isLessThanBoundsFrom(currentDate) {
//            newTime = date(hour: 0, of: currentDate)
//            while meals.containsMealWithin5MinutesOf(newTime) {
//                newTime = newTime.plus5Minutes
//                if newTime.isOutOfBoundsFrom(currentDate) {
//                    return
//                }
//            }
//        }
//        /// If it is out of bounds now by being greater than 6am the next day, set it at 5:55 am—unles we have a meal existing there—in which case keep decreasing this by 5 minutes until we find an empty slot
//        else if time.isGreaterThanBoundsFrom(currentDate) {
//            newTime = date(hour: 5, minute: 55, of: currentDate.moveDayBy(1))
//            while meals.containsMealWithin5MinutesOf(newTime) {
//                newTime = newTime.minus5Minutes
//                if newTime.isOutOfBoundsFrom(currentDate) {
//                    return
//                }
//            }
//        }
//
//        /// Make sure we set viewModel.time manually here as well to keep it in sync
//        /// Make sure we test for recursion here
        self.time = newTime
////        viewModel.time = newTime
        pickerTime = newTime
    }
}
