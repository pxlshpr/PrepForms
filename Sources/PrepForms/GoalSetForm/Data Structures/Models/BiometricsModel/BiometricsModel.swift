import SwiftUI
import PrepDataTypes
import SwiftHaptics
import HealthKit
import PrepCoreDataStack

class BiometricsModel: ObservableObject {
    @Published var restingEnergySource: RestingEnergySource? = nil
    @Published var restingEnergyEquation: RestingEnergyEquation = .katchMcardle
    @Published var restingEnergy: Double? = nil
    @Published var restingEnergyTextFieldString: String = ""
    @Published var restingEnergyInterval: HealthInterval = .init(1, .week)
    
    @Published var activeEnergySource: ActiveEnergySource? = nil
    @Published var activeEnergyActivityLevel: ActivityLevel = .moderatelyActive
    @Published var activeEnergy: Double? = nil
    @Published var activeEnergyTextFieldString: String = ""
    @Published var activeEnergyInterval: HealthInterval = .init(1, .day)

    @Published var lbmSource: LeanBodyMassSource? = nil
    @Published var lbmEquation: LeanBodyMassEquation = .boer
    @Published var lbm: Double? = nil
    @Published var lbmTextFieldString: String = ""
    @Published var lbmDate: Date? = nil
    
    @Published var weightSource: MeasurementSource? = nil
    @Published var weight: Double? = nil
    @Published var weightTextFieldString: String = ""
    @Published var weightDate: Date? = nil
    
    @Published var heightSource: MeasurementSource? = nil
    @Published var height: Double? = nil
    @Published var heightTextFieldString: String = ""
    @Published var heightDate: Date? = nil
    
    @Published var sexSource: MeasurementSource? = nil
    @Published var sex: HKBiologicalSex? = nil
    
    @Published var ageSource: MeasurementSource? = nil
    @Published var dob: DateComponents? = nil
    @Published var age: Int? = nil
    @Published var ageTextFieldString: String = ""

    @Published var sexSyncStatus: BiometricSyncStatus  = .notSynced
    @Published var dobSyncStatus: BiometricSyncStatus = .notSynced
    @Published var heightSyncStatus: BiometricSyncStatus = .notSynced
    @Published var weightSyncStatus: BiometricSyncStatus = .notSynced
    @Published var activeEnergySyncStatus: BiometricSyncStatus = .notSynced
    @Published var restingEnergySyncStatus: BiometricSyncStatus = .notSynced
    @Published var lbmSyncStatus: BiometricSyncStatus = .notSynced
    
    @Published var lastUpdatedAt: Date? = nil
    
    @Published var updatedTypes: [BiometricType]

    init() {
        self.updatedTypes = UserManager.updatedBiometricTypes
        self.load(UserManager.biometrics)
    }
}

extension BiometricsModel {
    
    var biometrics: Biometrics {
        
        var restingEnergyEquation: RestingEnergyEquation? { restingEnergySource == .equation ? self.restingEnergyEquation : nil }
        var restingEnergyInterval: HealthInterval? { restingEnergySource == .health ? self.restingEnergyInterval : nil }
        
        var activeEnergyActivityLevel: ActivityLevel? { activeEnergySource == .activityLevel ? self.activeEnergyActivityLevel : nil }
        var activeEnergyInterval: HealthInterval? { activeEnergySource == .health ? self.activeEnergyInterval : nil }
        
        var lbmEquation: LeanBodyMassEquation? { lbmSource == .equation ? self.lbmEquation : nil }
        var lbmDate: Date? { lbmSource == .health ? self.lbmDate : nil }
        
        var weightDate: Date? { weightSource == .health ? self.weightDate : nil }
        var heightDate: Date? { heightSource == .health ? self.heightDate : nil }
                
        var restingEnergyData: Biometrics.RestingEnergy {
            .init(
                amount: restingEnergyValue,
                unit: UserManager.energyUnit,
                source: restingEnergySource,
                equation: restingEnergyEquation,
                interval: restingEnergyInterval
            )
        }

        var activeEnergyData: Biometrics.ActiveEnergy {
            .init(
                amount: activeEnergyValue,
                unit: UserManager.energyUnit,
                source: activeEnergySource,
                activityLevel: activeEnergyActivityLevel,
                interval: activeEnergyInterval
            )
        }
        
        var leanBodyMassData: Biometrics.LeanBodyMass {
            .init(
                amount: lbmValue, /// We don't use `lbm` here because it may be the actual percentage
                unit: UserManager.bodyMassUnit,
                source: lbmSource,
                equation: lbmEquation,
                date: lbmDate
            )
        }
        
        var weightData: Biometrics.Weight {
            .init(
                amount: weight,
                unit: UserManager.bodyMassUnit,
                source: weightSource,
                date: weightDate
            )
        }

        var heightData: Biometrics.Height {
            .init(
                amount: height,
                unit: UserManager.heightUnit,
                source: heightSource,
                date: heightDate
            )
        }
        
        var sexData: Biometrics.Sex {
            let biometricSex: BiometricSex?
            if let sexIsFemale {
                biometricSex = sexIsFemale ? .female : .male
            } else {
                biometricSex = nil
            }
            return .init(
                value: biometricSex,
                source: sexSource
            )
        }
        
        var ageData: Biometrics.Age {
            .init(
                value: age,
                dobDay: dob?.day,
                dobMonth: dob?.month,
                dobYear: dob?.year,
                source: ageSource
            )
        }

        return Biometrics(
            restingEnergy: restingEnergyData,
            activeEnergy: activeEnergyData,
            fatPercentage: fatPercentage,
            leanBodyMass: leanBodyMassData,
            weight: weightData,
            height: heightData,
            sex: sexData,
            age: ageData
        )
    }
}

extension BiometricsModel {
    
    func shouldShowUpdatedBadge(for type: BiometricType) -> Bool {
        updatedTypes.contains(type)
    }
    
    var isSyncingRestingEnergy: Bool {
        restingEnergySource == .health
        || restingEnergyEquationVariablesAreSynced
    }
    
    var isSyncingLeanBodyMass: Bool {
        lbmSource == .health
        || leanBodyMassParametersAreSynced
    }
    
    func isSyncing(_ type: BiometricType) -> Bool {
        switch type {
        case .restingEnergy:
            return isSyncingRestingEnergy
        case .activeEnergy:
            return activeEnergySource == .health
        case .sex:
            return sexSource == .health
        case .age:
            return ageSource == .health
        case .weight:
            return weightSource == .health
        case .leanBodyMass:
            return isSyncingLeanBodyMass
        case .height:
            return heightSource == .health
        default:
            return false
        }
    }
    
    var isSyncingAtLeastOneType: Bool {
        for type in BiometricType.allCases {
            if isSyncing(type) {
                return true
            }
        }
        return false
    }
    
    var typesBeingSynced: [BiometricType] {
        BiometricType.allCases.filter { isSyncing($0) }
    }
    
    var typesNotSynced: [BiometricType] {
        BiometricType.allCases.filter { !isSyncing($0) }
    }
}

//MARK: Helpers

extension BiometricsModel {
    
    var tdeeDescriptionText: Text {
        let energy = UserManager.energyUnit == .kcal ? "calories" : "kiljoules"
        return Text("This is an estimate of how many \(energy) you would have to consume to *maintain* your current weight.")
    }
    
    var shouldShowSyncAllButton: Bool {
        typesNotSynced.count > 1
    }
}
