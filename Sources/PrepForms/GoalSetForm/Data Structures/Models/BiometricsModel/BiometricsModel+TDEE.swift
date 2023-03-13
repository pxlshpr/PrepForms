import Foundation
import SwiftUI
import PrepDataTypes
import SwiftHaptics
import PrepCoreDataStack

extension BiometricsModel {
    var maintenanceEnergy: Double? {
        guard let activeEnergyValue, let restingEnergyValue else {
            return nil
        }
        return activeEnergyValue + restingEnergyValue
    }
    
    var maintenanceEnergyInKcal: Double? {
        guard let maintenanceEnergy else { return nil }
        return userEnergyUnit.convert(maintenanceEnergy, to: .kcal)
//        if userEnergyUnit == .kcal {
//            return maintenanceEnergy
//        } else {
//            return maintenanceEnergy / KcalsPerKilojule
//        }
    }
    
    var maintenanceEnergyFormatted: String {
        guard let maintenanceEnergy else { return "" }
        return maintenanceEnergy.formattedEnergy
    }
}


//MARK: - Resting Energy

extension BiometricsModel {
    
    var restingEnergyIsDynamic: Bool {
        switch restingEnergySource {
        case .health:
            return true
        case .formula:
            return restingEnergyFormulaUsingSyncedHealthData
        default:
            return false
        }
    }
    
    var restingEnergyFormulaUsingSyncedHealthData: Bool {
        if restingEnergyFormula.usesLeanBodyMass {
            switch lbmSource {
            case .health:
                return true
            case .fatPercentage:
                return weightSource == .health
            case .formula:
                return weightSource == .health
            default:
                return false
            }
        } else {
            return measurementsAreSynced
        }
    }
    
    var restingEnergyValue: Double? {
        switch restingEnergySource {
        case .formula:
            return calculatedRestingEnergy
        default:
            return restingEnergy
        }
    }
    
    var restingEnergyFormatted: String {
        switch restingEnergySource {
        case .formula:
            return calculatedRestingEnergy?.formattedEnergy ?? "zero" /// this string is required for the redaction to be visible
        default:
            return restingEnergy?.formattedEnergy ?? ""
        }
    }
    
    var restingEnergyIntervalValues: [Int] {
        Array(restingEnergyInterval.period.minValue...restingEnergyInterval.period.maxValue)
    }
    
    var calculatedRestingEnergy: Double? {
        guard restingEnergySource == .formula else { return nil }
        switch restingEnergyFormula {
        case .katchMcardle, .cunningham:
            guard let lbmInKg else { return nil }
            return restingEnergyFormula.calculate(lbmInKg: lbmInKg, energyUnit: userEnergyUnit)
        case .henryOxford, .schofield:
            guard let age, let weightInKg, let sex else { return nil }
            return restingEnergyFormula.calculate(
                age: age,
                weightInKg: weightInKg,
                sexIsFemale: sex == .female,
                energyUnit: userEnergyUnit
            )
        default:
            guard let age, let weightInKg, let heightInCm, let sex else { return nil }
            return restingEnergyFormula.calculate(
                age: age,
                weightInKg: weightInKg,
                heightInCm: heightInCm,
                sexIsFemale: sex == .female,
                energyUnit: userEnergyUnit
            )
        }
    }
    
    var hasRestingEnergy: Bool {
        switch restingEnergySource {
        case .formula:
            return calculatedRestingEnergy != nil
        case .health, .userEntered:
            return restingEnergy != nil
        default:
            return false
        }
    }
    
    var restingEnergyPrefix: String? {
        switch restingEnergySource {
        case .health:
            return restingEnergyInterval.periodType.energyPrefix
        case .formula:
            return restingEnergyFormulaUsingSyncedHealthData ? "currently" : nil
        default:
            return nil
        }
    }
    
    var restingEnergySourceBinding: Binding<RestingEnergySource> {
        Binding<RestingEnergySource>(
            get: { self.restingEnergySource ?? .userEntered },
            set: { newSource in
                Haptics.feedback(style: .soft)
                self.changeRestingEnergySource(to: newSource)
            }
        )
    }
    
    var restingEnergyTextFieldStringBinding: Binding<String> {
        Binding<String>(
            get: { self.restingEnergyTextFieldString },
            set: { newValue in
                guard !newValue.isEmpty else {
                    self.restingEnergy = nil
                    self.restingEnergyTextFieldString = newValue
                    return
                }
                let withoutCommas = newValue.replacingOccurrences(of: ",", with: "")
                guard let double = Double(withoutCommas) else {
                    return
                }
                self.restingEnergy = double
                withAnimation {
                    self.restingEnergyTextFieldString = double.formattedEnergy
                }
            }
        )
    }
    
    func changeRestingEnergySource(to newSource: RestingEnergySource) {
        withAnimation {
            restingEnergySource = newSource
        }
        switch restingEnergySource {
        case .health:
            fetchRestingEnergyFromHealth()
        case .formula:
            break
        default:
            break
        }
    }
    
    var restingEnergyFormulaBinding: Binding<RestingEnergyFormula> {
        Binding<RestingEnergyFormula>(
            get: { self.restingEnergyFormula },
            set: { newFormula in
                Haptics.feedback(style: .soft)
                self.changeRestingEnergyFormula(to: newFormula)
            }
        )
    }
    
    func changeRestingEnergyFormula(to newFormula: RestingEnergyFormula) {
        withAnimation {
            self.restingEnergyFormula = newFormula
        }
    }
    
    var restingEnergyPeriodBinding: Binding<HealthPeriodType> {
        Binding<HealthPeriodType>(
            get: {
                self.restingEnergyInterval.periodType
            },
            set: { newPeriod in
                Haptics.feedback(style: .soft)
                self.changeRestingEnergyPeriod(to: newPeriod)
            }
        )
    }
    
    func changeRestingEnergyPeriod(to newPeriod: HealthPeriodType) {
        withAnimation {
            if newPeriod == .previousDay {
                restingEnergyInterval.value = 1
                restingEnergyInterval.period = .week
            } else {
                correctRestingEnergyIntervalValueIfNeeded()
            }
        }
        fetchRestingEnergyFromHealth()
    }
    
    var restingEnergyIntervalValueBinding: Binding<Int> {
        Binding<Int>(
            get: {
                self.restingEnergyInterval.value
            },
            set: { newValue in
                Haptics.feedback(style: .soft)
                self.changeRestingEnergyIntervalValue(to: newValue)
            }
        )
    }
    
    func changeRestingEnergyIntervalValue(to newValue: Int) {
        guard newValue >= restingEnergyInterval.period.minValue,
              newValue <= restingEnergyInterval.period.maxValue else {
            return
        }
        withAnimation {
            restingEnergyInterval.value = newValue
        }
        fetchRestingEnergyFromHealth()
    }
    
    var restingEnergyIntervalBinding: Binding<HealthPeriod> {
        Binding<HealthPeriod>(
            get: {
                self.restingEnergyInterval.period
            },
            set: { newInterval in
                Haptics.feedback(style: .soft)
                self.changeRestingEnergyInterval(to: newInterval)
            }
        )
    }
    
    func changeRestingEnergyInterval(to newPeriod: HealthPeriod) {
        withAnimation {
            restingEnergyInterval.period = newPeriod
            correctRestingEnergyIntervalValueIfNeeded()
        }
        
        fetchRestingEnergyFromHealth()
    }
    
    func correctRestingEnergyIntervalValueIfNeeded() {
        restingEnergyInterval.correctIfNeeded()
    }
    
    var restingEnergyFooterString: String? {
        "This is the energy your body uses each day while minimally active."
    }

    func setAndetchRestingEnergyFromHealth() {
    }
    
    func fetchRestingEnergyFromHealth() {
        
        @Sendable func nextAvailableFetched(_ energy: Double, for interval: HealthInterval) async {
            await MainActor.run {
                withAnimation {
                    Haptics.warningFeedback()
                    restingEnergy = energy
                    restingEnergyTextFieldString = "\(Int(energy.rounded()))"
                    //TODO: Show different state here
                    restingEnergySyncStatus = .lastSyncFailed
                    restingEnergyInterval = interval
                }
            }
        }
        
        @Sendable func latestFailed() async {
            await MainActor.run {
                withAnimation {
                    Haptics.errorFeedback()
                    restingEnergySyncStatus = .lastSyncFailed
                    changeRestingEnergySource(to: .userEntered)
                }
            }
        }
        
        @Sendable func fetchLatestAvailableRestingEnergy() async {
            do {
                let interval = HealthInterval(1, .day)
                let energy = try await HealthKitManager.shared.restingEnergy(using: userEnergyUnit, for: interval)
                await nextAvailableFetched(energy, for: interval)
            } catch {
                await latestFailed()
            }
        }
        
        @Sendable func fetchNextAvailableRestingEnergy() async {
            func fetchRestingEnergy(for interval: HealthInterval) async -> Double? {
                do {
                    return try await HealthKitManager.shared.restingEnergy(using: userEnergyUnit, for: interval)
                } catch {
                    return nil
                }
            }

            for interval in restingEnergyInterval.greaterIntervals {
                if let energy = await fetchRestingEnergy(for: interval) {
                    await nextAvailableFetched(energy, for: interval)
                    return
                }
            }
            
            await fetchLatestAvailableRestingEnergy()
        }
        
        withAnimation {
            restingEnergySyncStatus = .syncing
        }
        
        Task {
            do {
                let energy = try await HealthKitManager.shared.restingEnergy(using: userEnergyUnit, for: restingEnergyInterval)
                await MainActor.run {
                    withAnimation {
                        restingEnergy = energy
                        restingEnergyTextFieldString = "\(Int(energy.rounded()))"
                        restingEnergySyncStatus = .synced
                    }
                }
            } catch {
                if restingEnergyInterval.periodType == .previousDay {
                    await latestFailed()
                } else {
                    await fetchNextAvailableRestingEnergy()
                }
            }
        }
    }
}

//MARK: - Active Energy

extension BiometricsModel {
    
    var activeEnergyIsDynamic: Bool {
        switch activeEnergySource {
        case .health:
            return true
        default:
            return false
        }
    }
    
    var activeEnergyFormatted: String {
        switch activeEnergySource {
        case .activityLevel:
            return calculatedActiveEnergy?.formattedEnergy ?? "zero"
        default:
            return activeEnergy?.formattedEnergy ?? ""
        }
    }
    
    var activeEnergyIntervalValues: [Int] {
        Array(activeEnergyInterval.minValue...activeEnergyInterval.maxValue)
    }
    
    var calculatedActiveEnergy: Double? {
        guard activeEnergySource == .activityLevel,
              let restingEnergy = restingEnergyValue
        else { return nil }
        
        let total = activeEnergyActivityLevel.scaleFactor * restingEnergy
        return total - restingEnergy
    }
    
    var activeEnergyActivityLevelBinding: Binding<ActivityLevel> {
        Binding<ActivityLevel>(
            get: { self.activeEnergyActivityLevel },
            set: { newActivityLevel in
                Haptics.feedback(style: .soft)
                self.changeActiveEnergyActivityLevel(to: newActivityLevel)
            }
        )
    }
    
    func changeActiveEnergyActivityLevel(to newFormula: ActivityLevel) {
        withAnimation {
            self.activeEnergyActivityLevel = newFormula
        }
    }
    
    var activeEnergyValue: Double? {
        switch activeEnergySource {
        case .activityLevel:
            return calculatedActiveEnergy
        default:
            return activeEnergy
        }
    }
    
    var activeEnergyBiometricValue: BiometricValue? {
        guard let activeEnergyValue else { return nil }
        return .activeEnergy(activeEnergyValue, userEnergyUnit)
    }

    var ageBiometricValue: BiometricValue? {
        guard let age else { return nil }
        return .age(age)
    }

    var sexBiometricValue: BiometricValue? {
        guard let sex else { return nil }
        return .sex(sex.biometricSex)
    }

    var heightBiometricValue: BiometricValue? {
        guard let height else { return nil }
        return .height(height, userHeightUnit)
    }

    var weightBiometricValue: BiometricValue? {
        guard let weight else { return nil }
        return .weight(weight, userBodyMassUnit)
    }

    var leanBodyMassBiometricValue: BiometricValue? {
        guard let lbm else { return nil }
        return .leanBodyMass(lbm, userBodyMassUnit)
    }

    var restingEnergyBiometricValue: BiometricValue? {
        guard let restingEnergyValue else { return nil }
        return .restingEnergy(restingEnergyValue, userEnergyUnit)
    }

    var hasActiveEnergy: Bool {
        switch activeEnergySource {
        case .activityLevel:
            return calculatedActiveEnergy != nil
        case .health, .userEntered:
            return activeEnergy != nil
        default:
            return false
        }
    }
    
    var activeEnergyPrefix: String? {
        switch activeEnergySource {
        case .health:
            return activeEnergyPeriod.energyPrefix
        default:
            return nil
        }
    }
    
    var activeEnergySourceBinding: Binding<ActiveEnergySource> {
        Binding<ActiveEnergySource>(
            get: { self.activeEnergySource ?? .userEntered },
            set: { newSource in
                Haptics.feedback(style: .soft)
                self.changeActiveEnergySource(to: newSource)
            }
        )
    }
    
    var activeEnergyTextFieldStringBinding: Binding<String> {
        Binding<String>(
            get: { self.activeEnergyTextFieldString },
            set: { newValue in
                guard !newValue.isEmpty else {
                    self.activeEnergy = nil
                    self.activeEnergyTextFieldString = newValue
                    return
                }
                let withoutCommas = newValue.replacingOccurrences(of: ",", with: "")
                guard let double = Double(withoutCommas) else {
                    return
                }
                self.activeEnergy = double
                withAnimation {
                    self.activeEnergyTextFieldString = double.formattedEnergy
                }
            }
        )
    }
    
    func changeActiveEnergySource(to newSource: ActiveEnergySource) {
        withAnimation {
            activeEnergySource = newSource
        }
        switch activeEnergySource {
        case .health:
            fetchActiveEnergyFromHealth()
        default:
            break
        }
    }
    
    var activeEnergyPeriodBinding: Binding<HealthPeriodType> {
        Binding<HealthPeriodType>(
            get: { self.activeEnergyPeriod },
            set: { newPeriod in
                Haptics.feedback(style: .soft)
                self.changeActiveEnergyPeriod(to: newPeriod)
            }
        )
    }
    
    func changeActiveEnergyPeriod(to newPeriod: HealthPeriodType) {
        withAnimation {
            self.activeEnergyPeriod = newPeriod
            if newPeriod == .previousDay {
                activeEnergyIntervalValue = 1
                activeEnergyInterval = .day
            } else {
                correctActiveEnergyIntervalValueIfNeeded()
            }
        }
        fetchActiveEnergyFromHealth()
    }
    
    var activeEnergyIntervalValueBinding: Binding<Int> {
        Binding<Int>(
            get: { self.activeEnergyIntervalValue },
            set: { newValue in
                Haptics.feedback(style: .soft)
                self.changeActiveEnergyIntervalValue(to: newValue)
            }
        )
    }
    
    func changeActiveEnergyIntervalValue(to newValue: Int) {
        guard newValue >= activeEnergyInterval.minValue,
              newValue <= activeEnergyInterval.maxValue else {
            return
        }
        withAnimation {
            activeEnergyIntervalValue = newValue
        }
        fetchActiveEnergyFromHealth()
    }
    
    var activeEnergyIntervalBinding: Binding<HealthPeriod> {
        Binding<HealthPeriod>(
            get: { self.activeEnergyInterval },
            set: { newInterval in
                Haptics.feedback(style: .soft)
                self.changeActiveEnergyInterval(to: newInterval)
            }
        )
    }
    
    func changeActiveEnergyInterval(to newInterval: HealthPeriod) {
        withAnimation {
            activeEnergyInterval = newInterval
            correctActiveEnergyIntervalValueIfNeeded()
        }
        
        fetchActiveEnergyFromHealth()
    }
    
    func correctActiveEnergyIntervalValueIfNeeded() {
        if activeEnergyIntervalValue < activeEnergyInterval.minValue {
            activeEnergyIntervalValue = activeEnergyInterval.minValue
        }
        if activeEnergyIntervalValue > activeEnergyInterval.maxValue {
            activeEnergyIntervalValue = activeEnergyInterval.maxValue
        }
    }
    
    func fetchActiveEnergyFromHealth() {
        withAnimation {
            activeEnergySyncStatus = .syncing
        }
        
        Task {
            do {
                let average = try await HealthKitManager.shared.activeEnergy(
                    using: userEnergyUnit,
                    overPast: activeEnergyIntervalValue,
                    interval: activeEnergyInterval
                )
                await MainActor.run {
                    withAnimation {
                        cprint("🔥 setting average: \(average)")
                        activeEnergy = average
                        activeEnergyTextFieldString = "\(Int(average.rounded()))"
                        activeEnergySyncStatus = .synced
                    }
                }
            } catch {
                await MainActor.run {
                    withAnimation {
                        Haptics.errorFeedback()
                        activeEnergySyncStatus = .lastSyncFailed
                        //TODO: We should try other intervals if the chosen one fails
                        /// [ ] If the chosen one fails, get the latest available value instead
                        /// [ ] Still show the sync failed status, but in the message say it `wasn't available for the period you chose`
                        /// [ ] If we don't get any value, have the message say the default (no data or no permissions) fail message
//                        changeAgeSource(to: .userEntered)
                    }
                }
            }
            /// [ ] Make sure we persist this to the backend once the user saves it
        }
    }
    
    var activeEnergyFooterString: String? {
//        "This is an estimate of energy burnt over and above your Resting Energy use."
        "This is the additional energy you burn beyond your Resting Energy."
    }
}
