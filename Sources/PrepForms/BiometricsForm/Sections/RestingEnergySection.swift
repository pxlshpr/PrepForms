import SwiftUI
import SwiftHaptics
import PrepDataTypes
import ActivityIndicatorView
import SwiftUISugar
import HealthKit
import PrepCoreDataStack

struct UpdatedBadge: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Text("Updated")
            .textCase(.uppercase)
            .font(.footnote)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        HealthGradient
                            .opacity(colorScheme == .dark ? 0.5 : 0.8)
                    )
            )
    }
}
struct RestingEnergySection: View {
    
    @EnvironmentObject var model: BiometricsModel
    
    @Namespace var namespace
    @FocusState var restingEnergyTextFieldIsFocused: Bool
    @State var showFormOnAppear = false
    
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
                .foregroundColor(Color(.secondarySystemGroupedBackground))
                .matchedGeometryEffect(id: "resting-bg", in: namespace)
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

    
    var sourceSection: some View {
        var sourceMenu: some View {
            Menu {
                Picker(selection: model.restingEnergySourceBinding, label: EmptyView()) {
                    ForEach(RestingEnergySource.allCases, id: \.self) {
                        Label($0.menuDescription, systemImage: $0.systemImage).tag($0)
                    }
                }
            } label: {
                BiometricSourcePickerLabel(source: model.restingEnergySourceBinding.wrappedValue)
            }
            .animation(.none, value: model.restingEnergySource)
            .fixedSize(horizontal: true, vertical: false)
            .contentShape(Rectangle())
            .simultaneousGesture(TapGesture().onEnded {
                Haptics.feedback(style: .light)
            })
        }
        
        return HStack {
            sourceMenu
            Spacer()
        }
        .padding(.horizontal, 17)
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
    
    var parametersRow: some View {
        
        var lbmFormLink: some View {
            NavigationLink {
                LeanBodyMassForm()
                    .environmentObject(model)
            } label: {
                MeasurementLabel(
                    label: model.hasLeanBodyMass ? "lean body mass" : "set lean body mass",
                    valueString: model.lbmFormattedWithUnit,
                    useHealthAppData: model.restingEnergyFormulaUsingSyncedHealthData
                )
            }
        }
        
        var parametersFormLink: some View {
            NavigationLink {
                ProfileForm()
                    .environmentObject(model)
            } label: {
                if model.hasMeasurements,
                   let age = model.age,
                   let sex = model.sex,
                   let weight = model.weight
                {
                    ProfileLabel(
                        age: age,
                        sex: sex,
                        weight: weight,
                        height: model.height,
                        bodyMassUnit: model.userBodyMassUnit,
                        heightUnit: model.userHeightUnit,
                        isSynced: model.measurementsAreSynced
                    )
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
                lbmFormLink
            } else {
                parametersFormLink
            }
        }
        
        var flowView: some View {
            return FlowView(alignment: .center, spacing: 10, padding: 17) {
                ZStack {
                    Capsule(style: .continuous)
                        .foregroundColor(Color(.clear))
                    prefixString
                }
                .fixedSize(horizontal: true, vertical: true)
                link
            }
            .padding(.bottom, 5)
        }
        
        var hStack: some View {
            HStack {
                prefixString
                link
            }
        }
        
//        return flowView
        return hStack
    }
    
    func tappedManualEntry() {
        showFormOnAppear = true
        model.changeRestingEnergySource(to: .userEntered)
        restingEnergyTextFieldIsFocused = true
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
                    model.activeEnergy = model.userEnergyUnit.convert(activeEnergy, to: energyUnit)
                }
                model.userEnergyUnit = energyUnit
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
            showFormOnAppear: $showFormOnAppear,
            matchedGeometryId: "resting",
            matchedGeometryNamespace: namespace
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
                PickerLabel(
                    model.restingEnergyInterval.periodType.menuDescription,
                    imageColor: Color(hex: "F3DED7"),
                    backgroundGradientTop: HealthTopColor,
                    backgroundGradientBottom: HealthBottomColor,
                    foregroundColor: .white
                )
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
                PickerLabel(
                    "\(model.restingEnergyInterval.value)",
                    imageColor: Color(hex: "F3DED7"),
                    backgroundGradientTop: HealthTopColor,
                    backgroundGradientBottom: HealthBottomColor,
                    foregroundColor: .white
                )
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
                PickerLabel(
                    "\(model.restingEnergyInterval.period.description)\(model.restingEnergyInterval.value > 1 ? "s" : "")",
                    imageColor: Color(hex: "F3DED7"),
                    backgroundGradientTop: HealthTopColor,
                    backgroundGradientBottom: HealthBottomColor,
                    foregroundColor: .white
                )
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
