import SwiftUI
import HealthKit
import PrepCoreDataStack

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
                    changeSexSource(to: .health)
                    changeWeightSource(to: .health)
                    changeHeightSource(to: .health)
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
                    changeSexSource(to: .health)
                    changeWeightSource(to: .health)
                    changeAgeSource(to: .health)
                    if restingEnergyFormula.requiresHeight {
                        changeHeightSource(to: .health)
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
                    changeActiveEnergySource(to: .health)
                    changeRestingEnergySource(to: .health)
                    changeLBMSource(to: .health)
                    changeSexSource(to: .health)
                    changeWeightSource(to: .health)
                    changeHeightSource(to: .health)
                    changeAgeSource(to: .health)
                    
                    //TODO: Do this correctly after all values have been fetched and not with an artificial delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.saveBiometrics()
                    }
                }
            } catch {
                //TODO: Handle error
            }
        }
    }
}
