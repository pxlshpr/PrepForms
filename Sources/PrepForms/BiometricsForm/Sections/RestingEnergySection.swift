import SwiftUI
import SwiftHaptics
import PrepDataTypes
import ActivityIndicatorView
import SwiftUISugar
import HealthKit
import PrepCoreDataStack

struct RestingEnergySection: View {
    
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var model: BiometricsModel
    @State var showFormOnAppear = false
    let sheetPresenter: (RestingEnergySheet) -> ()
    
    var body: some View {
        VStack(spacing: 7) {
            header
            contentRow
            footer
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    var header: some View {
        BiometricSectionHeader(type: .restingEnergy)
            .environmentObject(model)
            .padding(.horizontal, 20)
    }
    
    var contentRow: some View {
        content
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 0)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(formCellBackgroundColor(colorScheme: colorScheme))
        )
        .if(model.restingEnergyFooterString == nil) { view in
            view.padding(.bottom, 10)
        }
    }
    
    
    @ViewBuilder
    var content: some View {
        VStack {
            Group {
                if let source = model.restingEnergySource {
                    filledContent(source)
                } else {
                    emptyContent
                }
            }
        }
    }
    
    func filledContent(_ source: RestingEnergySource) -> some View {
        Group {
            sourceSection
            switch source {
            case .health:
                healthContent
            case .userEntered:
                EmptyView()
            case .equation:
                equationContent
            }
            bottomRow
        }
    }
    
    var sourceSection: some View {
        var label: some View {
            BiometricSourcePickerLabel(source: model.restingEnergySourceBinding.wrappedValue)
        }

        var pickerButton: some View {
            Button {
                Haptics.feedback(style: .soft)
                present(.source)
            } label: {
                label
            }
        }
        
        return HStack {
            pickerButton
            Spacer()
        }
        .padding(.horizontal, 17)
    }

    func present(_ sheet: RestingEnergySheet) {
        sheetPresenter(sheet)
    }
    
    //MARK: - Equation Content
    
    var equationContent: some View {
        VStack {
            equationRow
            parametersRow
        }
    }
    
    var equationRow: some View {
        
        var equationButton: some View {
            Button {
                Haptics.feedback(style: .soft)
                present(.equation)
            } label: {
                BiometricPickerLabel(model.restingEnergyEquation.menuDescription)
            }
        }
        
        return HStack {
            HStack {
                Text("using")
                    .foregroundColor(Color(.tertiaryLabel))
                equationButton
                Text("equation")
                    .foregroundColor(Color(.tertiaryLabel))
            }
        }
        .padding(.top, 8)
    }
    
    var parametersRow: some View {
        
        var lbmFormButton: some View {
            let isSyncedBinding = Binding<Bool>(
                get: { model.restingEnergyEquationVariablesAreSynced },
                set: { _ in }
            )
            return Button {
                Haptics.feedback(style: .soft)
                present(.leanBodyMass)
            } label: {
                MeasurementLabel(
                    label: model.hasLeanBodyMass ? "lean body mass" : "set lean body mass",
                    valueString: model.lbmFormattedWithUnit,
                    useHealthAppData: isSyncedBinding.wrappedValue
                )
            }
        }
        
        var profileFormButton: some View {
            
            var usesHeight: Bool {
                model.restingEnergyEquation.requiresHeight
            }
            
            @ViewBuilder
            var label: some View {
                if model.hasRestingEnergyEquationVariables,
                   let age = model.age,
                   let sex = model.sex,
                   let weight = model.weight
                {
                    ProfileLabel(
                        age: age,
                        sex: sex,
                        weight: weight,
                        height: usesHeight ? model.height : nil,
                        bodyMassUnit: UserManager.bodyMassUnit,
                        heightUnit: UserManager.heightUnit,
                        isSynced: model.restingEnergyEquationVariablesAreSynced
                    )
                    .fixedSize(horizontal: true, vertical: false)
                } else {
                    MeasurementLabel(
                        label: "set components",
                        valueString: "",
                        useHealthAppData: false
                    )
                }
            }
            
            return Button {
                Haptics.feedback(style: .soft)
                present(.components)
            } label: {
                label
            }
        }
        
        var prefixString: some View {
            Text(model.restingEnergyEquation == .katchMcardle ? "with" : "as")
                .foregroundColor(Color(.tertiaryLabel))
//                .frame(height: 25)
//                .frame(maxHeight: .infinity)
                .padding(.vertical, 5)
                .padding(.bottom, 2)

        }
        
        @ViewBuilder
        var link: some View {
            if model.restingEnergyEquation.usesLeanBodyMass {
                lbmFormButton
            } else {
                profileFormButton
            }
        }

        
        var hStack: some View {
            HStack {
                prefixString
                link
            }
        }
        
        return hStack
    }
    
    func tappedManualEntry() {
        showFormOnAppear = true
        model.changeRestingEnergySource(to: .userEntered)
    }
    
    func tappedSyncWithHealth() {
        Task(priority: .high) {
            do {
                try await HealthKitManager.shared.requestPermission(for: .basalEnergyBurned)
                withAnimation {
                    model.restingEnergySource = .health
                }
                model.syncRestingEnergy()
            } catch {
                cprint("Error syncing with Health: \(error)")
            }
        }
    }
    
    func tappedEquation() {
        model.changeRestingEnergySource(to: .equation)
    }

    var emptyContent: some View {
        HStack {
            BiometricButton(healthTitle: "Sync", action: tappedSyncWithHealth)
            BiometricButton("Calculate", systemImage: "function", action: tappedEquation)
            BiometricButton("Enter", systemImage: "keyboard", action: tappedManualEntry)
        }
        .padding(.horizontal, 15)
    }
    
    var healthContent: some View {
        healthPeriodContent
            .padding()
            .padding(.horizontal)
    }
    
    var bottomRow: some View {
        let valueBinding = Binding<BiometricValue?>(
            get: {
                model.restingEnergyBiometricValue
            },
            set: { newValue in
                guard let energyUnit = newValue?.unit?.energyUnit else { return }
                model.restingEnergy = newValue?.double
                
                /// Convert other energy based values in `BiometricModel` before setting the unit
                if let activeEnergy = model.activeEnergy {
                    model.activeEnergy = UserManager.energyUnit.convert(activeEnergy, to: energyUnit)
                }
                UserManager.energyUnit = energyUnit
                
                /// Delay this by a second so that the core-data persistence doesn't interfere with
                /// the change of energy unit
                model.saveBiometrics(afterDelay: true)
            }
        )
        
        return BiometricValueRow(
            value: valueBinding,
            type: .restingEnergy,
            source: model.restingEnergySource ?? .userEntered,
            syncStatus: model.restingEnergySyncStatus,
            prefix: model.restingEnergyPrefix,
            showFormOnAppear: $showFormOnAppear
        )
        .padding(.horizontal)
    }
    
    var healthPeriodContent: some View {
        var intervalTypeMenu: some View {
            Button {
                Haptics.feedback(style: .soft)
                present(.intervalType)
            } label: {
                BiometricPickerLabel(model.restingEnergyInterval.intervalType.menuDescription)
            }
        }
        
        var periodIntervalMenu: some View {
            Button {
                Haptics.feedback(style: .soft)
                present(.intervalPeriod)
            } label: {
                BiometricPickerLabel(
                    "\(model.restingEnergyInterval.period.description)\(model.restingEnergyInterval.value > 1 ? "s" : "")"
                )
            }
        }
        
        
        var intervalValueMenu: some View {
            Button {
                Haptics.feedback(style: .soft)
                present(.intervalValue)
            } label: {
                BiometricPickerLabel("\(model.restingEnergyInterval.value)")
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
            if model.restingEnergyInterval.intervalType == .average {
                intervalRow
            }
        }
    }
    
    @ViewBuilder
    var footer: some View {
        if let string = model.restingEnergyFooterString {
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
