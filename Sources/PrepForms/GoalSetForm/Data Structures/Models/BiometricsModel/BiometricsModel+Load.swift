import Foundation
import PrepDataTypes

extension BiometricsModel {
    
    func load(_ biometrics: Biometrics) {
        
        if let timestamp = biometrics.timestamp {
            self.lastUpdatedAt = Date(timeIntervalSince1970: timestamp)
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

        //TODO: Is this needed anymore? We're doing it when the app comes to foreground, what's the point of doing it upon loading the model?
        syncHealSourcedBiometrics()
    }
    
    func syncHealSourcedBiometrics() {
//        if restingEnergySource == .health {
//            fetchRestingEnergyFromHealth()
//        }
//        if activeEnergySource == .health {
//            fetchActiveEnergyFromHealth()
//        }
//        if ageSource == .health {
//            fetchDOBFromHealth()
//        }
//        if heightSource == .health {
//            fetchHeightFromHealth()
//        }
//        if weightSource == .health {
//            fetchWeightFromHealth()
//        }
//        if lbmSource == .health {
//            fetchLBMFromHealth()
//        }
//        if sexSource == .health {
//            fetchSexFromHealth()
//        }
//
//        /// Save after fetches complete
//        //TODO: Do this properly as a large interval on energy would take longer
//        /// [ ] Have it as task that runs all fetches in parallel and saves once complete.
//        /// [ ] For this we would need to rewrite them as async functions
//        /// [ ] Do this also when coming back from background.
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
//            self.saveBiometrics()
//        }
    }
}
