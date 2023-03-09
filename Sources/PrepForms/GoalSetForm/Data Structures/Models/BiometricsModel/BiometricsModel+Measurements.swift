import SwiftUI
import PrepDataTypes
import HealthKit
import SwiftHaptics

extension BiometricsModel {
    
    var hasMeasurements: Bool {
        let hasCore = (sex == .male || sex == .female)
        && age != nil && weight != nil
        
        return restingEnergyFormula.requiresHeight ? hasCore && height != nil : hasCore
    }
    
    var measurementsAreSynced: Bool {
        hasMeasurements
        && (weightSource == .healthApp || heightSource == .healthApp)
    }
    
    var shouldShowSyncAllForMeasurementsForm: Bool {
        var countNotSynced = 0
        if sexSource != .healthApp { countNotSynced += 1 }
        if weightSource != .healthApp { countNotSynced += 1 }
        if ageSource != .healthApp { countNotSynced += 1 }
        if restingEnergyFormula.requiresHeight {
            if heightSource != .healthApp { countNotSynced += 1 }
        }
        return countNotSynced > 1
    }
}

//MARK: - Biological Sex
extension BiometricsModel {
    var sexSourceBinding: Binding<MeasurementSource> {
        Binding<MeasurementSource>(
            get: { self.sexSource ?? .userEntered },
            set: { newSource in
                Haptics.feedback(style: .soft)
                self.changeSexSource(to: newSource)
            }
        )
    }
    
    var sexPickerBinding: Binding<HKBiologicalSex> {
        Binding<HKBiologicalSex>(
            get: { self.sex ?? .notSet },
            set: { newSex in
                Haptics.feedback(style: .soft)
                withAnimation {
                    self.sex = newSex
                }
            }
        )
    }
    
    func changeSexSource(to newSource: MeasurementSource) {
        withAnimation {
            sexSource = newSource
        }
        if newSource == .healthApp {
            fetchSexFromHealth()
        }
    }
    
    func fetchSexFromHealth() {
        withAnimation {
            sexFetchStatus = .fetching
        }
        
        Task {
            guard let sex = await HealthKitManager.shared.currentBiologicalSex() else {
                return
            }
            await MainActor.run {
                withAnimation {
                    self.sexFetchStatus = .fetched
                    self.sex = sex
                }
            }
        }
    }
    
    var sexFormatted: String? {
        switch sex {
        case .male:
            return "male"
        case .female:
            return "female"
        default:
            return nil
        }
    }
    var hasSex: Bool {
        sex != nil
    }
    
    var hasDynamicSex: Bool {
        sexSource == .healthApp
    }
    
    var sexIsFemale: Bool? {
        switch sex {
        case .female:
            return true
        case .male:
            return false
        default:
            return nil
        }
    }
}

//MARK: - Age

extension BiometricsModel {
    var ageSourceBinding: Binding<MeasurementSource> {
        Binding<MeasurementSource>(
            get: { self.ageSource ?? .userEntered },
            set: { newSource in
                Haptics.feedback(style: .soft)
                self.changeAgeSource(to: newSource)
            }
        )
    }
    
    func changeAgeSource(to newSource: MeasurementSource) {
        withAnimation {
            ageSource = newSource
        }
        if newSource == .healthApp {
            fetchDOBFromHealth()
        }
    }
    
    var ageTextFieldStringBinding: Binding<String> {
        Binding<String>(
            get: { self.ageTextFieldString },
            set: { newValue in
                guard !newValue.isEmpty else {
                    self.dob = nil
                    self.age = nil
                    self.ageTextFieldString = newValue
                    return
                }
                guard let integer = Int(newValue) else {
                    return
                }
                self.age = integer
                withAnimation {
                    self.ageTextFieldString = newValue
                }
            }
        )
    }
    
    func fetchDOBFromHealth() {
        withAnimation {
            dobFetchStatus = .fetching
        }
        
        Task {
            guard let dob = await HealthKitManager.shared.currentDateOfBirthComponents() else {
                return
            }
            await MainActor.run {
                withAnimation {
                    self.dobFetchStatus = .fetched
                    self.dob = dob
                    if let age = dob.age {
                        self.age = age
                        self.ageTextFieldString = "\(age)"
                    } else {
                        self.age = nil
                        self.ageTextFieldString = ""
                    }
                }
            }
        }
    }
    
    var ageFormatted: String {
        guard let age = age else { return "" }
        return "\(age)"
    }

    var hasAge: Bool {
        age != nil
    }
    
    var hasDynamicAge: Bool {
        ageSource == .healthApp
    }
}

//MARK: - Height
extension BiometricsModel {
    var heightSourceBinding: Binding<MeasurementSource> {
        Binding<MeasurementSource>(
            get: { self.heightSource ?? .userEntered },
            set: { newSource in
                Haptics.feedback(style: .soft)
                self.changeHeightSource(to: newSource)
            }
        )
    }
    
    func changeHeightSource(to newSource: MeasurementSource) {
        withAnimation {
            heightSource = newSource
        }
        if newSource == .healthApp {
            fetchHeightFromHealth()
        }
    }
    
    var heightInCm: Double? {
        guard let height else { return nil }
        return userHeightUnit.cm * height
    }
    
    var heightTextFieldStringBinding: Binding<String> {
        Binding<String>(
            get: { self.heightTextFieldString },
            set: { newValue in
                guard !newValue.isEmpty else {
                    self.height = nil
                    self.heightTextFieldString = newValue
                    return
                }
                guard let double = Double(newValue) else {
                    return
                }
                self.height = double
                withAnimation {
                    self.heightTextFieldString = newValue
                }
            }
        )
    }
    
    func fetchHeightFromHealth() {
        withAnimation {
            heightFetchStatus = .fetching
        }
        
        Task {
            guard let (height, date) = await HealthKitManager.shared.latestHeight(unit: userHeightUnit) else {
                return
            }
            await MainActor.run {
                withAnimation {
                    self.heightFetchStatus = .fetched
                    self.height = height
                    self.heightTextFieldString = height.cleanAmount
                    self.heightDate = date
                }
            }
        }
    }
    
    var heightFormatted: String {
        height?.cleanAmount ?? ""
    }

    var heightFormattedWithUnit: String {
        guard let height else { return "" }
        return height.cleanAmount + " " + userHeightUnit.shortDescription
    }

    var hasHeight: Bool {
        height != nil
    }
    
    var hasDynamicHeight: Bool {
        heightSource == .healthApp
    }
}

//MARK: - Weight
extension BiometricsModel {
    var weightSourceBinding: Binding<MeasurementSource> {
        Binding<MeasurementSource>(
            get: { self.weightSource ?? .userEntered },
            set: { newSource in
                Haptics.feedback(style: .soft)
                self.changeWeightSource(to: newSource)
            }
        )
    }
    
    func changeWeightSource(to newSource: MeasurementSource) {
        withAnimation {
            weightSource = newSource
        }
        if newSource == .healthApp {
            fetchWeightFromHealth()
        }
    }
    
    var weightInKg: Double? {
        guard let weight else { return nil }
        switch userWeightUnit {
        case .kg:
            return weight
        case .lb:
            return (WeightUnit.lb.g/WeightUnit.kg.g) * weight
        default:
            return nil
        }
    }
    
    var weightTextFieldStringBinding: Binding<String> {
        Binding<String>(
            get: { self.weightTextFieldString },
            set: { newValue in
                guard !newValue.isEmpty else {
                    self.weight = nil
                    self.weightTextFieldString = newValue
                    return
                }
                guard let double = Double(newValue) else {
                    return
                }
                self.weight = double
                withAnimation {
                    self.weightTextFieldString = newValue
                }
            }
        )
    }
    
    func fetchWeightFromHealth() {
        withAnimation {
            weightFetchStatus = .fetching
        }
        
        Task {
            guard let (weight, date) = await HealthKitManager.shared.latestWeight(unit: userWeightUnit) else {
                return
            }
            await MainActor.run {
                withAnimation {
                    self.weightFetchStatus = .fetched
                    self.weight = weight
                    self.weightTextFieldString = weight.cleanAmount
                    self.weightDate = date
                }
            }
        }
    }
    
    var weightFormatted: String {
        weight?.cleanAmount ?? ""
    }

    var weightFormattedWithUnit: String {
        guard let weight else { return "" }
        return weight.cleanAmount + " " + userWeightUnit.shortDescription
    }

    var hasWeight: Bool {
        weight != nil
    }
    
    var hasDynamicWeight: Bool {
        weightSource == .healthApp
    }
}

//MARK: - LBM
extension BiometricsModel {
    var lbmSourceBinding: Binding<LeanBodyMassSource> {
        Binding<LeanBodyMassSource>(
            get: { self.lbmSource ?? .userEntered },
            set: { newSource in
                Haptics.feedback(style: .soft)
                self.changeLBMSource(to: newSource)
            }
        )
    }
    
    func changeLBMSource(to newSource: LeanBodyMassSource) {
        withAnimation {
            lbmSource = newSource
        }
        if newSource == .healthApp {
            Task {
                await fetchLBMFromHealth()
            }
        }
    }
    
    var lbmValue: Double? {
        switch lbmSource {
        case .fatPercentage, .formula:
            return calculatedLeanBodyMass
        default:
            return lbm
        }
    }
    
    var fatPercentage: Double? {
        switch lbmSource {
        case .fatPercentage:
            return lbm
        default:
            return calculatedFatPercentage
        }
    }
    
    var calculatedFatPercentage: Double? {
        /// Assuming the value in `lbm` isn't already the fat percentage...
        guard lbmSource != .fatPercentage else { return nil }
        guard let weight, let lbm else { return nil }
        let fatMass = weight - lbm
        return fatMass / weight
    }
    
    var lbmInKg: Double? {
        guard let lbmValue else { return nil }
        switch userWeightUnit {
        case .kg:
            return lbmValue
        case .lb:
            return (WeightUnit.lb.g/WeightUnit.kg.g) * lbmValue
        default:
            return nil
        }
    }
    
    var lbmTextFieldStringBinding: Binding<String> {
        Binding<String>(
            get: { self.lbmTextFieldString },
            set: { newValue in
                guard !newValue.isEmpty else {
                    self.lbm = nil
                    self.lbmTextFieldString = newValue
                    return
                }
                guard let double = Double(newValue) else {
                    return
                }
                
                if self.lbmSource == .fatPercentage {
                    guard double < 100 else {
                        return
                    }
                }
                self.lbm = double
                withAnimation {
                    self.lbmTextFieldString = newValue
                }
            }
        )
    }
    
    var lbmFormulaBinding: Binding<LeanBodyMassFormula> {
        Binding<LeanBodyMassFormula>(
            get: { self.lbmFormula },
            set: { newFormula in
                Haptics.feedback(style: .soft)
                self.changeLBMFormula(to: newFormula)
            }
        )
    }
    
    func changeLBMFormula(to newFormula: LeanBodyMassFormula) {
        withAnimation {
            self.lbmFormula = newFormula
        }
    }
    
    func fetchLBMFromHealth() async {
        await MainActor.run {
            withAnimation {
                lbmFetchStatus = .fetching
            }
        }
        
        guard let (lbm, date) = await HealthKitManager.shared.latestLeanBodyMass(unit: userWeightUnit) else {
            return
        }
        await MainActor.run {
            withAnimation {
                self.lbmFetchStatus = .fetched
                self.lbm = lbm
                self.lbmTextFieldString = lbm.cleanAmount
                self.lbmDate = date
            }
        }
    }
    
    var lbmFormatted: String {
        switch lbmSource {
        case .formula, .fatPercentage:
            return calculatedLeanBodyMass?.clean ?? ""
        default:
            return lbm?.clean ?? ""
        }
    }
    
    var calculatedLBMFormatted: String {
        calculatedLeanBodyMass?.cleanAmount ?? "empty"
    }

    var lbmFormattedWithUnit: String {
        let value: Double?
        switch lbmSource {
        case .formula, .fatPercentage:
            value = calculatedLeanBodyMass
        default:
            value = lbm
        }
        guard let value else { return "" }
        return value.rounded(toPlaces: 1).cleanAmount + " " + userWeightUnit.shortDescription
    }

    var hasLeanBodyMass: Bool {
        switch lbmSource {
        case .fatPercentage, .formula:
            return calculatedLeanBodyMass != nil
        case .healthApp, .userEntered:
            return lbm != nil
        default:
            return false
        }
    }
    
    var calculatedLeanBodyMass: Double? {
        let calculatedLBM: Double
        switch lbmSource {
        case .fatPercentage:
            guard let percent = lbm, let weight else { return nil }
            guard percent >= 0, percent <= 100 else { return nil }
            calculatedLBM = (1.0 - (percent/100.0)) * weight
        case .formula:
            guard let weightInKg, let heightInCm, let sex else { return nil }
            calculatedLBM = lbmFormula.calculate(
                sexIsFemale: sex == .female,
                weightInKg: weightInKg,
                heightInCm: heightInCm
            )
        default:
            return nil
        }
        return max(calculatedLBM, 0)
    }
}

//MARK: - LBM Form
extension BiometricsModel {
    
    var shouldShowSyncAllForLBMForm: Bool {
        guard lbmSource == .formula else { return false }
        var countNotSynced = 0
        if sexSource != .healthApp { countNotSynced += 1 }
        if weightSource != .healthApp { countNotSynced += 1 }
        if heightSource != .healthApp { countNotSynced += 1 }
        /// return true if the user has picked `.formula` as the source and we have at least two parameters not synced
        return countNotSynced > 1
    }


}
