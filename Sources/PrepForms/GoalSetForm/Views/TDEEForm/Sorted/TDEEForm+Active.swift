import SwiftUI
import SwiftUISugar
import SwiftHaptics
import PrepDataTypes
import ActivityIndicatorView

extension TDEEForm {
    
    var activeEnergySection: some View {
        
        var sourceSection: some View {
            var sourceMenu: some View {
                Menu {
                    Picker(selection: viewModel.activeEnergySourceBinding, label: EmptyView()) {
                        ForEach(ActiveEnergySource.allCases, id: \.self) {
                            Label($0.menuDescription, systemImage: $0.systemImage).tag($0)
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        HStack {
                            if viewModel.activeEnergySource == .healthApp {
                                appleHealthSymbol
                            } else {
                                if let systemImage = viewModel.activeEnergySource?.systemImage {
                                    Image(systemName: systemImage)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Text(viewModel.activeEnergySource?.pickerDescription ?? "")
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        Image(systemName: "chevron.up.chevron.down")
                            .imageScale(.small)
                    }
                    .foregroundColor(.secondary)
                    .animation(.none, value: viewModel.activeEnergySource)
                    .fixedSize(horizontal: true, vertical: false)
                }
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
                   Picker(selection: viewModel.activeEnergyPeriodBinding, label: EmptyView()) {
                        ForEach(HealthPeriodOption.allCases, id: \.self) {
                            Text($0.pickerDescription).tag($0)
                        }
                    }
                } label: {
                    PickerLabel(
                        viewModel.activeEnergyPeriod.menuDescription,
                        imageColor: Color(hex: "F3DED7"),
                        backgroundGradientTop: Color(hex: AppleHealthTopColorHex),
                        backgroundGradientBottom: Color(hex: AppleHealthBottomColorHex),
                        foregroundColor: .white
                    )
                    .animation(.none, value: viewModel.activeEnergyPeriod)
                    .fixedSize(horizontal: true, vertical: false)
                }
            }
            
            var periodValueMenu: some View {
                Menu {
                    Picker(selection: viewModel.activeEnergyIntervalValueBinding, label: EmptyView()) {
                        ForEach(viewModel.activeEnergyIntervalValues, id: \.self) { quantity in
                            Text("\(quantity)").tag(quantity)
                        }
                    }
                } label: {
                    PickerLabel(
                        "\(viewModel.activeEnergyIntervalValue)",
                        imageColor: Color(hex: "F3DED7"),
                        backgroundGradientTop: Color(hex: AppleHealthTopColorHex),
                        backgroundGradientBottom: Color(hex: AppleHealthBottomColorHex),
                        foregroundColor: .white
                    )
                    .animation(.none, value: viewModel.activeEnergyIntervalValue)
                    .animation(.none, value: viewModel.activeEnergyInterval)
                    .fixedSize(horizontal: true, vertical: false)
                }
            }
            
            var periodIntervalMenu: some View {
                Menu {
                    Picker(selection: viewModel.activeEnergyIntervalBinding, label: EmptyView()) {
                        ForEach(HealthAppInterval.allCases, id: \.self) { interval in
                            Text("\(interval.description)\(viewModel.activeEnergyIntervalValue > 1 ? "s" : "")").tag(interval)
                        }
                    }
                } label: {
                    PickerLabel(
                        "\(viewModel.activeEnergyInterval.description)\(viewModel.activeEnergyIntervalValue > 1 ? "s" : "")",
                        imageColor: Color(hex: "F3DED7"),
                        backgroundGradientTop: Color(hex: AppleHealthTopColorHex),
                        backgroundGradientBottom: Color(hex: AppleHealthBottomColorHex),
                        foregroundColor: .white
                    )
                    .animation(.none, value: viewModel.activeEnergyInterval)
                    .animation(.none, value: viewModel.activeEnergyIntervalValue)
                    .fixedSize(horizontal: true, vertical: false)
                }
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
                if viewModel.activeEnergyPeriod == .average {
                    intervalRow
                }
            }
        }
        
        
        var healthContent: some View {
            Group {
                if viewModel.activeEnergyFetchStatus == .notAuthorized {
                    permissionRequiredContent
                } else {
                    healthPeriodContent
                }
            }
            .padding()
            .padding(.horizontal)
        }
        
        var energyRow: some View {
            @ViewBuilder
            var health: some View {
                if viewModel.activeEnergyFetchStatus != .notAuthorized {
                    HStack {
                        Spacer()
                        if viewModel.activeEnergyFetchStatus == .fetching {
                            ActivityIndicatorView(isVisible: .constant(true), type: .opacityDots())
                                .frame(width: 25, height: 25)
                                .foregroundColor(.secondary)
                        } else {
                            if let prefix = viewModel.activeEnergyPrefix {
                                Text(prefix)
                                    .font(.subheadline)
                                    .foregroundColor(Color(.tertiaryLabel))
                            }
                            Text(viewModel.activeEnergyFormatted)
                                .font(.system(.title3, design: .rounded, weight: .semibold))
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(viewModel.activeEnergySource == .userEntered ? .primary : .secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .matchedGeometryEffect(id: "active", in: namespace)
                                .if(!viewModel.hasActiveEnergy) { view in
                                    view
                                        .redacted(reason: .placeholder)
                                }
                            Text(viewModel.userEnergyUnit.shortDescription)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            var manualEntry: some View {
                HStack {
                    Spacer()
                    TextField("energy in", text: viewModel.activeEnergyTextFieldStringBinding)
                        .keyboardType(.decimalPad)
                        .focused($activeEnergyTextFieldIsFocused)
                        .multilineTextAlignment(.trailing)
                        .font(.system(.title3, design: .rounded, weight: .semibold))
//                        .fixedSize(horizontal: false, vertical: true)
                        .matchedGeometryEffect(id: "active", in: namespace)
                    Text(viewModel.userEnergyUnit.shortDescription)
                        .foregroundColor(.secondary)
                }
            }
            
            var activityLevel: some View {
                HStack {
                    Spacer()
                    Text(viewModel.activeEnergyFormatted)
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                        .matchedGeometryEffect(id: "active", in: namespace)
                        .if(!viewModel.hasActiveEnergy) { view in
                            view
                                .redacted(reason: .placeholder)
                        }
                    Text(viewModel.userEnergyUnit.shortDescription)
                        .foregroundColor(.secondary)
                }
            }
            
            return Group {
                switch viewModel.activeEnergySource {
                case .healthApp:
                    health
                case .activityLevel:
                    activityLevel
                case .userEntered:
                    manualEntry
                default:
                    EmptyView()
                }
            }
            .padding(.trailing)
        }
        
        var activityLevelContent: some View {
            var menu: some View {
                Menu {
                    Picker(selection: viewModel.activeEnergyActivityLevelBinding, label: EmptyView()) {
                        ForEach(ActivityLevel.allCases, id: \.self) {
                            Text($0.description).tag($0)
                        }
                    }
                } label: {
//                    PickerLabel(
//                        viewModel.activeEnergyFormula.year,
//                        prefix: viewModel.activeEnergyFormula.menuDescription,
//                        foregroundColor: .secondary,
//                        prefixColor: .primary
//                    )
                    PickerLabel(viewModel.activeEnergyActivityLevel.description)
                    .animation(.none, value: viewModel.activeEnergyActivityLevel)
                    .fixedSize(horizontal: true, vertical: false)
                }
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
                    if let source = viewModel.activeEnergySource {
                        Group {
                            sourceSection
                            switch source {
                            case .healthApp:
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
            viewModel.changeActiveEnergySource(to: .activityLevel)
        }

        func tappedManualEntry() {
            viewModel.changeActiveEnergySource(to: .userEntered)
            activeEnergyTextFieldIsFocused = true
        }

        func tappedSyncWithHealth() {
            Task(priority: .high) {
                do {
                    try await HealthKitManager.shared.requestPermission(for: .activeEnergyBurned)
                    withAnimation {
                        viewModel.activeEnergySource = .healthApp
                    }
                    viewModel.fetchActiveEnergyFromHealth()
                } catch {
                    cprint("Error syncing with Health: \(error)")
                }
            }
        }
        
        var emptyContent: some View {
//            VStack(spacing: 10) {
//                emptyButton("Sync with Health app", showHealthAppIcon: true, action: tappedSyncWithHealth)
//                emptyButton("Apply Activity Multiplier", systemImage: "dial.medium.fill")
//                emptyButton("Let me type it in", systemImage: "keyboard")
//            }
//            HStack {
//                emptyButton2("Sync", showHealthAppIcon: true, action: tappedSyncWithHealth)
//                emptyButton2("Activity Level", systemImage: "dial.medium.fill")
//                emptyButton2("Enter", systemImage: "keyboard")
//            }
            FlowView(alignment: .center, spacing: 10, padding: 37) {
                emptyButton2("Sync with Health App", showHealthAppIcon: true, action: tappedSyncWithHealth)
                emptyButton2("Activity Level", systemImage: "dial.medium.fill", action: tappedActivityLevel)
                emptyButton2("Enter Manually", systemImage: "keyboard", action: tappedManualEntry)
            }
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
            if let string = viewModel.activeEnergyFooterString {
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
                .if(viewModel.activeEnergyFooterString == nil) { view in
                    view.padding(.bottom, 10)
                }
            footer
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
}
