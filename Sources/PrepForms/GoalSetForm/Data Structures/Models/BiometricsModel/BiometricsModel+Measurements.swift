import SwiftUI
import PrepDataTypes
import HealthKit
import SwiftHaptics
import PrepCoreDataStack

extension BiometricsModel {
    
    var hasRestingEnergyEquationVariables: Bool {
        let hasCore = (sex == .male || sex == .female)
        && age != nil && weight != nil
        
        return restingEnergyEquation.requiresHeight ? hasCore && height != nil : hasCore
    }
    
    var restingEnergyEquationVariablesAreSynced: Bool {
        guard hasRestingEnergyEquationVariables, restingEnergySource == .equation else {
            return false
        }
        
        if restingEnergyEquation.usesLeanBodyMass {
            return isSyncingLeanBodyMass
        } else {
            return weightSource == .health
        }
    }

    var leanBodyMassParametersAreSynced: Bool {
        guard lbmSource == .equation || lbmSource == .fatPercentage else { return false }
        return weightSource == .health
    }

    var shouldShowSyncAllForMeasurementsForm: Bool {
        var countNotSynced = 0
        if sexSource != .health { countNotSynced += 1 }
        if weightSource != .health { countNotSynced += 1 }
        if ageSource != .health { countNotSynced += 1 }
        if restingEnergyEquation.requiresHeight {
            if heightSource != .health { countNotSynced += 1 }
        }
        return countNotSynced >= 1
    }
}

//MARK: - Biological Sex
extension BiometricsModel {
    
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
        Task {
            if newSource == .health {
                await fetchSexFromHealth()
            }
            await MainActor.run {
                saveBiometrics()
            }
        }
    }
    
    
    func fetchSexFromHealth() async {
        
        @Sendable func syncFailed() {
            sexSyncStatus = .lastSyncFailed
            changeSexSource(to: .userEntered)
        }
        
        await MainActor.run {
            withAnimation {
                sexSyncStatus = .syncing
            }
        }
        
        guard let sex = await HealthKitManager.shared.currentBiologicalSex() else {
            await MainActor.run {
                withAnimation {
                    syncFailed()
                }
            }
            return
        }
        await MainActor.run {
            withAnimation {
                guard sex == .male || sex == .female else {
                    syncFailed()
                    return
                }
                sexSyncStatus = .synced
                self.sex = sex
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
        Task {
            if newSource == .health {
                await fetchDOBFromHealth()
            }
            await MainActor.run {
                saveBiometrics()
            }
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
    
    func fetchDOBFromHealth() async {
        await MainActor.run {
            withAnimation {
                dobSyncStatus = .syncing
            }
        }
        
        guard let dob = await HealthKitManager.shared.currentDateOfBirthComponents() else {
            await MainActor.run {
                withAnimation {
                    dobSyncStatus = .lastSyncFailed
                    changeAgeSource(to: .userEntered)
                }
            }
            return
        }
        await MainActor.run {
            withAnimation {
                dobSyncStatus = .synced
                
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
    
    var ageFormatted: String {
        guard let age = age else { return "" }
        return "\(age)"
    }

    var hasAge: Bool {
        age != nil
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
        Task {
            if newSource == .health {
                await fetchHeightFromHealth()
            }
            await MainActor.run {
                saveBiometrics()
            }
        }
    }
    
    var heightInCm: Double? {
        guard let height else { return nil }
        return UserManager.heightUnit.cm * height
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
    
    func fetchHeightFromHealth() async {
        await MainActor.run {
            withAnimation {
                heightSyncStatus = .syncing
            }
        }
        
        guard let (height, date) = await HealthKitManager.shared.latestHeight(unit: UserManager.heightUnit) else {
            await MainActor.run {
                withAnimation {
                    heightSyncStatus = .lastSyncFailed
                    changeHeightSource(to: .userEntered)
                }
            }
            return
        }
        await MainActor.run {
            withAnimation {
                heightSyncStatus = .synced
                self.height = height
                self.heightTextFieldString = height.cleanAmount
                self.heightDate = date
            }
        }
    }
    
    var heightFormatted: String {
        height?.cleanAmount ?? ""
    }
    
    var heightFormattedWithUnit: String {
        guard let height else { return "" }
        return height.cleanAmount + " " + UserManager.heightUnit.shortDescription
    }
    
    var hasHeight: Bool {
        height != nil
    }
}

extension BiometricsModel {
    
    var heightDateFormatted: String? {
        guard heightSource == .health else { return nil }
        return heightDate?.biometricFormat
    }
    
    var weightDateFormatted: String? {
        guard weightSource == .health else { return nil }
        return weightDate?.biometricFormat
    }
    
    var lbmPrefix: String? {
        switch lbmSource {
        case .health:
            return lbmDate?.biometricFormat
        case .fatPercentage:
            if weight != nil {
                return nil
            } else {
                return "requires weight"
            }
        default:
            return nil
        }
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
        Task {
            if newSource == .health {
                await fetchWeightFromHealth()
            }
            await MainActor.run {
                saveBiometrics()
            }
        }
    }
    
    var weightInKg: Double? {
        guard let weight else { return nil }
        switch UserManager.bodyMassUnit {
        case .kg:
            return weight
        case .lb:
            return (BodyMassUnit.lb.g/BodyMassUnit.kg.g) * weight
        case .st:
            return (BodyMassUnit.st.g/BodyMassUnit.kg.g) * weight
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
    
    func fetchWeightFromHealth() async {
        await MainActor.run {
            withAnimation {
                weightSyncStatus = .syncing
            }
        }
        
        guard let (weight, date) = await HealthKitManager.shared.latestWeight(unit: UserManager.bodyMassUnit) else {
            await MainActor.run {
                withAnimation {
                    weightSyncStatus = .lastSyncFailed
                    changeWeightSource(to: .userEntered)
                }
            }
            return
        }
        await MainActor.run {
            withAnimation {
                weightSyncStatus = .synced
                
                self.weight = weight
                self.weightTextFieldString = weight.cleanAmount
                self.weightDate = date
            }
        }
    }
    
    var weightFormatted: String {
        weight?.cleanAmount ?? ""
    }

    var weightFormattedWithUnit: String {
        guard let weight else { return "" }
        return weight.cleanAmount + " " + UserManager.bodyMassUnit.shortDescription
    }

    var hasWeight: Bool {
        weight != nil
    }
    
    var syncsWeight: Bool {
        weightSource == .health
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
        let changingToFatPercentage = lbmSource != .fatPercentage && newSource == .fatPercentage
        /// If we're changing **to** fat percentage and have a weight, convert it
        if changingToFatPercentage,
           let lbmAsBodyMass = lbm, let weight = weight, weight > 0
        {
            let percentage = (1 - max(min(lbmAsBodyMass / weight, 1), 0)) * 100
            self.lbm = percentage
        }
        
        /// If we're moving **from** fat percentage from *userEntered* and have a weight, convert it
        let changingFromFatPercentage = lbmSource == .fatPercentage && newSource == .userEntered
        if changingFromFatPercentage,
           let fatPercentage = lbm, let weight = weight, weight > 0
        {
            let bodyMass = (1 - (fatPercentage/100.0)) * weight
            self.lbm = bodyMass
        }

        withAnimation {
            lbmSource = newSource
        }
        
        Task {
            if newSource == .health {
                await fetchLBMFromHealth()
            }
            await MainActor.run {
                saveBiometrics()
            }
        }
    }
    
    var lbmValue: Double? {
        switch lbmSource {
        case .fatPercentage, .equation:
            return calculatedLeanBodyMass
        default:
            return lbm
        }
    }
    
    var fatPercentage: Double? {
        return lbm
//        switch lbmSource {
//        case .fatPercentage:
//            return lbm
//        default:
//            return calculatedFatPercentage
//        }
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
        switch UserManager.bodyMassUnit {
        case .kg:
            return lbmValue
        case .lb:
            return (BodyMassUnit.lb.g/BodyMassUnit.kg.g) * lbmValue
        case .st:
            return (BodyMassUnit.st.g/BodyMassUnit.kg.g) * lbmValue
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
    
    var lbmEquationBinding: Binding<LeanBodyMassEquation> {
        Binding<LeanBodyMassEquation>(
            get: { self.lbmEquation },
            set: { newEquation in
                Haptics.feedback(style: .soft)
                self.changeLBMEquation(to: newEquation)
            }
        )
    }
    
    func changeLBMEquation(to newEquation: LeanBodyMassEquation) {
        withAnimation {
            self.lbmEquation = newEquation
        }
        saveBiometrics()
    }
    
    func fetchLBMFromHealth() async {
        await MainActor.run {
            withAnimation {
                lbmSyncStatus = .syncing
            }
        }
        
        guard let (lbm, date) = await HealthKitManager.shared.latestLeanBodyMass(unit: UserManager.bodyMassUnit) else {
            await MainActor.run {
                withAnimation {
                    lbmSyncStatus = .lastSyncFailed
                    changeLBMSource(to: .userEntered)
                }
            }
            return
        }
        await MainActor.run {
            withAnimation {
                self.lbmSyncStatus = .synced
                
                self.lbm = lbm
                self.lbmTextFieldString = lbm.cleanAmount
                self.lbmDate = date
            }
        }
    }
    
    var lbmFormatted: String {
        switch lbmSource {
        case .equation, .fatPercentage:
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
        case .equation, .fatPercentage:
            value = calculatedLeanBodyMass
        default:
            value = lbm
        }
        guard let value else { return "" }
        return value.rounded(toPlaces: 1).cleanAmount + " " + UserManager.bodyMassUnit.shortDescription
    }

    var hasLeanBodyMass: Bool {
        switch lbmSource {
        case .fatPercentage, .equation:
            return calculatedLeanBodyMass != nil
        case .health, .userEntered:
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
        case .equation:
            guard let weightInKg, let heightInCm, let sex else { return nil }
            calculatedLBM = lbmEquation.calculate(
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
        guard lbmSource == .equation else { return false }
        var countNotSynced = 0
        if sexSource != .health { countNotSynced += 1 }
        if weightSource != .health { countNotSynced += 1 }
        if heightSource != .health { countNotSynced += 1 }
        /// return true if the user has picked `.equation` as the source and we have at least two parameters not synced
        return countNotSynced >= 1
    }


}
