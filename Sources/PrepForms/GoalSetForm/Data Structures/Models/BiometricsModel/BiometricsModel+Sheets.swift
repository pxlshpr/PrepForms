import SwiftUI
import SwiftHaptics
import PrepDataTypes
import ActivityIndicatorView
import SwiftUISugar
import HealthKit
import PrepCoreDataStack

extension BiometricsModel {
    
    func restingEnergySheet(for sheet: RestingEnergySheet) -> some View {
        var source: some View {
            PickerSheet(
                title: "Choose a Source",
                items: RestingEnergySource.pickerItems,
                pickedItem: restingEnergySource?.pickerItem,
                didPick: {
                    Haptics.feedback(style: .soft)
                    guard let pickedSource = RestingEnergySource(pickerItem: $0) else { return }
                    self.changeRestingEnergySource(to: pickedSource)
                }
            )
        }
        
        var leanBodyMass: some View {
            LeanBodyMassForm(self)
                .environmentObject(self)
        }
        
        var components: some View {
            RestingEnergyComponents(self)
                .environmentObject(self)
        }
        
        var intervalType: some View {
            PickerSheet(
                title: "Choose a value",
                items: HealthIntervalType.pickerItems,
                pickedItem: restingEnergyInterval.intervalType.pickerItem,
                didPick: {
                    Haptics.feedback(style: .soft)
                    guard let pickedType = HealthIntervalType(pickerItem: $0) else { return }
                    self.changeRestingEnergyIntervalType(to: pickedType)
                }
            )
        }
        
        var intervalPeriod: some View {
            PickerSheet(
                title: "Duration to average",
                items: HealthPeriod.pickerItems,
                pickedItem: restingEnergyInterval.period.pickerItem,
                didPick: {
                    Haptics.feedback(style: .soft)
                    guard let pickedPeriod = HealthPeriod(pickerItem: $0) else { return }
                    self.changeRestingEnergyIntervalPeriod(to: pickedPeriod)
                }
            )
        }
        
        var intervalValue: some View {
            var items: [PickerItem] {
                self.restingEnergyIntervalValues.map { PickerItem(with: $0) }
            }
            
            return PickerSheet(
                title: "\(restingEnergyInterval.period.description.capitalizingFirstLetter())s to average",
                items: items,
                pickedItem: PickerItem(with: restingEnergyInterval.value),
                didPick: {
                    Haptics.feedback(style: .soft)
                    guard let value = Int($0.id) else { return }
                    self.changeRestingEnergyIntervalValue(to: value)
                }
            )
        }
        
        var equation: some View {
            PickerSheet(
                title: "Equation",
                items: RestingEnergyEquation.pickerItems,
                pickedItem: restingEnergyEquation.pickerItem,
                didPick: {
                    Haptics.feedback(style: .soft)
                    guard let pickedEquation = RestingEnergyEquation(pickerItem: $0) else { return }
                    self.changeRestingEnergyEquation(to: pickedEquation)
                }
            )
        }
        
        return Group {
            switch sheet {
            case .source:           source
            case .components:       components
            case .intervalType:     intervalType
            case .intervalPeriod:   intervalPeriod
            case .intervalValue:    intervalValue
            case .equation:         equation
            case .leanBodyMass:     leanBodyMass
            }
        }
    }
    
    func activeEnergySheet(for sheet: ActiveEnergySheet) -> some View {
        
        var intervalType: some View {
            PickerSheet(
                title: "Choose a value",
                items: HealthIntervalType.pickerItems,
                pickedItem: activeEnergyInterval.intervalType.pickerItem,
                didPick: {
                    Haptics.feedback(style: .soft)
                    guard let pickedType = HealthIntervalType(pickerItem: $0) else { return }
                    self.changeActiveEnergyIntervalType(to: pickedType)
                }
            )
        }
        
        var intervalPeriod: some View {
            PickerSheet(
                title: "Duration to average",
                items: HealthPeriod.pickerItems,
                pickedItem: activeEnergyInterval.period.pickerItem,
                didPick: {
                    Haptics.feedback(style: .soft)
                    guard let pickedPeriod = HealthPeriod(pickerItem: $0) else { return }
                    self.changeActiveEnergyIntervalPeriod(to: pickedPeriod)
                }
            )
        }
        
        var activityLevel: some View {
            PickerSheet(
                title: "Activity Level",
                items: ActivityLevel.pickerItems,
                pickedItem: activeEnergyActivityLevel.pickerItem,
                didPick: {
                    Haptics.feedback(style: .soft)
                    guard let pickedLevel = ActivityLevel(pickerItem: $0) else { return }
                    self.changeActiveEnergyActivityLevel(to: pickedLevel)
                }
            )
        }
        
        var intervalValue: some View {
            var items: [PickerItem] {
                activeEnergyIntervalValues.map { PickerItem(with: $0) }
            }
            
            return PickerSheet(
                title: "\(activeEnergyInterval.period.description.capitalizingFirstLetter())s to average",
                items: items,
                pickedItem: PickerItem(with: activeEnergyInterval.value),
                didPick: {
                    Haptics.feedback(style: .soft)
                    guard let value = Int($0.id) else { return }
                    self.changeActiveEnergyIntervalValue(to: value)
                }
            )
        }
        
        var source: some View {
            PickerSheet(
                title: "Choose a Source",
                items: ActiveEnergySource.pickerItems,
                pickedItem: activeEnergySource?.pickerItem,
                didPick: {
                    Haptics.feedback(style: .soft)
                    guard let pickedSource = ActiveEnergySource(pickerItem: $0) else { return }
                    self.changeActiveEnergySource(to: pickedSource)
                }
            )
        }
        
        return Group {
            switch sheet {
            case .source:
                source
            case .intervalType:
                intervalType
            case .intervalPeriod:
                intervalPeriod
            case .intervalValue:
                intervalValue
            case .activityLevel:
                activityLevel
            }
        }
        
    }
    
    func leanBodyMassSheet(for sheet: LeanBodyMassSheet) -> some View {
        
        var equation: some View {
            PickerSheet(
                title: "Equation",
                items: LeanBodyMassEquation.pickerItems,
                pickedItem: lbmEquation.pickerItem,
                didPick: {
                    Haptics.feedback(style: .soft)
                    guard let pickedEquation = LeanBodyMassEquation(pickerItem: $0) else { return }
                    self.changeLBMEquation(to: pickedEquation)
                }
            )
        }
        
        var source: some View {
            PickerSheet(
                title: "Choose a Source",
                items: LeanBodyMassSource.pickerItems,
                pickedItem: lbmSource?.pickerItem,
                didPick: {
                    Haptics.feedback(style: .soft)
                    guard let pickedSource = LeanBodyMassSource(pickerItem: $0) else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        self.changeLBMSource(to: pickedSource)
                    }
                }
            )
        }
        
        return Group {
            switch sheet {
            case .source:
                source
            case .equation:
                equation
            }
        }
    }

    func measurementSourcePickerSheet(for biometricType: BiometricType) -> some View {
        
        var measurementSource: MeasurementSource? {
            switch biometricType {
            case .sex:      return sexSource
            case .age:      return ageSource
            case .weight:   return weightSource
            case .height:   return heightSource
            default:        return nil
            }
        }
        
        func handlePickedItem(_ pickerItem: PickerItem) {
            Haptics.feedback(style: .soft)
            guard let pickedSource = MeasurementSource(pickerItem: pickerItem) else {
                return
            }
            
            switch biometricType {
            case .sex:
                changeSexSource(to: pickedSource)
            case .age:
                changeAgeSource(to: pickedSource)
            case .weight:
                changeWeightSource(to: pickedSource)
            case .height:
                changeHeightSource(to: pickedSource)
            default:
                break
            }
        }
        
        return PickerSheet(
            title: "Choose a Source",
            items: MeasurementSource.pickerItems,
            pickedItem: measurementSource?.pickerItem,
            didPick: handlePickedItem
        )
    }
    
}

enum RestingEnergySheet: Hashable, Identifiable {
    case source
    case components
    case intervalType
    case intervalPeriod
    case intervalValue
    case equation
    case leanBodyMass
    
    var id: Self { self }
}
