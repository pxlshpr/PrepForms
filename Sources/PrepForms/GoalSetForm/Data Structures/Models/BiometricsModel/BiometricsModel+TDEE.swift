import Foundation
import SwiftUI
import PrepDataTypes
import SwiftHaptics

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
        case .healthApp:
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
            case .healthApp:
                return true
            case .fatPercentage:
                return weightSource == .healthApp
            case .formula:
                return weightSource == .healthApp
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
        Array(restingEnergyInterval.minValue...restingEnergyInterval.maxValue)
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
        case .healthApp, .userEntered:
            return restingEnergy != nil
        default:
            return false
        }
    }
    
    var restingEnergyPrefix: String? {
        switch restingEnergySource {
        case .healthApp:
            return restingEnergyPeriod.energyPrefix
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
        case .healthApp:
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
    
    var restingEnergyPeriodBinding: Binding<HealthPeriodOption> {
        Binding<HealthPeriodOption>(
            get: { self.restingEnergyPeriod },
            set: { newPeriod in
                Haptics.feedback(style: .soft)
                self.changeRestingEnergyPeriod(to: newPeriod)
            }
        )
    }
    
    func changeRestingEnergyPeriod(to newPeriod: HealthPeriodOption) {
        withAnimation {
            self.restingEnergyPeriod = newPeriod
            if newPeriod == .previousDay {
                restingEnergyIntervalValue = 1
                restingEnergyInterval = .day
            } else {
                correctRestingEnergyIntervalValueIfNeeded()
            }
        }
        fetchRestingEnergyFromHealth()
    }
    
    var restingEnergyIntervalValueBinding: Binding<Int> {
        Binding<Int>(
            get: { self.restingEnergyIntervalValue },
            set: { newValue in
                Haptics.feedback(style: .soft)
                self.changeRestingEnergyIntervalValue(to: newValue)
            }
        )
    }
    
    func changeRestingEnergyIntervalValue(to newValue: Int) {
        guard newValue >= restingEnergyInterval.minValue,
              newValue <= restingEnergyInterval.maxValue else {
            return
        }
        withAnimation {
            restingEnergyIntervalValue = newValue
        }
        fetchRestingEnergyFromHealth()
    }
    
    var restingEnergyIntervalBinding: Binding<HealthAppInterval> {
        Binding<HealthAppInterval>(
            get: { self.restingEnergyInterval },
            set: { newInterval in
                Haptics.feedback(style: .soft)
                self.changeRestingEnergyInterval(to: newInterval)
            }
        )
    }
    
    func changeRestingEnergyInterval(to newInterval: HealthAppInterval) {
        withAnimation {
            restingEnergyInterval = newInterval
            correctRestingEnergyIntervalValueIfNeeded()
        }
        
        fetchRestingEnergyFromHealth()
    }
    
    func correctRestingEnergyIntervalValueIfNeeded() {
        if restingEnergyIntervalValue < restingEnergyInterval.minValue {
            restingEnergyIntervalValue = restingEnergyInterval.minValue
        }
        if restingEnergyIntervalValue > restingEnergyInterval.maxValue {
            restingEnergyIntervalValue = restingEnergyInterval.maxValue
        }
    }
    
    var restingEnergyFooterString: String? {
        let prefix = "This is an estimate of the energy your body uses each day while minimally active."
        if restingEnergySource == .healthApp {
            return prefix + " This will sync with your Health data and update daily."
        }
        return prefix
    }
    
    func fetchRestingEnergyFromHealth() {
        withAnimation {
            restingEnergyFetchStatus = .fetching
        }
        
        Task {
            do {
                let average = try await HealthKitManager.shared.averageSumOfRestingEnergy(
                    using: userEnergyUnit,
                    overPast: restingEnergyIntervalValue,
                    interval: restingEnergyInterval
                )
                await MainActor.run {
                    withAnimation {
                        cprint("🔥 setting average: \(average)")
                        restingEnergy = average
                        restingEnergyTextFieldString = "\(Int(average.rounded()))"
                        restingEnergyFetchStatus = .fetched
                    }
                }
            } catch HealthKitManagerError.noData {
                await MainActor.run {
                    withAnimation { restingEnergyFetchStatus = .noData }
                }
            } catch HealthKitManagerError.noDataOrNotAuthorized {
                await MainActor.run {
                    withAnimation { restingEnergyFetchStatus = .noDataOrNotAuthorized }
                }
            } catch {
                
            }
            /// [ ] Make sure we persist this to the backend once the user saves it
        }
    }
}

//MARK: - Active Energy

extension BiometricsModel {
    
    var activeEnergyIsDynamic: Bool {
        switch activeEnergySource {
        case .healthApp:
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
        return .init(amount: activeEnergyValue, unit: .energy(userEnergyUnit))
    }
    
    var hasActiveEnergy: Bool {
        switch activeEnergySource {
        case .activityLevel:
            return calculatedActiveEnergy != nil
        case .healthApp, .userEntered:
            return activeEnergy != nil
        default:
            return false
        }
    }
    
    var activeEnergyPrefix: String? {
        switch activeEnergySource {
        case .healthApp:
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
        case .healthApp:
            fetchActiveEnergyFromHealth()
        default:
            break
        }
    }
    
    var activeEnergyPeriodBinding: Binding<HealthPeriodOption> {
        Binding<HealthPeriodOption>(
            get: { self.activeEnergyPeriod },
            set: { newPeriod in
                Haptics.feedback(style: .soft)
                self.changeActiveEnergyPeriod(to: newPeriod)
            }
        )
    }
    
    func changeActiveEnergyPeriod(to newPeriod: HealthPeriodOption) {
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
    
    var activeEnergyIntervalBinding: Binding<HealthAppInterval> {
        Binding<HealthAppInterval>(
            get: { self.activeEnergyInterval },
            set: { newInterval in
                Haptics.feedback(style: .soft)
                self.changeActiveEnergyInterval(to: newInterval)
            }
        )
    }
    
    func changeActiveEnergyInterval(to newInterval: HealthAppInterval) {
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
            activeEnergyFetchStatus = .fetching
        }
        
        Task {
            do {
                let average = try await HealthKitManager.shared.averageSumOfActiveEnergy(
                    using: userEnergyUnit,
                    overPast: activeEnergyIntervalValue,
                    interval: activeEnergyInterval
                )
                await MainActor.run {
                    withAnimation {
                        cprint("🔥 setting average: \(average)")
                        activeEnergy = average
                        activeEnergyTextFieldString = "\(Int(average.rounded()))"
                        activeEnergyFetchStatus = .fetched
                    }
                }
            } catch HealthKitManagerError.noData {
                await MainActor.run {
                    withAnimation { activeEnergyFetchStatus = .noData }
                }
            } catch HealthKitManagerError.noDataOrNotAuthorized {
                await MainActor.run {
                    withAnimation { activeEnergyFetchStatus = .noDataOrNotAuthorized }
                }
            } catch {
                
            }
            /// [ ] Make sure we persist this to the backend once the user saves it
        }
    }
    
    var activeEnergyFooterString: String? {
        let prefix = "This is an estimate of energy burnt over and above your Resting Energy use."
        if activeEnergySource == .healthApp {
            return prefix + " This will sync with your Health data and update daily."
        }
        return prefix
    }
}
