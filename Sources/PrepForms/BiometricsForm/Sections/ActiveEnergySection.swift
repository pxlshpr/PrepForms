import SwiftUI
import SwiftHaptics
import PrepDataTypes
import ActivityIndicatorView
import SwiftUISugar
import HealthKit
import PrepCoreDataStack

struct ActiveEnergySection: View {
    
    @EnvironmentObject var model: BiometricsModel
    @State var showFormOnAppear = false
    @State var showingSourcePicker = false

    var body: some View {
        VStack(spacing: 7) {
            header
            content
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 0)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(Color(.secondarySystemGroupedBackground))
                )
                .padding(.bottom, 10)
                .if(model.activeEnergyFooterString == nil) { view in
                    view.padding(.bottom, 10)
                }
            footer
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    var header: some View {
        BiometricSectionHeader(type: .activeEnergy)
            .environmentObject(model)
            .padding(.horizontal, 20)
    }

    var sourceSection: some View {
        var label: some View {
            BiometricSourcePickerLabel(source: model.activeEnergySourceBinding.wrappedValue)
        }
        
        var sourcePickerSheet: some View {
            PickerSheet(
                title: "Choose a Source",
                items: ActiveEnergySource.pickerItems,
                pickedItem: model.activeEnergySource?.pickerItem,
                didPick: {
                    Haptics.feedback(style: .soft)
                    guard let pickedSource = ActiveEnergySource(pickerItem: $0) else { return }
                    model.changeActiveEnergySource(to: pickedSource)
                }
            )
        }
        
        var pickerButton: some View {
            Button {
                Haptics.feedback(style: .soft)
                showingSourcePicker = true
            } label: {
                label
            }
            .sheet(isPresented: $showingSourcePicker) { sourcePickerSheet }
        }

        return HStack {
            pickerButton
            Spacer()
        }
        .padding(.horizontal, 17)
    }
    
    var healthPeriodContent: some View {
        var intervalTypeMenu: some View {
           Menu {
               Picker(selection: model.activeEnergyIntervalTypeBinding, label: EmptyView()) {
                    ForEach(HealthIntervalType.allCases, id: \.self) {
                        Text($0.pickerDescription).tag($0)
                    }
                }
            } label: {
                PickerLabel(
                    model.activeEnergyInterval.intervalType.menuDescription,
                    imageColor: .green,
                    backgroundColor: .green,
                    foregroundColor: .green
                )
                .animation(.none, value: model.activeEnergyInterval)
                .fixedSize(horizontal: true, vertical: false)
            }
            .contentShape(Rectangle())
            .simultaneousGesture(TapGesture().onEnded {
                Haptics.feedback(style: .soft)
            })
        }
        
        var intervalValueMenu: some View {
            Menu {
                Picker(selection: model.activeEnergyIntervalValueBinding, label: EmptyView()) {
                    ForEach(model.activeEnergyIntervalValues, id: \.self) { quantity in
                        Text("\(quantity)").tag(quantity)
                    }
                }
            } label: {
                PickerLabel(
                    "\(model.activeEnergyInterval.value)",
                    imageColor: .green,
                    backgroundColor: .green,
                    foregroundColor: .green
                )
                .animation(.none, value: model.activeEnergyInterval)
                .fixedSize(horizontal: true, vertical: false)
            }
            .contentShape(Rectangle())
            .simultaneousGesture(TapGesture().onEnded {
                Haptics.feedback(style: .soft)
            })
        }
        
        var periodIntervalMenu: some View {
            Menu {
                Picker(selection: model.activeEnergyIntervalPeriodBinding, label: EmptyView()) {
                    ForEach(HealthPeriod.allCases, id: \.self) { interval in
                        Text("\(interval.description)\(model.activeEnergyInterval.value > 1 ? "s" : "")").tag(interval)
                    }
                }
            } label: {
                PickerLabel(
                    "\(model.activeEnergyInterval.period.description)\(model.activeEnergyInterval.value > 1 ? "s" : "")",
                    imageColor: .green,
                    backgroundColor: .green,
                    foregroundColor: .green
                )
                .animation(.none, value: model.activeEnergyInterval)
                .fixedSize(horizontal: true, vertical: false)
            }
            .contentShape(Rectangle())
            .simultaneousGesture(TapGesture().onEnded {
                Haptics.feedback(style: .soft)
            })
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
        var menu: some View {
            Menu {
                Picker(selection: model.activeEnergyActivityLevelBinding, label: EmptyView()) {
                    ForEach(ActivityLevel.allCases, id: \.self) {
                        Text($0.description).tag($0)
                    }
                }
            } label: {
                BiometricPickerLabel(model.activeEnergyActivityLevel.description)
                    .animation(.none, value: model.activeEnergyActivityLevel)
                    .fixedSize(horizontal: true, vertical: false)
//                    PickerLabel(model.activeEnergyActivityLevel.description)
            }
            .contentShape(Rectangle())
            .simultaneousGesture(TapGesture().onEnded {
                Haptics.feedback(style: .soft)
            })
        }
        return HStack {
            HStack {
//                    Text("using")
//                        .foregroundColor(Color(.tertiaryLabel))
                menu
//                    Text("formula")
//                        .foregroundColor(Color(.tertiaryLabel))
            }
        }
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
