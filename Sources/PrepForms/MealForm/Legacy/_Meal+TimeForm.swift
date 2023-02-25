//import Foundation
//
//extension Array where Element == Meal {
//    func containsMealWithin5MinutesOf(_ time: Date) -> Bool {
//        contains { meal in
//            meal.isLessThanOrEqualTo5MinutesAfter(time) || meal.isLessThanOrEqualTo5MinutesBefore(time)
//        }
//    }
//}
//
//
//extension Meal {
//    
//    var timelineEmojis: [Emoji] {
//        //TODO: CoreData
//        []
////        itemsArray.compactMap {
////            Emoji(id: $0.id?.uuidString ?? "", emoji: $0.emojiString ?? "")
////        }
//    }
//    
//    var emojis: [String] {
//        //TODO: CoreData
//        []
////        itemsArray.compactMap {
////            $0.emojiString
////        }
//    }
//    
//    func isLessThanOrEqualTo5MinutesAfter(_ time: Date) -> Bool {
//        //TODO: CoreData
//        false
////        time <= self.timeDate && self.timeDate.timeIntervalSince(time) < (5 * 60)
//    }
//    func isLessThanOrEqualTo5MinutesBefore(_ time: Date) -> Bool {
//        //TODO: CoreData
//        false
////        time >= self.timeDate && time.timeIntervalSince(self.timeDate) < (5 * 60)
//    }
//}
