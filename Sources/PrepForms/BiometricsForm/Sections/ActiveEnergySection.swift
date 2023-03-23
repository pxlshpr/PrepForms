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
    @State var presentedSheet: Sheet? = nil

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
//                .padding(.bottom, 10)
                .if(model.activeEnergyFooterString == nil) { view in
                    view.padding(.bottom, 10)
                }
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
        case .intervalTypePicker:
            intervalTypePickerSheet
        case .intervalPeriodPicker:
            intervalPeriodPickerSheet
        case .intervalValuePicker:
            intervalValuePickerSheet
        case .activityLevelPicker:
            activityLevelPickerSheet
        }
    }
    
    var intervalTypePickerSheet: some View {
        PickerSheet(
            title: "Choose a value",
            items: HealthIntervalType.pickerItems,
            pickedItem: model.activeEnergyInterval.intervalType.pickerItem,
            didPick: {
                Haptics.feedback(style: .soft)
                guard let pickedType = HealthIntervalType(pickerItem: $0) else { return }
                model.changeActiveEnergyIntervalType(to: pickedType)
            }
        )
    }

    var intervalPeriodPickerSheet: some View {
        PickerSheet(
            title: "Duration to average",
            items: HealthPeriod.pickerItems,
            pickedItem: model.activeEnergyInterval.period.pickerItem,
            didPick: {
                Haptics.feedback(style: .soft)
                guard let pickedPeriod = HealthPeriod(pickerItem: $0) else { return }
                model.changeActiveEnergyIntervalPeriod(to: pickedPeriod)
            }
        )
    }
    
    var activityLevelPickerSheet: some View {
        PickerSheet(
            title: "Activity Level",
            items: ActivityLevel.pickerItems,
            pickedItem: model.activeEnergyActivityLevel.pickerItem,
            didPick: {
                Haptics.feedback(style: .soft)
                guard let pickedLevel = ActivityLevel(pickerItem: $0) else { return }
                model.changeActiveEnergyActivityLevel(to: pickedLevel)
            }
        )
    }
    
    var intervalValuePickerSheet: some View {
        var items: [PickerItem] {
            model.activeEnergyIntervalValues.map { PickerItem(with: $0) }
        }
        
        return PickerSheet(
            title: "\(model.activeEnergyInterval.period.description.capitalizingFirstLetter())s to average",
            items: items,
            pickedItem: PickerItem(with: model.activeEnergyInterval.value),
            didPick: {
                Haptics.feedback(style: .soft)
                guard let value = Int($0.id) else { return }
                model.changeActiveEnergyIntervalValue(to: value)
            }
        )
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
    

    var header: some View {
        BiometricSectionHeader(type: .activeEnergy)
            .environmentObject(model)
            .padding(.horizontal, 20)
    }

    var sourceSection: some View {
        var pickerButton: some View {
            Button {
                Haptics.feedback(style: .soft)
                present(.sourcePicker)
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

    var healthPeriodContent: some View {
        var intervalTypeMenu: some View {
            Button {
                Haptics.feedback(style: .soft)
                present(.intervalTypePicker)
            } label: {
                BiometricPickerLabel(model.activeEnergyInterval.intervalType.menuDescription)
            }
        }
        
        var periodIntervalMenu: some View {
            Button {
                Haptics.feedback(style: .soft)
                present(.intervalPeriodPicker)
            } label: {
                BiometricPickerLabel(
                    "\(model.activeEnergyInterval.period.description)\(model.activeEnergyInterval.value > 1 ? "s" : "")"
                )
            }
        }
        
        
        var intervalValueMenu: some View {
            Button {
                Haptics.feedback(style: .soft)
                present(.intervalValuePicker)
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

//    var healthPeriodContent_legacy: some View {
//        var intervalTypeMenu: some View {
//           Menu {
//               Picker(selection: model.activeEnergyIntervalTypeBinding, label: EmptyView()) {
//                    ForEach(HealthIntervalType.allCases, id: \.self) {
//                        Text($0.pickerDescription).tag($0)
//                    }
//                }
//            } label: {
//                PickerLabel(
//                    model.activeEnergyInterval.intervalType.menuDescription,
//                    imageColor: .green,
//                    backgroundColor: .green,
//                    foregroundColor: .green
//                )
//                .animation(.none, value: model.activeEnergyInterval)
//                .fixedSize(horizontal: true, vertical: false)
//            }
//            .contentShape(Rectangle())
//            .simultaneousGesture(TapGesture().onEnded {
//                Haptics.feedback(style: .soft)
//            })
//        }
//
//        var intervalValueMenu: some View {
//            Menu {
//                Picker(selection: model.activeEnergyIntervalValueBinding, label: EmptyView()) {
//                    ForEach(model.activeEnergyIntervalValues, id: \.self) { quantity in
//                        Text("\(quantity)").tag(quantity)
//                    }
//                }
//            } label: {
//                PickerLabel(
//                    "\(model.activeEnergyInterval.value)",
//                    imageColor: .green,
//                    backgroundColor: .green,
//                    foregroundColor: .green
//                )
//                .animation(.none, value: model.activeEnergyInterval)
//                .fixedSize(horizontal: true, vertical: false)
//            }
//            .contentShape(Rectangle())
//            .simultaneousGesture(TapGesture().onEnded {
//                Haptics.feedback(style: .soft)
//            })
//        }
//
//        var periodIntervalMenu: some View {
//            Menu {
//                Picker(selection: model.activeEnergyIntervalPeriodBinding, label: EmptyView()) {
//                    ForEach(HealthPeriod.allCases, id: \.self) { interval in
//                        Text("\(interval.description)\(model.activeEnergyInterval.value > 1 ? "s" : "")").tag(interval)
//                    }
//                }
//            } label: {
//                PickerLabel(
//                    "\(model.activeEnergyInterval.period.description)\(model.activeEnergyInterval.value > 1 ? "s" : "")",
//                    imageColor: .green,
//                    backgroundColor: .green,
//                    foregroundColor: .green
//                )
//                .animation(.none, value: model.activeEnergyInterval)
//                .fixedSize(horizontal: true, vertical: false)
//            }
//            .contentShape(Rectangle())
//            .simultaneousGesture(TapGesture().onEnded {
//                Haptics.feedback(style: .soft)
//            })
//        }
//
//        var intervalRow: some View {
//            HStack {
//                Spacer()
//                HStack(spacing: 5) {
//                    Text("previous")
//                        .foregroundColor(Color(.tertiaryLabel))
//                    intervalValueMenu
//                    periodIntervalMenu
//                }
//                Spacer()
//            }
//        }
//
//        return VStack(spacing: 5) {
//            HStack {
//                Spacer()
//                HStack {
//                    Text("using")
//                        .foregroundColor(Color(.tertiaryLabel))
//                    intervalTypeMenu
//                }
//                Spacer()
//            }
//            if model.activeEnergyInterval.intervalType == .average {
//                intervalRow
//            }
//        }
//    }
    
    
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
                present(.activityLevelPicker)
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
    
    enum Sheet: String, Identifiable {
        case sourcePicker
        case intervalTypePicker
        case intervalPeriodPicker
        case intervalValuePicker
        case activityLevelPicker
        
        var id: String { rawValue }
    }
}


extension ActivityLevel {
    static var pickerItems: [PickerItem] {
        allCases
            .map { $0.pickerItem }
    }
    
    init?(pickerItem: PickerItem) {
        guard let int16 = Int16(pickerItem.id),
              let source = ActivityLevel(rawValue: int16) else {
            return nil
        }
        self = source
    }
    
    var pickerItem: PickerItem {
        PickerItem(
            id: "\(self.rawValue)",
            title: pickerTitle,
            detail: pickerDetail,
            secondaryDetail: pickerSecondaryDetail
        )
    }
    
    var pickerTitle: String {
        description
    }

    var pickerDetail: String? {
        nil
    }

    var pickerSecondaryDetail: String? {
        switch self {
        case .notSet:
            return "Using this will assign 0 \(UserManager.energyUnit.shortDescription) as your active \(UserManager.energyDescription.lowercased()) component."
        case .sedentary:
            return "Little or no exercise, working a desk job."
        case .lightlyActive:
            return "Light exercise 1-2 days / week."
        case .moderatelyActive:
            return "Moderate exercise 3-5 days / week."
        case .active:
            return "Heavy exercise 6-7 days / week."
        case .veryActive:
            return "Very heavy exercise 2 or more times per day, hard labor job or training for a marathon, triathlon, etc."
        }
    }
}
