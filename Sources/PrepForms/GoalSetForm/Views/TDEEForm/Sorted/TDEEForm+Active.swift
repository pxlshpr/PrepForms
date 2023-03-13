import SwiftUI
import SwiftUISugar
import SwiftHaptics
import PrepDataTypes
import ActivityIndicatorView
import PrepCoreDataStack

extension TDEEForm {

    var activeEnergySection: some View {
        ActiveEnergySection()
            .environmentObject(model)
    }
    
    var activeEnergySection_legacy: some View {
        
        var sourceSection: some View {
            var sourceMenu: some View {
                Menu {
                    Picker(selection: model.activeEnergySourceBinding, label: EmptyView()) {
                        ForEach(ActiveEnergySource.allCases, id: \.self) {
                            Label($0.menuDescription, systemImage: $0.systemImage).tag($0)
                        }
                    }
                } label: {
                    BiometricSourcePickerLabel(source: model.activeEnergySourceBinding.wrappedValue)
                }
                .animation(.none, value: model.activeEnergySource)
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
        
        var healthPeriodContent: some View {
            var periodTypeMenu: some View {
               Menu {
                   Picker(selection: model.activeEnergyPeriodBinding, label: EmptyView()) {
                        ForEach(HealthPeriodType.allCases, id: \.self) {
                            Text($0.pickerDescription).tag($0)
                        }
                    }
                } label: {
                    PickerLabel(
                        model.activeEnergyPeriod.menuDescription,
                        imageColor: Color(hex: "F3DED7"),
                        backgroundGradientTop: HealthTopColor,
                        backgroundGradientBottom: HealthBottomColor,
                        foregroundColor: .white
                    )
                    .animation(.none, value: model.activeEnergyPeriod)
                    .fixedSize(horizontal: true, vertical: false)
                }
                .contentShape(Rectangle())
                .simultaneousGesture(TapGesture().onEnded {
                    Haptics.feedback(style: .soft)
                })
            }
            
            var periodValueMenu: some View {
                Menu {
                    Picker(selection: model.activeEnergyIntervalValueBinding, label: EmptyView()) {
                        ForEach(model.activeEnergyIntervalValues, id: \.self) { quantity in
                            Text("\(quantity)").tag(quantity)
                        }
                    }
                } label: {
                    PickerLabel(
                        "\(model.activeEnergyIntervalValue)",
                        imageColor: Color(hex: "F3DED7"),
                        backgroundGradientTop: HealthTopColor,
                        backgroundGradientBottom: HealthBottomColor,
                        foregroundColor: .white
                    )
                    .animation(.none, value: model.activeEnergyIntervalValue)
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
                    Picker(selection: model.activeEnergyIntervalBinding, label: EmptyView()) {
                        ForEach(HealthPeriod.allCases, id: \.self) { interval in
                            Text("\(interval.description)\(model.activeEnergyIntervalValue > 1 ? "s" : "")").tag(interval)
                        }
                    }
                } label: {
                    PickerLabel(
                        "\(model.activeEnergyInterval.description)\(model.activeEnergyIntervalValue > 1 ? "s" : "")",
                        imageColor: Color(hex: "F3DED7"),
                        backgroundGradientTop: HealthTopColor,
                        backgroundGradientBottom: HealthBottomColor,
                        foregroundColor: .white
                    )
                    .animation(.none, value: model.activeEnergyInterval)
                    .animation(.none, value: model.activeEnergyIntervalValue)
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
                if model.activeEnergyPeriod == .average {
                    intervalRow
                }
            }
        }
        
        
        var healthContent: some View {
//            Group {
//                switch model.activeEnergyFetchStatus {
//                case .noData:
//                    healthPeriodContent
//                case .noDataOrNotAuthorized:
////                    Text("No Data or Not Authorized")
//                    healthPeriodContent
////                    permissionRequiredContent
//                case .notFetched, .fetching:
//                    EmptyView()
//                case .fetched:
//                    healthPeriodContent
//                }
//            }
            healthPeriodContent
            .padding()
            .padding(.horizontal)
        }
        
        var energyRow: some View {
//            @ViewBuilder
//            var healthContent: some View {
//                switch model.activeEnergyFetchStatus {
//                case .noData:
//                    Text("No Data")
//                case .noDataOrNotAuthorized:
//                    Text("No Data or Not Authorized")
//                case .notFetched, .fetching, .fetched:
//                    HStack {
//                        Spacer()
//                        if model.activeEnergyFetchStatus == .fetching {
//                            ActivityIndicatorView(isVisible: .constant(true), type: .opacityDots())
//                                .frame(width: 25, height: 25)
//                                .foregroundColor(.secondary)
//                        } else {
//                            if let prefix = model.activeEnergyPrefix {
//                                Text(prefix)
//                                    .font(.subheadline)
//                                    .foregroundColor(Color(.tertiaryLabel))
//                            }
//                            Text(model.activeEnergyFormatted)
//                                .font(.system(.title3, design: .rounded, weight: .semibold))
//                                .multilineTextAlignment(.trailing)
//                                .foregroundColor(model.activeEnergySource == .userEntered ? .primary : .secondary)
//                                .fixedSize(horizontal: false, vertical: true)
//                                .matchedGeometryEffect(id: "active", in: namespace)
//                                .if(!model.hasActiveEnergy) { view in
//                                    view
//                                        .redacted(reason: .placeholder)
//                                }
//                            Text(model.userEnergyUnit.shortDescription)
//                                .foregroundColor(.secondary)
//                        }
//                    }
//                }
//            }
//
//            var manualEntry: some View {
//                HStack {
//                    Spacer()
//                    TextField("energy in", text: model.activeEnergyTextFieldStringBinding)
//                        .keyboardType(.decimalPad)
//                        .focused($activeEnergyTextFieldIsFocused)
//                        .multilineTextAlignment(.trailing)
//                        .font(.system(.title3, design: .rounded, weight: .semibold))
////                        .fixedSize(horizontal: false, vertical: true)
//                        .matchedGeometryEffect(id: "active", in: namespace)
//                    Text(model.userEnergyUnit.shortDescription)
//                        .foregroundColor(.secondary)
//                }
//            }
//
//            var activityLevel: some View {
//                HStack {
//                    Spacer()
//                    Text(model.activeEnergyFormatted)
//                        .font(.system(.title3, design: .rounded, weight: .semibold))
//                        .foregroundColor(.secondary)
//                        .multilineTextAlignment(.trailing)
//                        .fixedSize(horizontal: false, vertical: true)
//                        .matchedGeometryEffect(id: "active", in: namespace)
//                        .if(!model.hasActiveEnergy) { view in
//                            view
//                                .redacted(reason: .placeholder)
//                        }
//                    Text(model.userEnergyUnit.shortDescription)
//                        .foregroundColor(.secondary)
//                }
//            }
//
//            return Group {
//                switch model.activeEnergySource {
//                case .health:
//                    healthContent
//                case .activityLevel:
//                    activityLevel
//                case .userEntered:
//                    manualEntry
//                default:
//                    EmptyView()
//                }
//            }
            
            let valueBinding = Binding<BiometricValue?>(
                get: {
                    model.activeEnergyBiometricValue
                },
                set: { newValue in
                    model.activeEnergy = newValue?.double
                    
                    if let energyUnit = newValue?.unit?.energyUnit {
                        
                        /// Convert other energy based values in `BiometricModel` before setting the unit
                        if let restingEnergy = model.restingEnergy {
                            model.restingEnergy = model.userEnergyUnit.convert(restingEnergy, to: energyUnit)
                        }
                        model.userEnergyUnit = energyUnit
                        UserManager.energyUnit = energyUnit
                    }
                }
            )
            
            return BiometricValueRow(
                value: valueBinding,
                type: .activeEnergy,
                source: model.activeEnergySource ?? .userEntered,
                syncStatus: model.activeEnergySyncStatus,
                prefix: model.activeEnergyPrefix,
                matchedGeometryId: "active",
                matchedGeometryNamespace: namespace
            )
            .padding(.trailing)
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
//                    PickerLabel(
//                        model.activeEnergyFormula.year,
//                        prefix: model.activeEnergyFormula.menuDescription,
//                        foregroundColor: .secondary,
//                        prefixColor: .primary
//                    )
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
                            energyRow
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
            model.changeActiveEnergySource(to: .userEntered)
            activeEnergyTextFieldIsFocused = true
        }

        func tappedSyncWithHealth() {
            Task(priority: .high) {
                do {
                    try await HealthKitManager.shared.requestPermission(for: .activeEnergyBurned)
                    withAnimation {
                        model.activeEnergySource = .health
                    }
                    model.fetchActiveEnergyFromHealth()
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
        
        var activeHeader: some View {
            HStack {
                Image(systemName: EnergyComponent.active.systemImage)
                    .matchedGeometryEffect(id: "active-header-icon", in: namespace)
                Text("Active Energy")
            }
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
        
        return VStack(spacing: 7) {
            activeHeader
                .textCase(.uppercase)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(Color(.secondaryLabel))
                .font(.footnote)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            content
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 0)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(Color(.secondarySystemGroupedBackground))
                        .matchedGeometryEffect(id: "active-bg", in: namespace)
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
}
