import Foundation
import PrepCoreDataStack
import PrepDataTypes

extension BiometricsModel {
    func saveBiometrics(afterDelay: Bool = false) {
        
        var biometrics = self.biometrics
        
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
