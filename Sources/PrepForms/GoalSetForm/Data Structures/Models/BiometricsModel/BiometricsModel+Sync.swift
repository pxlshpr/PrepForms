import SwiftUI
import HealthKit

extension BiometricsModel {
 
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

    func tappedSyncAllOnMeasurementsForm() {
        
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
    
    func tappedSyncAll() {
        
        withAnimation {
            restingEnergyFetchStatus = .fetching
            activeEnergyFetchStatus = .fetching
            lbmFetchStatus = .fetching
            sexFetchStatus = .fetching
            weightFetchStatus = .fetching
            heightFetchStatus = .fetching
            dobFetchStatus = .fetching
        }
        
        Task {
            do {
                try await HealthKitManager.shared.requestPermissions(
                    characteristicTypes: [
                        .biologicalSex,
                        .dateOfBirth
                    ],
                    quantityTypes: [
                        .basalEnergyBurned,
                        .activeEnergyBurned,
                        .bodyMass,
                        .leanBodyMass,
                        .height
                    ]
                )
                await MainActor.run {
                    changeActiveEnergySource(to: .healthApp)
                    changeRestingEnergySource(to: .healthApp)
                    changeLBMSource(to: .healthApp)
                    changeSexSource(to: .healthApp)
                    changeWeightSource(to: .healthApp)
                    changeHeightSource(to: .healthApp)
                    changeAgeSource(to: .healthApp)
                    
                    //TODO: Do properly after all values have been fetched and not with a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.save()
                    }
                }
            } catch {
                //TODO: Handle error
            }
        }
    }
}
