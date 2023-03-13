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
            switch restingEnergyInterval.periodType {
            case .average:
                return "daily average"
            case .previousDay:
                guard let timestamp = restingEnergyInterval.timestamp else {
                    return "latest"
                }
                return Date(timeIntervalSince1970: timestamp).biometricEnergyFormat
            }
//        case .formula:
//            return restingEnergyFormulaUsingSyncedHealthData ? "currently" : nil
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
                restingEnergyInterval.period = .day
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
    
    func fetchRestingEnergyFromHealth() {
        
        @Sendable func nextAvailableFetched(_ result: (Double, Date?), for interval: HealthInterval) async {
            await MainActor.run {
                withAnimation {
                    restingEnergy = result.0
                    restingEnergyTextFieldString = "\(Int(result.0.rounded()))"
                    restingEnergySyncStatus = .nextAvailableSynced
                    restingEnergyInterval = interval
                    restingEnergyInterval.timestamp = result.1?.timeIntervalSince1970
                }
            }
        }
        
        @Sendable func latestFailed() async {
            await MainActor.run {
                withAnimation {
                    restingEnergySyncStatus = .lastSyncFailed
                    changeRestingEnergySource(to: .userEntered)
                }
            }
        }
        
        @Sendable func fetchLatestAvailable() async {
            do {
                let interval = HealthInterval(1, .day)
                let result = try await HealthKitManager.shared.restingEnergy(using: userEnergyUnit, for: interval)
                await nextAvailableFetched(result, for: interval)
            } catch {
                await latestFailed()
            }
        }
        
        @Sendable func fetchNextAvailable() async {
            func fetch(for interval: HealthInterval) async -> (Double, Date?)? {
                do {
                    return try await HealthKitManager.shared.restingEnergy(using: userEnergyUnit, for: interval)
                } catch {
                    return nil
                }
            }

            for interval in restingEnergyInterval.greaterIntervals {
                if let result = await fetch(for: interval) {
                    await nextAvailableFetched(result, for: interval)
                    return
                }
            }
            
            await fetchLatestAvailable()
        }
        
        withAnimation {
            restingEnergySyncStatus = .syncing
        }
        
        Task {
            do {
                let (energy, date) = try await HealthKitManager.shared.restingEnergy(using: userEnergyUnit, for: restingEnergyInterval)
                await MainActor.run {
                    withAnimation {
                        restingEnergy = energy
                        restingEnergyTextFieldString = "\(Int(energy.rounded()))"
                        restingEnergySyncStatus = .synced
                        restingEnergyInterval.timestamp = date?.timeIntervalSince1970
                    }
                }
            } catch {
                if restingEnergyInterval.periodType == .previousDay {
                    await latestFailed()
                } else {
                    await fetchNextAvailable()
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
        Array(activeEnergyInterval.period.minValue...activeEnergyInterval.period.maxValue)
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
            switch activeEnergyInterval.periodType {
            case .average:
                return "daily average"
            case .previousDay:
                guard let timestamp = activeEnergyInterval.timestamp else {
                    return "latest"
                }
                return Date(timeIntervalSince1970: timestamp).biometricEnergyFormat
            }
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
            syncActiveEnergy()
        default:
            break
        }
    }
    
    var activeEnergyPeriodTypeBinding: Binding<HealthPeriodType> {
        Binding<HealthPeriodType>(
            get: { self.activeEnergyInterval.periodType },
            set: { newPeriod in
                Haptics.feedback(style: .soft)
                self.changeActiveEnergyPeriodType(to: newPeriod)
            }
        )
    }
    
    func changeActiveEnergyPeriodType(to newPreiodType: HealthPeriodType) {
        withAnimation {
            if newPreiodType == .previousDay {
                activeEnergyInterval.value = 1
                activeEnergyInterval.period = .day
            } else {
                correctActiveEnergyIntervalValueIfNeeded()
            }
        }
        
        syncActiveEnergy()
    }
    
    var activeEnergyIntervalValueBinding: Binding<Int> {
        Binding<Int>(
            get: { self.activeEnergyInterval.value },
            set: { newValue in
                Haptics.feedback(style: .soft)
                self.changeActiveEnergyIntervalValue(to: newValue)
            }
        )
    }
    
    func changeActiveEnergyIntervalValue(to newValue: Int) {
        guard newValue >= activeEnergyInterval.period.minValue,
              newValue <= activeEnergyInterval.period.maxValue else {
            return
        }
        withAnimation {
            activeEnergyInterval.value = newValue
        }
        
        syncActiveEnergy()
    }
    
    var activeEnergyIntervalPeriodBinding: Binding<HealthPeriod> {
        Binding<HealthPeriod>(
            get: { self.activeEnergyInterval.period },
            set: { newInterval in
                Haptics.feedback(style: .soft)
                self.changeActiveEnergyPeriodInterval(to: newInterval)
            }
        )
    }
    
    func changeActiveEnergyPeriodInterval(to newInterval: HealthPeriod) {
        withAnimation {
            activeEnergyInterval.period = newInterval
            correctActiveEnergyIntervalValueIfNeeded()
        }
        
        syncActiveEnergy()
    }
    
    func correctActiveEnergyIntervalValueIfNeeded() {
        activeEnergyInterval.correctIfNeeded()
    }
    
    func syncActiveEnergy() {
        Task {
            await fetchActiveEnergyFromHealth()
            await MainActor.run {
                saveBiometrics()
            }
        }
    }
    
    func fetchActiveEnergyFromHealth() async {
        
        @Sendable func nextAvailableFetched(_ result: (Double, Date?), for interval: HealthInterval) async {
            await MainActor.run {
                withAnimation {
                    activeEnergy = result.0
                    activeEnergyTextFieldString = "\(Int(result.0.rounded()))"
                    activeEnergySyncStatus = .nextAvailableSynced
                    activeEnergyInterval = interval
                    activeEnergyInterval.timestamp = result.1?.timeIntervalSince1970
                }
            }
        }
        
        @Sendable func latestFailed() async {
            await MainActor.run {
                withAnimation {
                    activeEnergySyncStatus = .lastSyncFailed
                    changeActiveEnergySource(to: .userEntered)
                }
            }
        }
        
        @Sendable func fetchLatestAvailable() async {
            do {
                let interval = HealthInterval(1, .day)
                let result = try await HealthKitManager.shared.activeEnergy(using: userEnergyUnit, for: interval)
                await nextAvailableFetched(result, for: interval)
            } catch {
                await latestFailed()
            }
        }
        
        @Sendable func fetchNextAvailable() async {
            func fetch(for interval: HealthInterval) async -> (Double, Date?)? {
                do {
                    return try await HealthKitManager.shared.activeEnergy(using: userEnergyUnit, for: interval)
                } catch {
                    return nil
                }
            }

            for interval in activeEnergyInterval.greaterIntervals {
                if let result = await fetch(for: interval) {
                    await nextAvailableFetched(result, for: interval)
                    return
                }
            }
            
            await fetchLatestAvailable()
        }
        
        await MainActor.run {
            withAnimation {
                activeEnergySyncStatus = .syncing
            }
        }
        
        do {
            let (energy, date) = try await HealthKitManager.shared.activeEnergy(using: userEnergyUnit, for: activeEnergyInterval)
            await MainActor.run {
                withAnimation {
                    activeEnergy = energy
                    activeEnergyTextFieldString = "\(Int(energy.rounded()))"
                    activeEnergySyncStatus = .synced
                    activeEnergyInterval.timestamp = date?.timeIntervalSince1970
                }
            }
        } catch {
            if activeEnergyInterval.periodType == .previousDay {
                await latestFailed()
            } else {
                await fetchNextAvailable()
            }
        }
    }
    
    var activeEnergyFooterString: String? {
//        "This is an estimate of energy burnt over and above your Resting Energy use."
        "This is the additional energy you burn beyond your Resting Energy."
    }
}
