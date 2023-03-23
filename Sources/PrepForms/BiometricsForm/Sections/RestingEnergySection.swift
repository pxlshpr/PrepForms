import SwiftUI
import SwiftHaptics
import PrepDataTypes
import ActivityIndicatorView
import SwiftUISugar
import HealthKit
import PrepCoreDataStack

struct RestingEnergySection: View {
    
    @EnvironmentObject var model: BiometricsModel
    @State var showFormOnAppear = false
    @State var presentedSheet: Sheet? = nil
    
    var body: some View {
        VStack(spacing: 7) {
            header
            contentRow
            footer
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .sheet(item: $presentedSheet) { sheet(for: $0) }
    }
    
    @ViewBuilder
    func sheet(for sheet: Sheet) -> some View {
        switch sheet {
        case .sourcePicker:
            sourcePickerSheet
        case .leanBodyMassForm:
            leanBodyMassForm
        case .profileForm:
            profileForm
        }
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
                .foregroundColor(Color(.secondarySystemGroupedBackground))
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
            case .formula:
                formulaContent
            }
            bottomRow
        }
    }

    var sourcePickerSheet: some View {
        PickerSheet(
            title: "Choose a Source",
            items: RestingEnergySource.pickerItems,
            pickedItem: model.restingEnergySource?.pickerItem,
            didPick: {
                Haptics.feedback(style: .soft)
                guard let pickedSource = RestingEnergySource(pickerItem: $0) else { return }
                model.changeRestingEnergySource(to: pickedSource)
            }
        )
    }
    
    var sourceSection: some View {
        var label: some View {
            BiometricSourcePickerLabel(source: model.restingEnergySourceBinding.wrappedValue)
        }

        var pickerButton: some View {
            Button {
                Haptics.feedback(style: .soft)
                present(.sourcePicker)
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

    enum Sheet: String, Identifiable {
        case profileForm
        case leanBodyMassForm
        case sourcePicker
        
        var id: String { rawValue }
    }
    
    func present(_ sheet: Sheet) {
        
        func present() {
            Haptics.feedback(style: .soft)
            presentedSheet = sheet
        }
        
        func delayedPresent() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                present()
            }
        }
        
        if presentedSheet != nil {
            presentedSheet = nil
            delayedPresent()
        } else {
            present()
        }
    }
    
    //MARK: - Formula Content
    
    var formulaContent: some View {
        VStack {
            formulaRow
            parametersRow
        }
    }
    
    var formulaRow: some View {
        var formulaMenu: some View {
            Menu {
                Picker(selection: model.restingEnergyFormulaBinding, label: EmptyView()) {
                    ForEach(RestingEnergyFormula.latest, id: \.self) { formula in
                        Text(formula.pickerDescription + " • " + formula.year).tag(formula)
                    }
                    Divider()
                    ForEach(RestingEnergyFormula.legacy, id: \.self) {
                        Text($0.pickerDescription + " • " + $0.year).tag($0)
                    }
                }
            } label: {
                BiometricPickerLabel(model.restingEnergyFormula.menuDescription)
                    .animation(.none, value: model.restingEnergyFormula)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .contentShape(Rectangle())
            .simultaneousGesture(TapGesture().onEnded {
                Haptics.feedback(style: .soft)
            })
        }
        
        return HStack {
            HStack {
                Text("using")
                    .foregroundColor(Color(.tertiaryLabel))
                formulaMenu
                Text("formula")
                    .foregroundColor(Color(.tertiaryLabel))
            }
        }
        .padding(.top, 8)
    }
    
    var leanBodyMassForm: some View {
        LeanBodyMassForm(model)
    }
    
    var profileForm: some View {
        ProfileForm()
            .environmentObject(model)
    }
    
    var parametersRow: some View {
        
        var lbmFormButton: some View {
            let isSyncedBinding = Binding<Bool>(
                get: { model.restingEnergyFormulaParametersAreSynced },
                set: { _ in }
            )
            return Button {
                Haptics.feedback(style: .soft)
                present(.leanBodyMassForm)
            } label: {
                MeasurementLabel(
                    label: model.hasLeanBodyMass ? "lean body mass" : "set lean body mass",
                    valueString: model.lbmFormattedWithUnit,
                    useHealthAppData: isSyncedBinding.wrappedValue
                )
            }
        }
        
        var profileFormButton: some View {
            Button {
                Haptics.feedback(style: .soft)
                present(.profileForm)
            } label: {
                if model.hasRestingEnergyFormulaParameters,
                   let age = model.age,
                   let sex = model.sex,
                   let weight = model.weight
                {
                    ProfileLabel(
                        age: age,
                        sex: sex,
                        weight: weight,
                        height: model.height,
                        bodyMassUnit: UserManager.bodyMassUnit,
                        heightUnit: UserManager.heightUnit,
                        isSynced: model.restingEnergyFormulaParametersAreSynced
                    )
                    .fixedSize(horizontal: true, vertical: false)
                } else {
                    MeasurementLabel(
                        label: "set parameters",
                        valueString: "",
                        useHealthAppData: false
                    )
                }
            }
        }
        
        var prefixString: some View {
            Text(model.restingEnergyFormula == .katchMcardle ? "with" : "as")
                .foregroundColor(Color(.tertiaryLabel))
//                .frame(height: 25)
//                .frame(maxHeight: .infinity)
                .padding(.vertical, 5)
                .padding(.bottom, 2)

        }
        
        @ViewBuilder
        var link: some View {
            if model.restingEnergyFormula.usesLeanBodyMass {
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
    
    func tappedFormula() {
        model.changeRestingEnergySource(to: .formula)
    }

    var emptyContent: some View {
        HStack {
            BiometricButton(healthTitle: "Sync", action: tappedSyncWithHealth)
            BiometricButton("Calculate", systemImage: "function", action: tappedFormula)
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
        var periodTypeMenu: some View {
           Menu {
               Picker(selection: model.restingEnergyPeriodBinding, label: EmptyView()) {
                    ForEach(HealthPeriodType.allCases, id: \.self) {
                        Text($0.pickerDescription).tag($0)
                    }
                }
            } label: {
                BiometricPickerLabel(
                    model.restingEnergyInterval.periodType.menuDescription
                )
//                PickerLabel(
//                    model.restingEnergyInterval.periodType.menuDescription,
//                    imageColor: .green,
//                    backgroundColor: .green,
//                    foregroundColor: .green
//                )
                .animation(.none, value: model.restingEnergyInterval)
                .fixedSize(horizontal: true, vertical: false)
            }
            .contentShape(Rectangle())
            .simultaneousGesture(TapGesture().onEnded {
                Haptics.feedback(style: .soft)
            })

        }
        
        var periodValueMenu: some View {
            Menu {
                Picker(selection: model.restingEnergyIntervalValueBinding, label: EmptyView()) {
                    ForEach(model.restingEnergyIntervalValues, id: \.self) { quantity in
                        Text("\(quantity)").tag(quantity)
                    }
                }
            } label: {
                BiometricPickerLabel(
                    "\(model.restingEnergyInterval.value)"
                )
//                PickerLabel(
//                    "\(model.restingEnergyInterval.value)",
//                    imageColor: .green,
//                    backgroundColor: .green,
//                    foregroundColor: .green
//                )
                .animation(.none, value: model.restingEnergyInterval)
                .fixedSize(horizontal: true, vertical: false)
            }
            .contentShape(Rectangle())
            .simultaneousGesture(TapGesture().onEnded {
                Haptics.feedback(style: .soft)
            })

        }
        
        var periodIntervalMenu: some View {
            Menu {
                Picker(selection: model.restingEnergyIntervalBinding, label: EmptyView()) {
                    ForEach(HealthPeriod.allCases, id: \.self) { interval in
                        Text("\(interval.description)\(model.restingEnergyInterval.value > 1 ? "s" : "")").tag(interval)
                    }
                }
            } label: {
                BiometricPickerLabel(
                    "\(model.restingEnergyInterval.period.description)\(model.restingEnergyInterval.value > 1 ? "s" : "")"
                )
//                PickerLabel(
//                    "\(model.restingEnergyInterval.period.description)\(model.restingEnergyInterval.value > 1 ? "s" : "")",
//                    imageColor: .green,
//                    backgroundColor: .green,
//                    foregroundColor: .green
//                )
                .animation(.none, value: model.restingEnergyInterval)
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
                    periodValueMenu
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
                    periodTypeMenu
                }
                Spacer()
            }
            if model.restingEnergyInterval.periodType == .average {
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
