import Foundation
import PrepCoreDataStack
import PrepDataTypes

extension BiometricsModel {
    func save() {
        let biometrics = self.biometrics
        UserManager.biometrics = biometrics
//        UserManager.biometrics = Biometrics()
    }
}
