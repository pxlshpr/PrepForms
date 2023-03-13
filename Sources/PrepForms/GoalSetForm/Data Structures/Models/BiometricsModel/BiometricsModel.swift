import SwiftUI
import PrepDataTypes
import SwiftHaptics
import HealthKit
import PrepCoreDataStack

class BiometricsModel: ObservableObject {
    var userEnergyUnit: EnergyUnit
    var userBodyMassUnit: BodyMassUnit
    var userHeightUnit: HeightUnit
    
    @Published var path: [TDEEFormRoute] = []
    @Published var isEditing = false
    
    @Published var presentationDetent: PresentationDetent
    @Published var detents: Set<PresentationDetent>
    
    @Published var hasAppeared = false
    
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
    @Published var previousBiometrics: Biometrics?

    let existingProfile: Biometrics?
    
    init(
        existingProfile: Biometrics?,
        userUnits: UserOptions.Units
    ) {
        self.userEnergyUnit = userUnits.energy
        self.userBodyMassUnit = userUnits.bodyMass
        self.userHeightUnit = userUnits.height
        
        self.existingProfile = existingProfile
        
        if let existingProfile, existingProfile.hasTDEE {
            if existingProfile.hasDynamicTDEE {
                detents = [.medium, .large]
                presentationDetent = .medium
            } else {
                detents = [.height(400), .large]
                presentationDetent = .height(400)
            }
        } else {
            detents = [.height(270), .large]
            presentationDetent = .height(270)
        }

        self.previousBiometrics = UserManager.previousBiometrics?.biometrics

        if let existingProfile {
            self.load(existingProfile)
        }
    }
}

//MARK: Helpers

extension BiometricsModel {
    
    var tdeeDescriptionText: Text {
        let energy = userEnergyUnit == .kcal ? "calories" : "kiljoules"
        return Text("This is an estimate of how many \(energy) you would have to consume to *maintain* your current weight.")
    }
    
    var shouldShowSaveButton: Bool {
        guard isEditing, biometrics.hasTDEE else { return false }
        if let existingProfile {
            /// We're only checking the parameters as the `updatedAt` flag, `syncStatus` might differ.
            return existingProfile != biometrics
        }
        return true
    }
    
    var shouldShowEditButton: Bool {
        guard !isEditing else { return false }
        return existingProfile != nil
    }
    
    var shouldShowInitialSetupButton: Bool {
        !shouldShowSummary
        //        existingProfile == nil && !isEditing
    }
    
    var shouldShowSummary: Bool {
        biometrics.hasTDEE
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
        guard let previousBiometrics,
              isSyncing(type)
        else { return false }
        
        switch type {
        case .restingEnergy:
            return biometrics.restingEnergy != previousBiometrics.restingEnergy
        case .activeEnergy:
            return biometrics.activeEnergy != previousBiometrics.activeEnergy
        case .sex:
            return biometrics.sex != previousBiometrics.sex
        case .age:
            return biometrics.age != previousBiometrics.age
        case .weight:
            return biometrics.weight != previousBiometrics.weight
        case .leanBodyMass:
            return biometrics.leanBodyMass != previousBiometrics.leanBodyMass
        case .height:
            return biometrics.height != previousBiometrics.height
        default:
            return false
        }
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
