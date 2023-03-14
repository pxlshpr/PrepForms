import Foundation
import PrepDataTypes
import PrepCoreDataStack

extension BiometricsModel {
    
    func load(_ biometrics: Biometrics) {
        
        if let timestamp = biometrics.timestamp {
            self.lastUpdatedAt = Date(timeIntervalSince1970: timestamp)
        }
        
        if let previousBiometrics = UserManager.previousBiometrics?.biometrics {
            self.updatedTypes = biometrics.updatedTypes(from: previousBiometrics)
        }
        
        self.restingEnergySource = biometrics.restingEnergy?.source
        self.restingEnergyFormula = biometrics.restingEnergy?.formula ?? .katchMcardle
        self.restingEnergy = biometrics.restingEnergy?.amount
        self.restingEnergyTextFieldString = biometrics.restingEnergy?.amount?.cleanAmount ?? ""
        self.restingEnergyInterval = biometrics.restingEnergy?.interval ?? .init(1, .week)

        self.activeEnergySource = biometrics.activeEnergy?.source
        self.activeEnergyActivityLevel = biometrics.activeEnergy?.activityLevel ?? .moderatelyActive
        self.activeEnergy = biometrics.activeEnergy?.amount
        self.activeEnergyTextFieldString = biometrics.activeEnergy?.amount?.cleanAmount ?? ""
        self.activeEnergyInterval = biometrics.activeEnergy?.interval ?? .init(1, .day)

        self.lbmSource = biometrics.leanBodyMass?.source
        self.lbmFormula = biometrics.leanBodyMass?.formula ?? .boer
        self.lbmDate = biometrics.leanBodyMass?.sampleDate

        if self.lbmSource == .fatPercentage {
            self.lbm = biometrics.fatPercentage
        } else {
            self.lbm = biometrics.leanBodyMass?.amount
        }
        self.lbmTextFieldString = self.lbm?.cleanAmount ?? ""

        self.weightSource = biometrics.weight?.source
        self.weight = biometrics.weight?.amount
        self.weightTextFieldString = biometrics.weight?.amount?.cleanAmount ?? ""
        self.weightDate = biometrics.weight?.sampleDate

        self.heightSource = biometrics.height?.source
        self.height = biometrics.height?.amount
        self.heightTextFieldString = biometrics.height?.amount?.cleanAmount ?? ""
        self.heightDate = biometrics.height?.sampleDate

        self.sexSource = biometrics.sex?.source
        if let sexValue = biometrics.sex?.value {
            self.sex = sexValue == .female ? .female : .male
        }

        self.ageSource = biometrics.age?.source
        self.dob = DateComponents(
            year: biometrics.age?.dobYear,
            month: biometrics.age?.dobMonth,
            day: biometrics.age?.dobDay
        )
        self.age = biometrics.age?.value
        if let age = biometrics.age?.value {
            self.ageTextFieldString = "\(age)"
        }

        if restingEnergySyncStatus == .nextAvailableSynced {
            restingEnergySyncStatus = .notSynced
        }
        if activeEnergySyncStatus == .nextAvailableSynced {
            activeEnergySyncStatus = .notSynced
        }
        if lbmSyncStatus == .nextAvailableSynced {
            lbmSyncStatus = .notSynced
        }
        if weightSyncStatus == .nextAvailableSynced {
            weightSyncStatus = .notSynced
        }
        if heightSyncStatus == .nextAvailableSynced {
            heightSyncStatus = .notSynced
        }
        if sexSyncStatus == .nextAvailableSynced {
            sexSyncStatus = .notSynced
        }
        if dobSyncStatus == .nextAvailableSynced {
            dobSyncStatus = .notSynced
        }
    }
}
