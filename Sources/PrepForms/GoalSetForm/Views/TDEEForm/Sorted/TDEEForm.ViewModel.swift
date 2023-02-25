import SwiftUI
import PrepDataTypes
import SwiftHaptics
import HealthKit

extension DateComponents {
    var age: Int? {
        let calendar = Calendar.current
        let now = calendar.dateComponents([.year, .month, .day], from: Date())
        let ageComponents = calendar.dateComponents([.year], from: self, to: now)
        return ageComponents.year
    }
}

extension HeightUnit {
    var cm: Double {
        switch self {
        case .cm:
            return 1
        case .ft:
            return 30.48
        case .m:
            return 100
        }
    }
    
    var healthKitUnit: HKUnit {
        switch self {
        case .cm:
            return .meterUnit(with: .centi)
        case .ft:
            return .foot()
        case .m:
            return .meter()
        }
    }
}

extension TDEEForm.ViewModel {
    var maintenanceEnergy: Double? {
        guard let activeEnergyValue, let restingEnergyValue else {
            return nil
        }
        return activeEnergyValue + restingEnergyValue
    }
    
    var maintenanceEnergyInKcal: Double? {
        guard let maintenanceEnergy else { return nil }
        return userEnergyUnit.convert(maintenanceEnergy, to: .kcal)
//        if userEnergyUnit == .kcal {
//            return maintenanceEnergy
//        } else {
//            return maintenanceEnergy / KcalsPerKilojule
//        }
    }
    
    var maintenanceEnergyFormatted: String {
        guard let maintenanceEnergy else { return "" }
        return maintenanceEnergy.formattedEnergy
    }
}

//MARK: - Biological Sex
extension TDEEForm.ViewModel {
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

extension TDEEForm.ViewModel {
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
extension TDEEForm.ViewModel {
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
extension TDEEForm.ViewModel {
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
extension TDEEForm.ViewModel {
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
extension TDEEForm.ViewModel {
    
    var shouldShowSyncAllForLBMForm: Bool {
        guard lbmSource == .formula else { return false }
        var countNotSynced = 0
        if sexSource != .healthApp { countNotSynced += 1 }
        if weightSource != .healthApp { countNotSynced += 1 }
        if heightSource != .healthApp { countNotSynced += 1 }
        /// return true if the user has picked `.formula` as the source and we have at least two parameters not synced
        return countNotSynced > 1
    }

    func tappedSyncAllOnLBMForm() {
        
        withAnimation {
            sexFetchStatus = .fetching
            weightFetchStatus = .fetching
            heightFetchStatus = .fetching
        }
            
        Task {
            do {
                /// request permissions for all required parameters in one sheet
                try await HealthKitManager.shared.requestPermissions(
                    characteristicTypes: [.biologicalSex],
                    quantityTypes: [.bodyMass, .height]
                )
                await MainActor.run {
                    changeSexSource(to: .healthApp)
                    changeWeightSource(to: .healthApp)
                    changeHeightSource(to: .healthApp)
                }
            } catch {
                //TODO: Handle error
            }
        }
    }
}

//MARK: - Profile Form
extension TDEEForm.ViewModel {
    
    var hasProfile: Bool {
        let hasCore = (sex == .male || sex == .female)
            && age != nil && weight != nil
        return restingEnergyFormula.requiresHeight ? hasCore && height != nil : hasCore
    }
    
    var profileIsSynced: Bool {
        hasProfile
        && (weightSource == .healthApp || heightSource == .healthApp)
    }
    
    var shouldShowSyncAllForProfileForm: Bool {
        var countNotSynced = 0
        if sexSource != .healthApp { countNotSynced += 1 }
        if weightSource != .healthApp { countNotSynced += 1 }
        if ageSource != .healthApp { countNotSynced += 1 }
        if restingEnergyFormula.requiresHeight {
            if heightSource != .healthApp { countNotSynced += 1 }
        }
        return countNotSynced > 1
    }

    func tappedSyncAllOnProfileForm() {
        
        withAnimation {
            sexFetchStatus = .fetching
            weightFetchStatus = .fetching
            dobFetchStatus = .fetching
            if restingEnergyFormula.requiresHeight {
                heightFetchStatus = .fetching
            }
        }
            
        Task {
            do {
                let quantityTypes: [HKQuantityTypeIdentifier]
                if restingEnergyFormula.requiresHeight {
                    quantityTypes = [.bodyMass, .height]
                } else {
                    quantityTypes = [.bodyMass]
                }
                
                /// request permissions for all required parameters in one sheet
                try await HealthKitManager.shared.requestPermissions(
                    characteristicTypes: [.biologicalSex, .dateOfBirth],
                    quantityTypes: quantityTypes
                )
                await MainActor.run {
                    changeSexSource(to: .healthApp)
                    changeWeightSource(to: .healthApp)
                    changeAgeSource(to: .healthApp)
                    if restingEnergyFormula.requiresHeight {
                        changeHeightSource(to: .healthApp)
                    }
                }
            } catch {
                //TODO: Handle error
            }
        }
    }
}

//MARK: - Resting Energy

extension TDEEForm.ViewModel {
    
    var restingEnergyIsDynamic: Bool {
        switch restingEnergySource {
        case .healthApp:
            return true
        case .formula:
            return restingEnergyFormulaUsingSyncedHealthData
        default:
            return false
        }
    }
    
    var restingEnergyFormulaUsingSyncedHealthData: Bool {
        if restingEnergyFormula.usesLeanBodyMass {
            switch lbmSource {
            case .healthApp:
                return true
            case .fatPercentage:
                return weightSource == .healthApp
            case .formula:
                return weightSource == .healthApp
            default:
                return false
            }
        } else {
            return profileIsSynced
        }
    }
    
    var restingEnergyValue: Double? {
        switch restingEnergySource {
        case .formula:
            return calculatedRestingEnergy
        default:
            return restingEnergy
        }
    }
    
    var restingEnergyFormatted: String {
        switch restingEnergySource {
        case .formula:
            return calculatedRestingEnergy?.formattedEnergy ?? "zero" /// this string is required for the redaction to be visible
        default:
            return restingEnergy?.formattedEnergy ?? ""
        }
    }

    var restingEnergyIntervalValues: [Int] {
        Array(restingEnergyInterval.minValue...restingEnergyInterval.maxValue)
    }

    var calculatedRestingEnergy: Double? {
        guard restingEnergySource == .formula else { return nil }
        switch restingEnergyFormula {
        case .katchMcardle, .cunningham:
            guard let lbmInKg else { return nil }
            return restingEnergyFormula.calculate(lbmInKg: lbmInKg, energyUnit: userEnergyUnit)
        case .henryOxford, .schofield:
            guard let age, let weightInKg, let sex else { return nil }
            return restingEnergyFormula.calculate(
                age: age,
                weightInKg: weightInKg,
                sexIsFemale: sex == .female,
                energyUnit: userEnergyUnit
            )
        default:
            guard let age, let weightInKg, let heightInCm, let sex else { return nil }
            return restingEnergyFormula.calculate(
                age: age,
                weightInKg: weightInKg,
                heightInCm: heightInCm,
                sexIsFemale: sex == .female,
                energyUnit: userEnergyUnit
            )
        }
    }

    var hasRestingEnergy: Bool {
        switch restingEnergySource {
        case .formula:
            return calculatedRestingEnergy != nil
        case .healthApp, .userEntered:
            return restingEnergy != nil
        default:
            return false
        }
    }

    var restingEnergyPrefix: String? {
        switch restingEnergySource {
        case .healthApp:
            return restingEnergyPeriod.energyPrefix
        case .formula:
            return restingEnergyFormulaUsingSyncedHealthData ? "currently" : nil
        default:
            return nil
        }
    }
    
    var restingEnergySourceBinding: Binding<RestingEnergySource> {
        Binding<RestingEnergySource>(
            get: { self.restingEnergySource ?? .userEntered },
            set: { newSource in
                Haptics.feedback(style: .soft)
                self.changeRestingEnergySource(to: newSource)
            }
        )
    }
    
    var restingEnergyTextFieldStringBinding: Binding<String> {
        Binding<String>(
            get: { self.restingEnergyTextFieldString },
            set: { newValue in
                guard !newValue.isEmpty else {
                    self.restingEnergy = nil
                    self.restingEnergyTextFieldString = newValue
                    return
                }
                let withoutCommas = newValue.replacingOccurrences(of: ",", with: "")
                guard let double = Double(withoutCommas) else {
                    return
                }
                self.restingEnergy = double
                withAnimation {
                    self.restingEnergyTextFieldString = double.formattedEnergy
                }
            }
        )
    }
    
    func changeRestingEnergySource(to newSource: RestingEnergySource) {
        withAnimation {
            restingEnergySource = newSource
        }
        switch restingEnergySource {
        case .healthApp:
            fetchRestingEnergyFromHealth()
        case .formula:
            break
        default:
            break
        }
    }
    
    var restingEnergyFormulaBinding: Binding<RestingEnergyFormula> {
        Binding<RestingEnergyFormula>(
            get: { self.restingEnergyFormula },
            set: { newFormula in
                Haptics.feedback(style: .soft)
                self.changeRestingEnergyFormula(to: newFormula)
            }
        )
    }

    func changeRestingEnergyFormula(to newFormula: RestingEnergyFormula) {
        withAnimation {
            self.restingEnergyFormula = newFormula
        }
    }
    
    var restingEnergyPeriodBinding: Binding<HealthPeriodOption> {
        Binding<HealthPeriodOption>(
            get: { self.restingEnergyPeriod },
            set: { newPeriod in
                Haptics.feedback(style: .soft)
                self.changeRestingEnergyPeriod(to: newPeriod)
            }
        )
    }

    func changeRestingEnergyPeriod(to newPeriod: HealthPeriodOption) {
        withAnimation {
            self.restingEnergyPeriod = newPeriod
            if newPeriod == .previousDay {
                restingEnergyIntervalValue = 1
                restingEnergyInterval = .day
            } else {
                correctRestingEnergyIntervalValueIfNeeded()
            }
        }
        fetchRestingEnergyFromHealth()
    }
    
    var restingEnergyIntervalValueBinding: Binding<Int> {
        Binding<Int>(
            get: { self.restingEnergyIntervalValue },
            set: { newValue in
                Haptics.feedback(style: .soft)
                self.changeRestingEnergyIntervalValue(to: newValue)
            }
        )
    }
    
    func changeRestingEnergyIntervalValue(to newValue: Int) {
        guard newValue >= restingEnergyInterval.minValue,
              newValue <= restingEnergyInterval.maxValue else {
            return
        }
        withAnimation {
            restingEnergyIntervalValue = newValue
        }
        fetchRestingEnergyFromHealth()
    }
    
    var restingEnergyIntervalBinding: Binding<HealthAppInterval> {
        Binding<HealthAppInterval>(
            get: { self.restingEnergyInterval },
            set: { newInterval in
                Haptics.feedback(style: .soft)
                self.changeRestingEnergyInterval(to: newInterval)
            }
        )
    }
    
    func changeRestingEnergyInterval(to newInterval: HealthAppInterval) {
        withAnimation {
            restingEnergyInterval = newInterval
            correctRestingEnergyIntervalValueIfNeeded()
        }
        
        fetchRestingEnergyFromHealth()
    }
    
    func correctRestingEnergyIntervalValueIfNeeded() {
        if restingEnergyIntervalValue < restingEnergyInterval.minValue {
            restingEnergyIntervalValue = restingEnergyInterval.minValue
        }
        if restingEnergyIntervalValue > restingEnergyInterval.maxValue {
            restingEnergyIntervalValue = restingEnergyInterval.maxValue
        }
    }

    var restingEnergyFooterString: String? {
        let prefix = "This is an estimate of the energy your body uses each day while minimally active."
        if restingEnergySource == .healthApp {
            return prefix + " This will sync with your Health data and update daily."
        }
        return prefix
    }

    func fetchRestingEnergyFromHealth() {
        withAnimation {
            restingEnergyFetchStatus = .fetching
        }
        
        Task {
            do {
                guard let average = try await HealthKitManager.shared.averageSumOfRestingEnergy(
                    using: userEnergyUnit,
                    overPast: restingEnergyIntervalValue,
                    interval: restingEnergyInterval
                ) else {
                    await MainActor.run {
                        withAnimation {
                            restingEnergyFetchStatus = .notAuthorized
                        }
                    }
                    return
                }
                await MainActor.run {
                    withAnimation {
                        cprint("🔥 setting average: \(average)")
                        restingEnergy = average
                        restingEnergyTextFieldString = "\(Int(average.rounded()))"
                        restingEnergyFetchStatus = .fetched
                    }
                }
            } catch HealthKitManagerError.couldNotGetSumQuantity {
                /// Indicates that permissions are not present
                await MainActor.run {
                    withAnimation {
                        restingEnergyFetchStatus = .notAuthorized
                    }
                }
            } catch {
                
            }
            /// [ ] Make sure we persist this to the backend once the user saves it
        }
    }
}

//MARK: - Active Energy

extension TDEEForm.ViewModel {

    var activeEnergyIsDynamic: Bool {
        switch activeEnergySource {
        case .healthApp:
            return true
        default:
            return false
        }
    }
    
    var activeEnergyFormatted: String {
        switch activeEnergySource {
        case .activityLevel:
            return calculatedActiveEnergy?.formattedEnergy ?? "zero"
        default:
            return activeEnergy?.formattedEnergy ?? ""
        }
    }

    var activeEnergyIntervalValues: [Int] {
        Array(activeEnergyInterval.minValue...activeEnergyInterval.maxValue)
    }
    
    var calculatedActiveEnergy: Double? {
        guard activeEnergySource == .activityLevel,
              let restingEnergy = restingEnergyValue
        else { return nil }
        
        let total = activeEnergyActivityLevel.scaleFactor * restingEnergy
        return total - restingEnergy
    }

    var activeEnergyActivityLevelBinding: Binding<ActivityLevel> {
        Binding<ActivityLevel>(
            get: { self.activeEnergyActivityLevel },
            set: { newActivityLevel in
                Haptics.feedback(style: .soft)
                self.changeActiveEnergyActivityLevel(to: newActivityLevel)
            }
        )
    }

    func changeActiveEnergyActivityLevel(to newFormula: ActivityLevel) {
        withAnimation {
            self.activeEnergyActivityLevel = newFormula
        }
    }
    
    var activeEnergyValue: Double? {
        switch activeEnergySource {
        case .activityLevel:
            return calculatedActiveEnergy
        default:
            return activeEnergy
        }
    }

    var hasActiveEnergy: Bool {
        switch activeEnergySource {
        case .activityLevel:
            return calculatedActiveEnergy != nil
        case .healthApp, .userEntered:
            return activeEnergy != nil
        default:
            return false
        }
    }

    var activeEnergyPrefix: String? {
        switch activeEnergySource {
        case .healthApp:
            return activeEnergyPeriod.energyPrefix
        default:
            return nil
        }
    }
    
    var activeEnergySourceBinding: Binding<ActiveEnergySource> {
        Binding<ActiveEnergySource>(
            get: { self.activeEnergySource ?? .userEntered },
            set: { newSource in
                Haptics.feedback(style: .soft)
                self.changeActiveEnergySource(to: newSource)
            }
        )
    }
    
    var activeEnergyTextFieldStringBinding: Binding<String> {
        Binding<String>(
            get: { self.activeEnergyTextFieldString },
            set: { newValue in
                guard !newValue.isEmpty else {
                    self.activeEnergy = nil
                    self.activeEnergyTextFieldString = newValue
                    return
                }
                let withoutCommas = newValue.replacingOccurrences(of: ",", with: "")
                guard let double = Double(withoutCommas) else {
                    return
                }
                self.activeEnergy = double
                withAnimation {
                    self.activeEnergyTextFieldString = double.formattedEnergy
                }
            }
        )
    }
    
    func changeActiveEnergySource(to newSource: ActiveEnergySource) {
        withAnimation {
            activeEnergySource = newSource
        }
        switch activeEnergySource {
        case .healthApp:
            fetchActiveEnergyFromHealth()
        default:
            break
        }
    }
    
    var activeEnergyPeriodBinding: Binding<HealthPeriodOption> {
        Binding<HealthPeriodOption>(
            get: { self.activeEnergyPeriod },
            set: { newPeriod in
                Haptics.feedback(style: .soft)
                self.changeActiveEnergyPeriod(to: newPeriod)
            }
        )
    }

    func changeActiveEnergyPeriod(to newPeriod: HealthPeriodOption) {
        withAnimation {
            self.activeEnergyPeriod = newPeriod
            if newPeriod == .previousDay {
                activeEnergyIntervalValue = 1
                activeEnergyInterval = .day
            } else {
                correctActiveEnergyIntervalValueIfNeeded()
            }
        }
        fetchActiveEnergyFromHealth()
    }
    
    var activeEnergyIntervalValueBinding: Binding<Int> {
        Binding<Int>(
            get: { self.activeEnergyIntervalValue },
            set: { newValue in
                Haptics.feedback(style: .soft)
                self.changeActiveEnergyIntervalValue(to: newValue)
            }
        )
    }
    
    func changeActiveEnergyIntervalValue(to newValue: Int) {
        guard newValue >= activeEnergyInterval.minValue,
              newValue <= activeEnergyInterval.maxValue else {
            return
        }
        withAnimation {
            activeEnergyIntervalValue = newValue
        }
        fetchActiveEnergyFromHealth()
    }
    
    var activeEnergyIntervalBinding: Binding<HealthAppInterval> {
        Binding<HealthAppInterval>(
            get: { self.activeEnergyInterval },
            set: { newInterval in
                Haptics.feedback(style: .soft)
                self.changeActiveEnergyInterval(to: newInterval)
            }
        )
    }
    
    func changeActiveEnergyInterval(to newInterval: HealthAppInterval) {
        withAnimation {
            activeEnergyInterval = newInterval
            correctActiveEnergyIntervalValueIfNeeded()
        }
        
        fetchActiveEnergyFromHealth()
    }
    
    func correctActiveEnergyIntervalValueIfNeeded() {
        if activeEnergyIntervalValue < activeEnergyInterval.minValue {
            activeEnergyIntervalValue = activeEnergyInterval.minValue
        }
        if activeEnergyIntervalValue > activeEnergyInterval.maxValue {
            activeEnergyIntervalValue = activeEnergyInterval.maxValue
        }
    }
    
    func fetchActiveEnergyFromHealth() {
        withAnimation {
            activeEnergyFetchStatus = .fetching
        }
        
        Task {
            do {
                guard let average = try await HealthKitManager.shared.averageSumOfActiveEnergy(
                    using: userEnergyUnit,
                    overPast: activeEnergyIntervalValue,
                    interval: activeEnergyInterval
                ) else {
                    await MainActor.run {
                        withAnimation {
                            activeEnergyFetchStatus = .notAuthorized
                        }
                    }
                    return
                }
                await MainActor.run {
                    withAnimation {
                        cprint("🔥 setting average: \(average)")
                        activeEnergy = average
                        activeEnergyTextFieldString = "\(Int(average.rounded()))"
                        activeEnergyFetchStatus = .fetched
                    }
                }
            } catch HealthKitManagerError.couldNotGetSumQuantity {
                /// Indicates that permissions are not present
                await MainActor.run {
                    withAnimation {
                        activeEnergyFetchStatus = .notAuthorized
                    }
                }
            } catch {
                
            }
            /// [ ] Make sure we persist this to the backend once the user saves it
        }
    }
 
    var activeEnergyFooterString: String? {
        let prefix = "This is an estimate of energy burnt over and above your Resting Energy use."
        if activeEnergySource == .healthApp {
            return prefix + " This will sync with your Health data and update daily."
        }
        return prefix
    }
}

//MARK: - UI Helpers
extension TDEEForm.ViewModel {
    
    var maintenanceEnergyFooterText: Text {
        let energy = userEnergyUnit == .kcal ? "calories" : "kiljoules"
        return Text("This is an estimate of how many \(energy) you would have to consume to *maintain* your current weight.")
    }
    
    func updateHealthAppDataIfNeeded() {
        if restingEnergySource == .healthApp {
            fetchRestingEnergyFromHealth()
        }
        //TODO: We need to fetch other HealthApp synced data here too
    }

    var shouldShowSaveButton: Bool {
        guard isEditing, bodyProfile.hasTDEE else { return false }
        if let existingProfile {
            /// We're only checking the parameters as the `updatedAt` flag, `syncStatus` might differ.
            return existingProfile != bodyProfile
        }
        return true
    }
    
    var shouldShowEditButton: Bool {
        guard !isEditing else { return false }
        return existingProfile != nil
    }
    
    var shouldShowInitialSetupButton: Bool {
        !shouldShowSummary
//        existingProfile == nil && !isEditing
    }
    
    var shouldShowSummary: Bool {
        bodyProfile.hasTDEE
    }
    
    var isDynamic: Bool {
        restingEnergyIsDynamic || activeEnergyIsDynamic
    }
}
extension TDEEForm.ViewModel {
 
    
    //MARK: - Profile
    
    var bodyProfile: BodyProfile {
        
        var restingEnergyFormula: RestingEnergyFormula? { restingEnergySource == .formula ? self.restingEnergyFormula : nil }
        var restingEnergyPeriod: HealthPeriodOption? { restingEnergySource == .healthApp ? self.restingEnergyPeriod : nil }
        var restingEnergyIntervalValue: Int? { restingEnergySource == .healthApp ? self.restingEnergyIntervalValue : nil }
        var restingEnergyInterval: HealthAppInterval? { restingEnergySource == .healthApp ? self.restingEnergyInterval : nil }
        
        var activeEnergyPeriod: HealthPeriodOption? { activeEnergySource == .healthApp ? self.activeEnergyPeriod : nil }
        var activeEnergyActivityLevel: ActivityLevel? { activeEnergySource == .activityLevel ? self.activeEnergyActivityLevel : nil }
        var activeEnergyIntervalValue: Int? { activeEnergySource == .healthApp ? self.activeEnergyIntervalValue : nil }
        var activeEnergyInterval: HealthAppInterval? { activeEnergySource == .healthApp ? self.activeEnergyInterval : nil }
        
        var lbmFormula: LeanBodyMassFormula? { lbmSource == .formula ? self.lbmFormula : nil }
        var lbmDate: Date? { lbmSource == .healthApp ? self.lbmDate : nil }
        
        var weightDate: Date? { weightSource == .healthApp ? self.weightDate : nil }
        var heightDate: Date? { heightSource == .healthApp ? self.heightDate : nil }
        
        return BodyProfile(
            energyUnit: userEnergyUnit,
            weightUnit: userWeightUnit,
            heightUnit: userHeightUnit,
            restingEnergy: restingEnergyValue,
            restingEnergySource: restingEnergySource,
            restingEnergyFormula: restingEnergyFormula,
            restingEnergyPeriod: restingEnergyPeriod,
            restingEnergyIntervalValue: restingEnergyIntervalValue,
            restingEnergyInterval: restingEnergyInterval,
            activeEnergy: activeEnergyValue,
            activeEnergySource: activeEnergySource,
            activeEnergyActivityLevel: activeEnergyActivityLevel,
            activeEnergyPeriod: activeEnergyPeriod,
            activeEnergyIntervalValue: activeEnergyIntervalValue,
            activeEnergyInterval: activeEnergyInterval,
            fatPercentage: fatPercentage,
            lbm: lbmValue, /// We don't use `lbm` here because it may be the actual percentage
            lbmSource: lbmSource,
            lbmFormula: lbmFormula,
            lbmDate: lbmDate,
            weight: weight,
            weightSource: weightSource,
            weightDate: weightDate,
            height: height,
            heightSource: heightSource,
            heightDate: heightDate,
            sexIsFemale: sexIsFemale,
            sexSource: sexSource,
            age: age,
            dobDay: dob?.day,
            dobMonth: dob?.month,
            dobYear: dob?.year,
            ageSource: ageSource
        )
    }
}

//MARK: - Definition

extension TDEEForm {
    class ViewModel: ObservableObject {
        let userEnergyUnit: EnergyUnit
        let userWeightUnit: WeightUnit
        let userHeightUnit: HeightUnit

        @Published var path: [TDEEFormRoute] = []
        @Published var isEditing = false

        @Published var presentationDetent: PresentationDetent
        @Published var detents: Set<PresentationDetent>
        
        @Published var hasAppeared = false

        @Published var restingEnergySource: RestingEnergySource? = nil
        @Published var restingEnergyFormula: RestingEnergyFormula = .katchMcardle
        @Published var restingEnergy: Double? = nil
        @Published var restingEnergyTextFieldString: String = ""
        @Published var restingEnergyPeriod: HealthPeriodOption = .average
        @Published var restingEnergyIntervalValue: Int = 1
        @Published var restingEnergyInterval: HealthAppInterval = .week
        @Published var restingEnergyFetchStatus: HealthKitFetchStatus = .notFetched

        @Published var activeEnergySource: ActiveEnergySource? = nil
        @Published var activeEnergyActivityLevel: ActivityLevel = .moderatelyActive
        @Published var activeEnergy: Double? = nil
        @Published var activeEnergyTextFieldString: String = ""
        @Published var activeEnergyPeriod: HealthPeriodOption = .previousDay
        @Published var activeEnergyIntervalValue: Int = 1
        @Published var activeEnergyInterval: HealthAppInterval = .day
        @Published var activeEnergyFetchStatus: HealthKitFetchStatus = .notFetched

        
        @Published var lbmSource: LeanBodyMassSource? = nil
        @Published var lbmFormula: LeanBodyMassFormula = .boer
        @Published var lbmFetchStatus: HealthKitFetchStatus = .notFetched
        @Published var lbm: Double? = nil
        @Published var lbmTextFieldString: String = ""
        @Published var lbmDate: Date? = nil

        @Published var weightSource: MeasurementSource? = nil
        @Published var weightFetchStatus: HealthKitFetchStatus = .notFetched
        @Published var weight: Double? = nil
        @Published var weightTextFieldString: String = ""
        @Published var weightDate: Date? = nil

        @Published var heightSource: MeasurementSource? = nil
        @Published var heightFetchStatus: HealthKitFetchStatus = .notFetched
        @Published var height: Double? = nil
        @Published var heightTextFieldString: String = ""
        @Published var heightDate: Date? = nil

        @Published var sexSource: MeasurementSource? = nil
        @Published var sexFetchStatus: HealthKitFetchStatus = .notFetched
        @Published var sex: HKBiologicalSex? = nil

        @Published var ageSource: MeasurementSource? = nil
        @Published var dobFetchStatus: HealthKitFetchStatus = .notFetched
        @Published var dob: DateComponents? = nil
        @Published var age: Int? = nil
        @Published var ageTextFieldString: String = ""

        /// These were used when trying to force the detents to switch
//        @Published var presentationDetent: PresentationDetent = .custom(PrimaryDetent.self)
//        @Published var detents: Set<PresentationDetent> = [.custom(PrimaryDetent.self), .custom(SecondaryDetent.self)]

        let existingProfile: BodyProfile?
        
        init(
            existingProfile: BodyProfile?,
            userUnits: UserUnits
        ) {
            self.userEnergyUnit = userUnits.energy
            self.userWeightUnit = userUnits.weight
            self.userHeightUnit = userUnits.height
            
            self.existingProfile = existingProfile
                        
            if let existingProfile, existingProfile.hasTDEE {
                if existingProfile.hasDynamicTDEE {
                    detents = [.medium, .large]
                    presentationDetent = .medium
                } else {
                    detents = [.height(400), .large]
                    presentationDetent = .height(400)
                }
            } else {
                detents = [.height(270), .large]
                presentationDetent = .height(270)
            }
            
            if let existingProfile {
                self.load(existingProfile)
            }
        }
    }
}

struct TDEEForm_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            Color.clear
                .sheet(isPresented: .constant(true)) {
                    TDEEFormPreview()
                }
        }
    }
}
