import SwiftUI
import PrepDataTypes

extension TDEEForm {
    
    func blankViewAppeared() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            withAnimation {
                viewModel.hasAppeared = true
            }
        }
    }
  
    func didEnterForeground(notification: Notification) {
        /// Do this in case the user came back from changing permissions
        viewModel.updateHealthAppDataIfNeeded()
    }
    
    func restingEnergySourceChanged(to newSource: RestingEnergySource?) {
        switch newSource {
        case .userEntered:
            restingEnergyTextFieldIsFocused = true
        default:
            break
        }
    }
    
    func activeEnergySourceChanged(to newSource: ActiveEnergySource?) {
        switch newSource {
        case .userEntered:
            activeEnergyTextFieldIsFocused = true
        default:
            break
        }
    }

}
