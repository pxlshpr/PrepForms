import Foundation
import PrepDataTypes

extension BiometricsModel {
    func load(_ profile: Biometrics) {
        
        self.restingEnergySource = profile.restingEnergy?.source
        self.restingEnergyFormula = profile.restingEnergy?.formula ?? .katchMcardle
        self.restingEnergy = profile.restingEnergy?.amount
        self.restingEnergyTextFieldString = profile.restingEnergy?.amount?.cleanAmount ?? ""
        self.restingEnergyPeriod = profile.restingEnergy?.period ?? .average
        self.restingEnergyIntervalValue = profile.restingEnergy?.intervalValue ?? 1
        self.restingEnergyInterval = profile.restingEnergy?.interval ?? .week

        self.activeEnergySource = profile.activeEnergy?.source
        self.activeEnergyActivityLevel = profile.activeEnergy?.activityLevel ?? .moderatelyActive
        self.activeEnergy = profile.activeEnergy?.amount
        self.activeEnergyTextFieldString = profile.activeEnergy?.amount?.cleanAmount ?? ""
        self.activeEnergyPeriod = profile.activeEnergy?.period ?? .previousDay
        self.activeEnergyIntervalValue = profile.activeEnergy?.intervalValue ?? 1
        self.activeEnergyInterval = profile.activeEnergy?.interval ?? .day

        self.lbmSource = profile.leanBodyMass?.source
        self.lbmFormula = profile.leanBodyMass?.formula ?? .boer
        self.lbmDate = profile.leanBodyMass?.date
        
        if self.lbmSource == .fatPercentage {
            self.lbm = profile.fatPercentage
        } else {
            self.lbm = profile.leanBodyMass?.amount
        }
        self.lbmTextFieldString = self.lbm?.cleanAmount ?? ""
        
        self.weightSource = profile.weight?.source
        self.weight = profile.weight?.amount
        self.weightTextFieldString = profile.weight?.amount?.cleanAmount ?? ""
        self.weightDate = profile.weight?.date

        self.heightSource = profile.height?.source
        self.height = profile.height?.amount
        self.heightTextFieldString = profile.height?.amount?.cleanAmount ?? ""
        self.heightDate = profile.height?.date

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

        //TODO: Revisit this
        self.restingEnergyFetchStatus = .notFetched
        self.activeEnergyFetchStatus = .notFetched
        self.lbmFetchStatus = .notFetched
        self.weightFetchStatus = .notFetched
        self.heightFetchStatus = .notFetched
        self.sexFetchStatus = .notFetched
        self.dobFetchStatus = .notFetched
    }
}
