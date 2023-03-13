import Foundation
import PrepDataTypes

extension BiometricsModel {
    func load(_ profile: Biometrics) {
        self.restingEnergySource = profile.restingEnergy?.source
        self.restingEnergyFormula = profile.restingEnergy?.formula ?? .katchMcardle
        self.restingEnergy = profile.restingEnergy?.amount
        self.restingEnergyTextFieldString = profile.restingEnergy?.amount?.cleanAmount ?? ""
        self.restingEnergyInterval = profile.restingEnergy?.healthInterval ?? .init(1, .week)

        self.activeEnergySource = profile.activeEnergy?.source
        self.activeEnergyActivityLevel = profile.activeEnergy?.activityLevel ?? .moderatelyActive
        self.activeEnergy = profile.activeEnergy?.amount
        self.activeEnergyTextFieldString = profile.activeEnergy?.amount?.cleanAmount ?? ""
        self.activeEnergyPeriod = profile.activeEnergy?.period ?? .previousDay
        self.activeEnergyIntervalValue = profile.activeEnergy?.intervalValue ?? 1
        self.activeEnergyInterval = profile.activeEnergy?.interval ?? .day

        self.lbmSource = profile.leanBodyMass?.source
        self.lbmFormula = profile.leanBodyMass?.formula ?? .boer
        self.lbmDate = profile.leanBodyMass?.sampleDate

        if self.lbmSource == .fatPercentage {
            self.lbm = profile.fatPercentage
        } else {
            self.lbm = profile.leanBodyMass?.amount
        }
        self.lbmTextFieldString = self.lbm?.cleanAmount ?? ""

        self.weightSource = profile.weight?.source
        self.weight = profile.weight?.amount
        self.weightTextFieldString = profile.weight?.amount?.cleanAmount ?? ""
        self.weightDate = profile.weight?.sampleDate

        self.heightSource = profile.height?.source
        self.height = profile.height?.amount
        self.heightTextFieldString = profile.height?.amount?.cleanAmount ?? ""
        self.heightDate = profile.height?.sampleDate

        self.sexSource = profile.sex?.source
        if let sexValue = profile.sex?.value {
            self.sex = sexValue == .female ? .female : .male
        }

        self.ageSource = profile.age?.source
        self.dob = DateComponents(
            year: profile.age?.dobYear,
            month: profile.age?.dobMonth,
            day: profile.age?.dobDay
        )
        self.age = profile.age?.value
        if let age = profile.age?.value {
            self.ageTextFieldString = "\(age)"
        }

        
        if restingEnergySource == .health {
            fetchRestingEnergyFromHealth()
        }
        if activeEnergySource == .health {
            fetchActiveEnergyFromHealth()
        }
        if ageSource == .health {
            fetchDOBFromHealth()
        }
        if heightSource == .health {
            fetchHeightFromHealth()
        }
        if weightSource == .health {
            fetchWeightFromHealth()
        }
        if lbmSource == .health {
            fetchLBMFromHealth()
        }
        if sexSource == .health {
            fetchSexFromHealth()
        }
        
        /// Save after fetches complete
        //TODO: Do this properly as a large interval on energy would take longer
        /// [ ] Have it as task that runs all fetches in parallel and saves once complete.
        /// [ ] For this we would need to rewrite them as async functions
        /// [ ] Do this also when coming back from background.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.saveBiometrics()
        }
    }
}
