import SwiftUI
import PrepDataTypes
import SwiftHaptics
import HealthKit

class BiometricsModel: ObservableObject {
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
    
    let existingProfile: Biometrics?
    
    init(
        existingProfile: Biometrics?,
        userUnits: UserOptions.Units
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

//MARK: Helpers

extension BiometricsModel {
    
    var tdeeDescriptionText: Text {
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
        guard isEditing, biometrics.hasTDEE else { return false }
        if let existingProfile {
            /// We're only checking the parameters as the `updatedAt` flag, `syncStatus` might differ.
            return existingProfile != biometrics
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
        biometrics.hasTDEE
    }
    
    var isDynamic: Bool {
        restingEnergyIsDynamic || activeEnergyIsDynamic
    }
}

extension BiometricsModel {
    
    var biometrics: Biometrics {
        
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
                
        var restingEnergyData: Biometrics.RestingEnergy {
            .init(
                amount: restingEnergyValue,
                unit: userEnergyUnit, //TODO: Change this
                source: restingEnergySource,
                formula: restingEnergyFormula,
                period: restingEnergyPeriod,
                intervalValue: restingEnergyIntervalValue,
                interval: restingEnergyInterval
            )
        }

        var activeEnergyData: Biometrics.ActiveEnergy {
            .init(
                amount: activeEnergyValue,
                unit: userEnergyUnit, //TODO: Change this
                source: activeEnergySource,
                activityLevel: activeEnergyActivityLevel,
                period: activeEnergyPeriod,
                intervalValue: activeEnergyIntervalValue,
                interval: activeEnergyInterval
            )
        }
        
        var leanBodyMassData: Biometrics.LeanBodyMass {
            .init(
                amount: lbmValue, /// We don't use `lbm` here because it may be the actual percentage
                unit: userWeightUnit, //TODO: Change this
                source: lbmSource,
                formula: lbmFormula,
                date: lbmDate
            )
        }
        
        var weightData: Biometrics.Weight {
            .init(
                amount: weight,
                unit: userWeightUnit, //TODO: Change this
                source: weightSource,
                date: weightDate
            )
        }

        var heightData: Biometrics.Height {
            .init(
                amount: height,
                unit: userHeightUnit, //TODO: Change this
                source: heightSource,
                date: heightDate
            )
        }
        
        var sexData: Biometrics.Sex {
            let biometricSex: BiometricSex?
            if let sexIsFemale {
                biometricSex = sexIsFemale ? .female : .male
            } else {
                biometricSex = nil
            }
            return .init(
                value: biometricSex,
                source: sexSource
            )
        }
        
        var ageData: Biometrics.Age {
            .init(
                value: age,
                dobDay: dob?.day,
                dobMonth: dob?.month,
                dobYear: dob?.year,
                source: ageSource
            )
        }

        return Biometrics(
            restingEnergy: restingEnergyData,
            activeEnergy: activeEnergyData,
            fatPercentage: fatPercentage,
            leanBodyMass: leanBodyMassData,
            weight: weightData,
            height: heightData,
            sex: sexData,
            age: ageData
        )
    }
}
