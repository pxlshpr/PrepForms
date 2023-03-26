import SwiftUI
import SwiftHaptics
import PrepDataTypes
import ActivityIndicatorView
import SwiftUISugar
import HealthKit
import PrepCoreDataStack

struct ActiveEnergySection: View {
    
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var model: BiometricsModel
    @State var showFormOnAppear = false
    let sheetPresenter: (ActiveEnergySheet) -> ()

    var body: some View {
        VStack(spacing: 7) {
            header
            content
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 0)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(formCellBackgroundColor(colorScheme: colorScheme))
                )
//                .padding(.bottom, 10)
                .if(model.activeEnergyFooterString == nil) { view in
                    view.padding(.bottom, 10)
                }
            footer
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
  
    func present(_ sheet: ActiveEnergySheet) {
        sheetPresenter(sheet)
    }

    var header: some View {
        BiometricSectionHeader(type: .activeEnergy)
            .environmentObject(model)
            .padding(.horizontal, 20)
    }

    var sourceSection: some View {
        var pickerButton: some View {
            Button {
                Haptics.feedback(style: .soft)
                present(.source)
            } label: {
                BiometricSourcePickerLabel(source: model.activeEnergySourceBinding.wrappedValue)
            }
        }

        return HStack {
            pickerButton
            Spacer()
        }
        .padding(.horizontal, 17)
    }

    var healthPeriodContent: some View {
        var intervalTypeMenu: some View {
            Button {
                Haptics.feedback(style: .soft)
                present(.intervalType)
            } label: {
                BiometricPickerLabel(model.activeEnergyInterval.intervalType.menuDescription)
            }
        }
        
        var periodIntervalMenu: some View {
            Button {
                Haptics.feedback(style: .soft)
                present(.intervalPeriod)
            } label: {
                BiometricPickerLabel(
                    "\(model.activeEnergyInterval.period.description)\(model.activeEnergyInterval.value > 1 ? "s" : "")"
                )
            }
        }
        
        
        var intervalValueMenu: some View {
            Button {
                Haptics.feedback(style: .soft)
                present(.intervalValue)
            } label: {
                BiometricPickerLabel("\(model.activeEnergyInterval.value)")
            }
        }
        
        var intervalRow: some View {
            HStack {
                Spacer()
                HStack(spacing: 5) {
                    Text("previous")
                        .foregroundColor(Color(.tertiaryLabel))
                    intervalValueMenu
                    periodIntervalMenu
                }
                Spacer()
            }
        }
        
        return VStack(spacing: 5) {
            HStack {
                Spacer()
                HStack {
                    Text("using")
                        .foregroundColor(Color(.tertiaryLabel))
                    intervalTypeMenu
                }
                Spacer()
            }
            if model.activeEnergyInterval.intervalType == .average {
                intervalRow
            }
        }
    }
    
    var healthContent: some View {
        healthPeriodContent
            .padding()
            .padding(.horizontal)
    }
    
    var bottomRow: some View {
        let valueBinding = Binding<BiometricValue?>(
            get: {
                model.activeEnergyBiometricValue
            },
            set: { newValue in
                guard let energyUnit = newValue?.unit?.energyUnit else { return }
                model.activeEnergy = newValue?.double
                
                /// Convert other energy based values in `BiometricModel` before setting the unit
                if let restingEnergy = model.restingEnergy {
                    model.restingEnergy = UserManager.energyUnit.convert(restingEnergy, to: energyUnit)
                }
                UserManager.energyUnit = energyUnit
                
                /// Delay this by a second so that the core-data persistence doesn't interfere with
                /// the change of energy unit
                model.saveBiometrics(afterDelay: true)
            }
        )
        
        return BiometricValueRow(
            value: valueBinding,
            type: .activeEnergy,
            source: model.activeEnergySource ?? .userEntered,
            syncStatus: model.activeEnergySyncStatus,
            prefix: model.activeEnergyPrefix,
            placeholder: "needs resting energy",
            showFormOnAppear: $showFormOnAppear
        )
        .padding(.horizontal)
    }
    
    var activityLevelContent: some View {
        
        var button: some View {
            Button {
                Haptics.feedback(style: .soft)
                present(.activityLevel)
            } label: {
                BiometricPickerLabel(model.activeEnergyActivityLevel.description)
            }
        }
        
        return button
            .padding(.top, 8)
    }
    
    @ViewBuilder
    var content: some View {
        VStack {
            Group {
                if let source = model.activeEnergySource {
                    Group {
                        sourceSection
                        switch source {
                        case .health:
                            healthContent
                        case .activityLevel:
                            activityLevelContent
                        case .userEntered:
                            EmptyView()
                        }
                        bottomRow
                    }
                } else {
                    emptyContent
                }
            }
        }
    }

    func tappedActivityLevel() {
        model.changeActiveEnergySource(to: .activityLevel)
        model.saveBiometrics()
    }

    func tappedManualEntry() {
        showFormOnAppear = true
        model.changeActiveEnergySource(to: .userEntered)
    }

    func tappedSyncWithHealth() {
        Task(priority: .high) {
            do {
                try await HealthKitManager.shared.requestPermission(for: .activeEnergyBurned)
                withAnimation {
                    model.activeEnergySource = .health
                }
                model.activeEnergySyncStatus = .syncing
                model.syncActiveEnergy()
            } catch {
                cprint("Error syncing with Health: \(error)")
            }
        }
    }
    
    var emptyContent: some View {
        HStack {
            BiometricButton(healthTitle: "Sync", action: tappedSyncWithHealth)
            BiometricButton("Activity", systemImage: "dial.medium.fill", action: tappedActivityLevel)
            BiometricButton("Enter", systemImage: "keyboard", action: tappedManualEntry)
        }
        .padding(.horizontal, 15)
    }
    
    @ViewBuilder
    var footer: some View {
        if let string = model.activeEnergyFooterString {
            Text(string)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(Color(.secondaryLabel))
                .font(.footnote)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
        }
    }
}
