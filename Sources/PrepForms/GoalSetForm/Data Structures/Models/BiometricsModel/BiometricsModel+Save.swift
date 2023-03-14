import Foundation
import PrepCoreDataStack
import PrepDataTypes

extension BiometricsModel {
    func saveBiometrics(afterDelay: Bool = false) {
        
        let currentBiometrics = UserManager.biometrics
        var biometrics = currentBiometrics.mergingData(from: self.biometrics)
        
        let lastUpdatedAt = Date()
        self.lastUpdatedAt = lastUpdatedAt
        
        biometrics.timestamp = lastUpdatedAt.timeIntervalSince1970
        
        if afterDelay {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                UserManager.biometrics = biometrics
            }
        } else {
            UserManager.biometrics = biometrics
        }
    }
}

extension Biometrics {
    func mergingData(from other: Biometrics) -> Biometrics {
        Biometrics(
            restingEnergy: other.restingEnergy?.amount != nil ? other.restingEnergy : restingEnergy,
            activeEnergy: other.activeEnergy?.amount != nil ? other.activeEnergy : activeEnergy,
            fatPercentage: other.fatPercentage,
            leanBodyMass: other.leanBodyMass?.amount != nil ? other.leanBodyMass : leanBodyMass,
            weight: other.weight?.amount != nil ? other.weight : weight,
            height: other.height?.amount != nil ? other.height : height,
            sex: other.sex?.value != nil ? other.sex : sex,
            age: other.age?.value != nil ? other.age : age
        )
    }
}
