import SwiftUI
import PrepDataTypes
import SwiftHaptics
import HealthKit
import PrepCoreDataStack

class BiometricsModel: ObservableObject {
    var userEnergyUnit: EnergyUnit
    var userBodyMassUnit: BodyMassUnit
    var userHeightUnit: HeightUnit
    
    @Published var restingEnergySource: RestingEnergySource? = nil
    @Published var restingEnergyFormula: RestingEnergyFormula = .katchMcardle
    @Published var restingEnergy: Double? = nil
    @Published var restingEnergyTextFieldString: String = ""
    @Published var restingEnergyInterval: HealthInterval = .init(1, .week)
    
    @Published var activeEnergySource: ActiveEnergySource? = nil
    @Published var activeEnergyActivityLevel: ActivityLevel = .moderatelyActive
    @Published var activeEnergy: Double? = nil
    @Published var activeEnergyTextFieldString: String = ""
    
    @Published var activeEnergyInterval: HealthInterval = .init(1, .day)

    @Published var lbmSource: LeanBodyMassSource? = nil
    @Published var lbmFormula: LeanBodyMassFormula = .boer
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
        let units = UserManager.units
        self.userEnergyUnit = units.energy
        self.userBodyMassUnit = units.bodyMass
        self.userHeightUnit = units.height
        
        let biometrics = UserManager.biometrics
        
        if let previousBiometrics = UserManager.previousBiometrics?.biometrics {
            self.updatedTypes = biometrics.updatedTypes(from: previousBiometrics)
        } else {
            self.updatedTypes = []
        }

        self.load(biometrics)
    }
}

//MARK: Helpers

extension BiometricsModel {
    
    var tdeeDescriptionText: Text {
        let energy = userEnergyUnit == .kcal ? "calories" : "kiljoules"
        return Text("This is an estimate of how many \(energy) you would have to consume to *maintain* your current weight.")
    }
    
    var isDynamic: Bool {
        restingEnergyIsDynamic || activeEnergyIsDynamic
    }
}

extension BiometricsModel {
    
    var biometrics: Biometrics {
        
        var restingEnergyFormula: RestingEnergyFormula? { restingEnergySource == .formula ? self.restingEnergyFormula : nil }
        var restingEnergyInterval: HealthInterval? { restingEnergySource == .health ? self.restingEnergyInterval : nil }
        
        var activeEnergyActivityLevel: ActivityLevel? { activeEnergySource == .activityLevel ? self.activeEnergyActivityLevel : nil }
        var activeEnergyInterval: HealthInterval? { activeEnergySource == .health ? self.activeEnergyInterval : nil }
        
        var lbmFormula: LeanBodyMassFormula? { lbmSource == .formula ? self.lbmFormula : nil }
        var lbmDate: Date? { lbmSource == .health ? self.lbmDate : nil }
        
        var weightDate: Date? { weightSource == .health ? self.weightDate : nil }
        var heightDate: Date? { heightSource == .health ? self.heightDate : nil }
                
        var restingEnergyData: Biometrics.RestingEnergy {
            .init(
                amount: restingEnergyValue,
                unit: userEnergyUnit, //TODO: Change this
                source: restingEnergySource,
                formula: restingEnergyFormula,
                interval: restingEnergyInterval
            )
        }

        var activeEnergyData: Biometrics.ActiveEnergy {
            .init(
                amount: activeEnergyValue,
                unit: userEnergyUnit, //TODO: Change this
                source: activeEnergySource,
                activityLevel: activeEnergyActivityLevel,
                interval: activeEnergyInterval
            )
        }
        
        var leanBodyMassData: Biometrics.LeanBodyMass {
            .init(
                amount: lbmValue, /// We don't use `lbm` here because it may be the actual percentage
                unit: userBodyMassUnit, //TODO: Change this
                source: lbmSource,
                formula: lbmFormula,
                date: lbmDate
            )
        }
        
        var weightData: Biometrics.Weight {
            .init(
                amount: weight,
                unit: userBodyMassUnit, //TODO: Change this
                source: weightSource,
                date: weightDate
            )
        }

        var heightData: Biometrics.Height {
            .init(
                amount: height,
                unit: userHeightUnit, //TODO: Change this
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
    
    func isSyncing(_ type: BiometricType) -> Bool {
        switch type {
        case .restingEnergy:
            return restingEnergySource == .health
        case .activeEnergy:
            return activeEnergySource == .health
        case .sex:
            return sexSource == .health
        case .age:
            return ageSource == .health
        case .weight:
            return weightSource == .health
        case .leanBodyMass:
            return lbmSource == .health
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
}
