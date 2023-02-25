import Foundation
import PrepDataTypes

extension TDEEForm.ViewModel {
    func load(_ profile: BodyProfile) {
        
        self.restingEnergySource = profile.restingEnergySource
        self.restingEnergyFormula = profile.restingEnergyFormula ?? .katchMcardle
        self.restingEnergy = profile.restingEnergy
        self.restingEnergyTextFieldString = profile.restingEnergy?.cleanAmount ?? ""
        self.restingEnergyPeriod = profile.restingEnergyPeriod ?? .average
        self.restingEnergyIntervalValue = profile.restingEnergyIntervalValue ?? 1
        self.restingEnergyInterval = profile.restingEnergyInterval ?? .week

        self.activeEnergySource = profile.activeEnergySource
        self.activeEnergyActivityLevel = profile.activeEnergyActivityLevel ?? .moderatelyActive
        self.activeEnergy = profile.activeEnergy
        self.activeEnergyTextFieldString = profile.activeEnergy?.cleanAmount ?? ""
        self.activeEnergyPeriod = profile.activeEnergyPeriod ?? .previousDay
        self.activeEnergyIntervalValue = profile.activeEnergyIntervalValue ?? 1
        self.activeEnergyInterval = profile.activeEnergyInterval ?? .day

        self.lbmSource = profile.lbmSource
        self.lbmFormula = profile.lbmFormula ?? .boer
        self.lbmDate = profile.lbmDate
        
        if self.lbmSource == .fatPercentage {
            self.lbm = profile.fatPercentage
        } else {
            self.lbm = profile.lbm
        }
        self.lbmTextFieldString = self.lbm?.cleanAmount ?? ""
        
        self.weightSource = profile.weightSource
        self.weight = profile.weight
        self.weightTextFieldString = profile.weight?.cleanAmount ?? ""
        self.weightDate = profile.weightDate

        self.heightSource = profile.heightSource
        self.height = profile.height
        self.heightTextFieldString = profile.height?.cleanAmount ?? ""
        self.heightDate = profile.heightDate

        self.sexSource = profile.sexSource
        if let sexIsFemale = profile.sexIsFemale {
            self.sex = sexIsFemale ? .female : .male
        }

        self.ageSource = profile.ageSource
        self.dob = DateComponents(
            year: profile.dobYear,
            month: profile.dobMonth,
            day: profile.dobDay
        )
        self.age = profile.age
        if let age = profile.age {
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
