import Foundation
import PrepCoreDataStack
import PrepDataTypes

extension BiometricsModel {
    func saveBiometrics(afterDelay: Bool = false) {
        let biometrics = self.biometrics
        if afterDelay {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                UserManager.biometrics = biometrics
            }
        } else {
            UserManager.biometrics = biometrics
        }
    }
}
