import HealthKit
import PrepDataTypes

extension EnergyUnit {
    var healthKitUnit: HKUnit {
        switch self {
        case .kcal:
            return .kilocalorie()
        case .kJ:
            return .jouleUnit(with: .kilo)
        }
    }
}

class HealthKitManager: ObservableObject {

    static let shared = HealthKitManager()
    
    let store: HKHealthStore = HKHealthStore()
    
    func requestPermission(for type: HKQuantityTypeIdentifier) async throws {
        try await requestPermissions(quantityTypes: [type])
    }
    
    func requestPermission(for characteristicType: HKCharacteristicTypeIdentifier) async throws {
        try await requestPermissions(characteristicTypes: [characteristicType])
    }
    
    func requestPermissions(characteristicTypes: [HKCharacteristicTypeIdentifier] = [], quantityTypes: [HKQuantityTypeIdentifier] = []) async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitManagerError.healthKitNotAvailable
        }
        
        var readTypes: [HKObjectType] = []
        readTypes.append(contentsOf: quantityTypes.compactMap { HKQuantityType($0) })
        readTypes.append(contentsOf: characteristicTypes.compactMap { HKCharacteristicType($0) } )

        do {
            try await store.requestAuthorization(toShare: Set(), read: Set(readTypes))
        } catch {
            throw HealthKitManagerError.permissionsError(error)
        }
    }
    
    //MARK: Legacy
    func requestPermission() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            return false
        }
        
        let quantityTypes: [HKQuantityTypeIdentifier] = [
            .activeEnergyBurned,
            .basalEnergyBurned,
            .bodyMass,
            .bodyFatPercentage,
            .height,
        ]
        
        let characteristicTypes: [HKCharacteristicTypeIdentifier] = [
            .biologicalSex,
            .dateOfBirth,
            .wheelchairUse, //TODO: Set this in our backend under the User's characteristics and use it in TDEE calculation
            .activityMoveMode //TODO: Remove this after checking it out
        ]

        var readTypes: [HKObjectType] = []
        readTypes.append(contentsOf: quantityTypes.compactMap { HKQuantityType($0) })
        readTypes.append(contentsOf: characteristicTypes.compactMap { HKCharacteristicType($0) } )

        do {
            try await store.requestAuthorization(toShare: Set(), read: Set(readTypes))
            return true
        } catch {
            cprint("Error requesting authorization: \(error)")
            return false
        }

//        dispatch_async(dispatch_get_main_queue(), self.startObservingHeightChanges)

    }

    func startObservingHeightChanges() {
//
//       let sampleType =  HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight)
//
//       var query: HKObserverQuery = HKObserverQuery(sampleType: sampleType, predicate: nil, updateHandler: self.heightChangedHandler)
//
//       healthKitStore.executeQuery(query)
//       healthKitStore.enableBackgroundDeliveryForType(sampleType, frequency: .Immediate, withCompletion: {(succeeded: Bool, error: NSError!) in
//
//           if succeeded{
//               println("Enabled background delivery of weight changes")
//           } else {
//               if let theError = error{
//                   cprint("Failed to enable background delivery of weight changes. ")
//                   println("Error = \(theError)")
//               }
//           }
//       })
   }

    func heightChangedHandler(query: HKObserverQuery!, completionHandler: HKObserverQueryCompletionHandler!, error: NSError!) {
//
//       // Here you need to call a function to query the height change
//
//       // Send the notification to the user
//       var notification = UILocalNotification()
//       notification.alertBody = "Changed height in Health App"
//       notification.alertAction = "open"
//       notification.soundName = UILocalNotificationDefaultSoundName
//
//       UIApplication.sharedApplication().scheduleLocalNotification(notification)
//
//       completionHandler()
   }

//   func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
//
//       application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: .Alert | .Badge | .Sound, categories: nil))
//
//       self.authorizeHealthKit { (authorized,  error) -> Void in
//           if authorized {
//               println("HealthKit authorization received.")
//           }
//           else {
//               println("HealthKit authorization denied!")
//               if error != nil {
//                   println("\(error)")
//               }
//           }
//       }
//
//       return true
//   }
}

extension WeightUnit {
    var healthKitUnit: HKUnit {
        switch self {
        case .g:
            return .gram()
        case .kg:
            return .gramUnit(with: .kilo)
        case .oz:
            return .ounce()
        case .lb:
            return .pound()
        case .mg:
            return .gramUnit(with: .milli)
        }
    }
}

extension HealthKitManager {
    func latestHeight(unit: HeightUnit) async -> (Double, Date)? {
        do {
            try await HealthKitManager.shared.requestPermission(for: .height)
            return await getLatestQuantity(for: .height, using: unit.healthKitUnit)
        } catch {
            return nil
        }
    }

    func latestWeight(unit: WeightUnit) async -> (Double, Date)? {
        do {
            try await HealthKitManager.shared.requestPermission(for: .bodyMass)
            return await getLatestQuantity(for: .bodyMass, using: unit.healthKitUnit)
        } catch {
            return nil
        }
    }

    func currentBiologicalSex() async -> HKBiologicalSex? {
        do {
            try await HealthKitManager.shared.requestPermission(for: .biologicalSex)
            return try store.biologicalSex().biologicalSex
        } catch {
            cprint("Error getting biological sex")
            return nil
        }
    }
    
    func currentDateOfBirthComponents() async -> DateComponents? {
        do {
            return try store.dateOfBirthComponents()
        } catch {
            cprint("Error getting date of birth")
            return nil
        }
    }


    func latestLeanBodyMass(unit: WeightUnit) async -> (Double, Date)? {
        do {
            try await HealthKitManager.shared.requestPermission(for: .leanBodyMass)
            return await getLatestQuantity(for: .leanBodyMass, using: unit.healthKitUnit)
        } catch {
            return nil
        }
    }

    func getLatestHeight() async -> (Double, Date)? {
        await getLatestQuantity(for: .height, using: .meterUnit(with: .centi))
    }

    func getLatestQuantity(for typeIdentifier: HKQuantityTypeIdentifier, using unit: HKUnit) async -> (Double, Date)? {
        do {
            let sample = try await getLatestQuantitySample(for: typeIdentifier)
            let quantity = sample.quantity.doubleValue(for: unit)
            let date = sample.startDate
            return (quantity, date)
        } catch {
            //TODO: This might be an indiciator of needing permissions
            cprint("Error getting quantity")
            return nil
        }
    }
    
    var biologicalSex: HKBiologicalSex {
        do {
            return try store.biologicalSex().biologicalSex
        } catch {
            cprint("Error getting biological sex")
            return .notSet
        }
    }

    var dateOfBirth: Date? {
        do {
            return try store.dateOfBirthComponents().date
        } catch {
            cprint("Error getting age")
            return nil
        }
    }
    
    func averageSumOfRestingEnergy(using energyUnit: EnergyUnit, overPast value: Int, interval: HealthAppInterval) async throws -> Double? {
        try await HealthKitManager.shared.requestPermission(for: .basalEnergyBurned)
        return try await averageSum(
            for: .basalEnergyBurned,
            using: energyUnit.healthKitUnit,
            overPast: value,
            interval: interval,
            considerEmptyDaysAsZero: false /// this makes sure we're not counting days that had no recorded resting energy as that would be impossible unless you were dead
        )
    }

    func averageSumOfActiveEnergy(using energyUnit: EnergyUnit, overPast value: Int, interval: HealthAppInterval) async throws -> Double? {
        try await averageSum(
            for: .activeEnergyBurned,
            using: energyUnit.healthKitUnit,
            overPast: value,
            interval: interval,
            considerEmptyDaysAsZero: true /// this makes sure we're dividing by the total number of days, even those where we had no recorded activity
        )
    }

    func averageSum(for typeIdentifier: HKQuantityTypeIdentifier, using unit: HKUnit, overPast value: Int, interval: HealthAppInterval, considerEmptyDaysAsZero: Bool = true) async throws -> Double? {
        /// Get the date range
        guard let dateRange = interval.dateRangeOfPast(value) else {
            throw HealthKitManagerError.dateCreationError
        }
        
        return try await averageSumUsingIntervals(for: typeIdentifier, using: unit, in: dateRange, considerEmptyDaysAsZero: considerEmptyDaysAsZero)
    }

    func averageSumUsingIntervals(for typeIdentifier: HKQuantityTypeIdentifier, using unit: HKUnit, in dateRange: ClosedRange<Date>, considerEmptyDaysAsZero: Bool) async throws -> Double? {
        /// Always get samples up to the start of tomorrow, so that we get all of today's results too in case we need it
        let endDate = Date().startOfDay.moveDayBy(1)
        
        let datePredicate = HKQuery.predicateForSamples(withStart: dateRange.lowerBound, end: endDate)

        /// Create the query descriptor.
        let type = HKSampleType.quantityType(forIdentifier: typeIdentifier)!
        let samplesPredicate = HKSamplePredicate.quantitySample(type: type, predicate: datePredicate)

        /// We want the sum of each day
        let everyDay = DateComponents(day: 1)

        let asyncQuery = HKStatisticsCollectionQueryDescriptor(
            predicate: samplesPredicate,
            options: .cumulativeSum,
            anchorDate: endDate,
            intervalComponents: everyDay
        )
        let collection = try await asyncQuery.result(for: store)
        
        var sumQuantities: [Date: HKQuantity] = [:]
        for day in dateRange.days {
            guard let statistics = collection.statistics(for: day) else {
                throw HealthKitManagerError.couldNotGetStatistics
            }
            guard let sumQuantity = statistics.sumQuantity() else {
                cprint("Could not get sumQuantity for \(day)")
                continue
            }
            sumQuantities[day] = sumQuantity
        }
        
        guard !sumQuantities.isEmpty else {
            return nil
        }
        
        let sum = sumQuantities
            .values
            .map { $0.doubleValue(for: unit) }
            .reduce(0, +)
        
        /// We're using the number of days here because there may have been days where we recorded 0
        if considerEmptyDaysAsZero {
            return sum / Double(dateRange.days.count)
        } else {
            return sum / Double(sumQuantities.count)
        }
    }
    
    /// We had previously used this to try and speed up the query to no avail. This seemingly only marginally improved the efficiency if at all (it was slower sometimes)—with a tradeoff of accuracy as the results don't correlate precisely with what HealthKit reports.
    func averageSumUsingTotal(for typeIdentifier: HKQuantityTypeIdentifier, using unit: HKUnit, in dateRange: ClosedRange<Date>) async throws -> Double? {
        let lower = dateRange.lowerBound.moveDayBy(1)
        let upper = dateRange.upperBound.moveDayBy(1)
        let type = HKSampleType.quantityType(forIdentifier: typeIdentifier)!
        let datePredicate = HKQuery.predicateForSamples(withStart: lower, end: upper)
        let samplesPredicate = HKSamplePredicate.quantitySample(type: type, predicate: datePredicate)
        let asyncQuery = HKStatisticsQueryDescriptor(predicate: samplesPredicate, options: .cumulativeSum)
        
        let result = try await asyncQuery.result(for: store)
        guard let sum = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) else {
            throw HealthKitManagerError.couldNotGetSumQuantity
        }
        return sum/Double(upper.numberOfDaysFrom(lower))
    }

    private func getLatestQuantitySample(for typeIdentifier: HKQuantityTypeIdentifier) async throws -> HKQuantitySample {
        let type = HKSampleType.quantityType(forIdentifier: typeIdentifier)!
        let predicates: [HKSamplePredicate<HKSample>] = [HKSamplePredicate.sample(type: type)]
        let sortDescriptors: [SortDescriptor<HKSample>] = [SortDescriptor(\.startDate, order: .reverse)]
        let limit = 1
        let asyncQuery = HKSampleQueryDescriptor(predicates: predicates, sortDescriptors: sortDescriptors, limit: limit)
        let results = try await asyncQuery.result(for: store)
        guard let sample = results.first as? HKQuantitySample else {
            throw HealthKitManagerError.couldNotGetSample
        }
        return sample
    }
}

enum HealthKitManagerError: Error {
    case healthKitNotAvailable
    case permissionsError(Error)
    case couldNotGetSample
    case couldNotGetStatistics
    case couldNotGetSumQuantity
    case dateCreationError
}

public extension Date {
    func moveHoursBy(_ hourIncrement: Int) -> Date {
        var components = DateComponents()
        components.hour = hourIncrement
        return Calendar.current.date(byAdding: components, to: self)!
    }
}
