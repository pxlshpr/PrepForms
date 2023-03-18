import SwiftUI
import PrepDataTypes

extension BiometricValueForm {
    class Model: ObservableObject {
        
        let type: BiometricType
        let initialValue: BiometricValue?
        let handleNewValue: (BiometricValue?) -> ()
        
        @Published var refreshTextField: Bool = false
        
        @Published var unit: BiometricUnit? {
            didSet {
                unitChanged(from: oldValue)
            }
        }
        @Published var string: String = ""
        @Published var double: Double? = nil

        @Published var secondaryString: String = ""
        @Published var secondaryDouble: Double? = nil

        init(type: BiometricType, initialValue: BiometricValue?, handleNewValue: @escaping (BiometricValue?) -> Void) {
            self.type = type
            
            self.initialValue = initialValue
            self.handleNewValue = handleNewValue
            
            if let initialValue {
                double = initialValue.primaryDouble
                string = initialValue.primaryDouble?.clean ?? ""
                
                secondaryDouble = initialValue.secondaryDouble
                secondaryString = initialValue.secondaryDouble?.clean ?? ""
            }
            self.unit = initialValue?.unit ?? type.defaultUnit

        }
    }
}

extension BiometricValueForm.Model {
    var title: String {
        type.description
    }
    
    var keyboardType: UIKeyboardType {
        switch type {
        case .age:
            return .numberPad
        default:
            return usesSecondaryUnit ? .numberPad : .decimalPad
        }
    }
    
    func unitChanged(from oldUnit: BiometricUnit?) {
        guard let oldUnit, let unit, let double else { return }
        
        /// If we've moved to a single-component to a two-component unit
        if !oldUnit.hasTwoComponents, unit.hasTwoComponents, let maxSecondaryValue {
            let primary = double.whole
            self.double = primary.whole
            self.string = primary.clean
            
            let secondary = (double.fraction * maxSecondaryValue)
            self.secondaryDouble = secondary
            self.secondaryString = secondary.clean
        }
    }
    
    var secondaryUnitString: String? {
        switch unit {
        case .bodyMass(let bodyMassUnit):
            return bodyMassUnit == .st ? "lb" : nil
        case .height(let heightUnit):
            return heightUnit == .ft ? "in" : nil
        default:
            return nil
        }
    }
    
    var usesSecondaryUnit: Bool {
        switch unit {
        case .bodyMass(let bodyMassUnit):
            return bodyMassUnit == .st
        case .height(let heightUnit):
            return heightUnit == .ft
        default:
            return false
        }
    }
    
    var shouldDisableDone: Bool {
        if initialValue == value {
            return true
        }
        if string.isEmpty {
            return true
        }
        return false
    }
    
    var energyUnit: EnergyUnit? {
        unit?.energyUnit
    }
    
    var bodyMassUnit: BodyMassUnit? {
        unit?.bodyMassUnit
    }
    
    var heightUnit: HeightUnit? {
        unit?.heightUnit
    }
    
    /// Totals value of double when we have a secondary unit (of inches for feet, or pounds for stones)
    var totalDouble: Double? {
        guard let double else { return nil }
        switch type {
        case .weight, .leanBodyMass:
            guard let bodyMassUnit else { return nil }
            if bodyMassUnit == .st, let secondaryDouble {
                return double + ((secondaryDouble / PoundsPerStone))
            } else {
                return double
            }
        case .height:
            guard let heightUnit else { return nil }
            if heightUnit == .ft, let secondaryDouble {
                return double + ((secondaryDouble / InchesPerFoot))
            } else {
                return double
            }
            
        default:
            return double
        }
    }
    
    var value: BiometricValue? {
        guard let totalDouble else { return nil }
        switch type {
        case .activeEnergy:
            guard let energyUnit else { return nil }
            return .activeEnergy(totalDouble, energyUnit)
        case .restingEnergy:
            guard let energyUnit else { return nil }
            return .restingEnergy(totalDouble, energyUnit)
        case .weight:
            guard let bodyMassUnit else { return nil }
            return .weight(totalDouble, bodyMassUnit)
        case .leanBodyMass:
            guard let bodyMassUnit else { return nil }
            return .leanBodyMass(totalDouble, bodyMassUnit)
        case .height:
            guard let heightUnit else { return nil }
            return .height(totalDouble, heightUnit)
        case .fatPercentage:
            return .fatPercentage(totalDouble)
            
        //TODO: Handle these
        case .age:
            return .age(Int(totalDouble))
        case .sex:
            guard let biometricSex = BiometricSex(rawValue: Int16(totalDouble)) else { return nil }
            return .sex(biometricSex)
        }
    }
    
    var textFieldString: String {
        //TODO: Force integer for age
        get { string }
        set {
            guard !newValue.isEmpty else {
                double = nil
                string = newValue
                return
            }
            guard let double = Double(newValue) else {
                return
            }
            self.double = double
            self.string = newValue
        }
    }
    
    var secondaryTextFieldString: String {
        get { secondaryString }
        set {
            guard !newValue.isEmpty else {
                secondaryDouble = nil
                secondaryString = newValue
                return
            }
            guard let double = Double(newValue) else {
                return
            }
            if let maxSecondaryValue, double >= maxSecondaryValue {
                self.secondaryDouble = maxSecondaryValue
                self.secondaryString = maxSecondaryValue.cleanAmount
            } else {
                self.secondaryDouble = double
                self.secondaryString = newValue
            }
        }
    }
    
    var maxSecondaryValue: Double? {
        switch unit {
        case .bodyMass(let bodyMassUnit):
            return bodyMassUnit == .st ? PoundsPerStone : nil
        case .height(let heightUnit):
            return heightUnit == .ft ? InchesPerFoot : nil
        default:
            return nil
        }
    }
}
