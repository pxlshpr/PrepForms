import SwiftUI
import SwiftUISugar
import SwiftHaptics
import PrepDataTypes
import ActivityIndicatorView
import PrepCoreDataStack

extension TDEEForm {

    var activeEnergySection: some View {
        ActiveEnergySection()
            .environmentObject(model)
    }

}
