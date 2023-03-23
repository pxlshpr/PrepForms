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
        return UserManager.energyUnit.convert(maintenanceEnergy, to: .kcal)
    }
    
    var maintenanceEnergyFormatted: String {
        guard let maintenanceEnergy else { return "" }
        return maintenanceEnergy.formattedEnergy
    }
}


//MARK: - Resting Energy

extension BiometricsModel {
    
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
            return restingEnergyFormula.calculate(lbmInKg: lbmInKg, energyUnit: UserManager.energyUnit)
        case .henryOxford, .schofield:
            guard let age, let weightInKg, let sex else { return nil }
            return restingEnergyFormula.calculate(
                age: age,
                weightInKg: weightInKg,
                sexIsFemale: sex == .female,
                energyUnit: UserManager.energyUnit
            )
        default:
            guard let age, let weightInKg, let heightInCm, let sex else { return nil }
            return restingEnergyFormula.calculate(
                age: age,
                weightInKg: weightInKg,
                heightInCm: heightInCm,
                sexIsFemale: sex == .female,
                energyUnit: UserManager.energyUnit
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
            case .latest:
                guard let timestamp = restingEnergyInterval.timestamp else {
                    return "latest"
                }
                return Date(timeIntervalSince1970: timestamp).biometricEnergyFormat
            }
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
            restingEnergySyncStatus = .syncing
            syncRestingEnergy()
        default:
            saveBiometrics()
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
        saveBiometrics()
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
            if newPeriod == .latest {
                restingEnergyInterval.value = 1
                restingEnergyInterval.period = .day
            } else {
                correctRestingEnergyIntervalValueIfNeeded()
            }
        }
        syncRestingEnergy(ignoringInterval: true)
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
        restingEnergySyncStatus = .syncing
        syncRestingEnergy()
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
        
        restingEnergySyncStatus = .syncing
        syncRestingEnergy()
    }
    
    func syncRestingEnergy(ignoringInterval: Bool = false) {
        Task {
            await fetchRestingEnergyFromHealth(ignoringInterval: ignoringInterval)
            await MainActor.run {
                saveBiometrics()
            }
        }
    }
    
    func correctRestingEnergyIntervalValueIfNeeded() {
        restingEnergyInterval.correctIfNeeded()
    }
    
    var restingEnergyFooterString: String? {
        "This is the energy your body uses each day while minimally active."
    }
    
    func fetchRestingEnergyFromHealth(ignoringInterval: Bool = false) async {
        
        guard let (value, date, interval) = await HealthKitManager.shared.fetchEnergy(
            type: .basalEnergyBurned,
            using: UserManager.energyUnit,
            for: restingEnergyInterval
        ) else {
            await MainActor.run {
                withAnimation {
                    restingEnergySyncStatus = .lastSyncFailed
                    changeRestingEnergySource(to: .userEntered)
                }
            }
            return
        }

        await MainActor.run {
            withAnimation {
                if ignoringInterval {
                    restingEnergySyncStatus = .synced
                } else {
                    let gotRequestedInterval = interval.equalsWithoutTimestamp(restingEnergyInterval)
                    restingEnergySyncStatus = gotRequestedInterval ? .synced : .nextAvailableSynced
                }
                restingEnergy = value
                restingEnergyTextFieldString = "\(Int(value.rounded()))"
                restingEnergyInterval = interval
                restingEnergyInterval.timestamp = date?.timeIntervalSince1970
            }
        }
    }
}

//MARK: - Active Energy

extension BiometricsModel {
    
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
        saveBiometrics()
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
        return .activeEnergy(activeEnergyValue, UserManager.energyUnit)
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
        return .height(height, UserManager.heightUnit)
    }

    var weightBiometricValue: BiometricValue? {
        guard let weight else { return nil }
        return .weight(weight, UserManager.bodyMassUnit)
    }

    var leanBodyMassBiometricValue: BiometricValue? {
        guard let lbm else { return nil }
        if lbmSource == .fatPercentage {
            return .fatPercentage(lbm)
        } else {
            guard let lbmValue else { return nil }
            return .leanBodyMass(lbmValue, UserManager.bodyMassUnit)
        }
    }

    var restingEnergyBiometricValue: BiometricValue? {
        guard let restingEnergyValue else { return nil }
        return .restingEnergy(restingEnergyValue, UserManager.energyUnit)
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
            case .latest:
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
            activeEnergySyncStatus = .syncing
            syncActiveEnergy()
        default:
            saveBiometrics()
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
            if newPreiodType == .latest {
                activeEnergyInterval.value = 1
                activeEnergyInterval.period = .day
            } else {
                correctActiveEnergyIntervalValueIfNeeded()
            }
        }
        
        /// Ignore interval since we're only changing the period type
        activeEnergySyncStatus = .syncing
        syncActiveEnergy(ignoringInterval: true)
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
        
        activeEnergySyncStatus = .syncing
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
        
        activeEnergySyncStatus = .syncing
        syncActiveEnergy()
    }
    
    func correctActiveEnergyIntervalValueIfNeeded() {
        activeEnergyInterval.correctIfNeeded()
    }
    
    func syncActiveEnergy(ignoringInterval: Bool = false) {
        Task {
            await fetchActiveEnergyFromHealth(ignoringInterval: ignoringInterval)
            await MainActor.run {
                saveBiometrics()
            }
        }
    }
    
    func fetchActiveEnergyFromHealth(ignoringInterval: Bool = false) async {
        
        guard let (value, date, interval) = await HealthKitManager.shared.fetchEnergy(
            type: .activeEnergyBurned,
            using: UserManager.energyUnit,
            for: activeEnergyInterval
        ) else {
            await MainActor.run {
                withAnimation {
                    activeEnergySyncStatus = .lastSyncFailed
                    changeActiveEnergySource(to: .userEntered)
                }
            }
            return
        }

        await MainActor.run {
            withAnimation {
                if ignoringInterval {
                    activeEnergySyncStatus = .synced
                } else {
                    let gotRequestedInterval = interval.equalsWithoutTimestamp(activeEnergyInterval)
                    activeEnergySyncStatus = gotRequestedInterval ? .synced : .nextAvailableSynced
                }
                activeEnergy = value
                activeEnergyTextFieldString = "\(Int(value.rounded()))"
                activeEnergyInterval = interval
                activeEnergyInterval.timestamp = date?.timeIntervalSince1970
            }
        }
    }
    
    var activeEnergyFooterString: String? {
//        "This is an estimate of energy burnt over and above your Resting Energy use."
        "This is the additional energy you burn beyond your Resting Energy."
    }
}
