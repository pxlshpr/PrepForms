import SwiftUI
import PrepDataTypes

extension TDEEForm {
    
    func blankViewAppeared() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            withAnimation {
                model.hasAppeared = true
            }
        }
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
