import Foundation
import PrepCoreDataStack
import PrepDataTypes

extension BiometricsModel {
    func saveBiometrics() {
        let biometrics = self.biometrics
        UserManager.biometrics = biometrics
    }
}
