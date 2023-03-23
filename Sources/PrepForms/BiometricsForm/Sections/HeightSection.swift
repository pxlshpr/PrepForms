import SwiftUI
import SwiftHaptics
import PrepDataTypes
import ActivityIndicatorView
import SwiftUISugar
import PrepCoreDataStack

struct HeightSection: View {
    
    @EnvironmentObject var model: BiometricsModel
    @State var showFormOnAppear = false

    var body: some View {
        FormStyledSection(header: header) {
            content
        }
    }

    var content: some View {
        VStack {
            Group {
                if let source = model.heightSource {
                    Group {
                        sourceSection
                        switch source {
                        case .health:
                            EmptyView()
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

   var header: some View {
       BiometricSectionHeader(type: .height)
           .environmentObject(model)
   }

    func tappedSyncWithHealth() {
        model.changeHeightSource(to: .health)
    }
    
    func tappedManualEntry() {
        showFormOnAppear = true
        model.changeHeightSource(to: .userEntered)
    }
    
    var emptyContent: some View {
        HStack {
            BiometricButton(healthTitle: "Sync", action: tappedSyncWithHealth)
            BiometricButton("Enter", systemImage: "keyboard", action: tappedManualEntry)
        }
    }

    var bottomRow: some View {
        let valueBinding = Binding<BiometricValue?>(
            get: { model.heightBiometricValue },
            set: { newValue in
                guard let heightUnit = newValue?.unit?.heightUnit else { return }
                model.height = newValue?.double
                UserManager.heightUnit = heightUnit
                
                /// Delay this by a second so that the core-data persistence doesn't interfere with
                /// the change of energy unit
                model.saveBiometrics(afterDelay: true)
            }
        )
        
        return HStack {
            BiometricValueRow(
                value: valueBinding,
                type: .height,
                source: model.heightSource ?? .userEntered,
                syncStatus: model.heightSyncStatus,
                prefix: model.heightDateFormatted,
                showFormOnAppear: $showFormOnAppear
            )
        }
    }
    
    @State var showingSourcePicker = false
    
    var sourceSection: some View {
        var label: some View {
            BiometricSourcePickerLabel(source: model.heightSourceBinding.wrappedValue)
        }
        
        var sourcePickerSheet: some View {
            PickerSheet(
                title: "Choose a Source",
                items: MeasurementSource.pickerItems,
                pickedItem: model.heightSource?.pickerItem,
                didPick: {
                    Haptics.feedback(style: .soft)
                    guard let pickedSource = MeasurementSource(pickerItem: $0) else { return }
                    model.changeHeightSource(to: pickedSource)
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
    }
}

extension MeasurementSource {
    static var pickerItems: [PickerItem] {
        allCases.map { $0.pickerItem }
    }
    
    init?(pickerItem: PickerItem) {
        guard let int16 = Int16(pickerItem.id),
              let source = MeasurementSource(rawValue: int16) else {
            return nil
        }
        self = source
    }
    
    var pickerItem: PickerItem {
        PickerItem(
            id: "\(self.rawValue)",
            title: pickerDescription,
            detail: nil,
            secondaryDetail: pickerDetail,
            systemImage: systemImage
        )
    }
    
    var pickerDetail: String {
        switch self {
        case .health:
            return "Updates automatically."
        case .userEntered:
            return "You will need to manually update this."
        }
    }
}

extension LeanBodyMassSource {
    static var pickerItems: [PickerItem] {
        allCases.map { $0.pickerItem }
    }
    
    init?(pickerItem: PickerItem) {
        guard let int16 = Int16(pickerItem.id),
              let source = LeanBodyMassSource(rawValue: int16) else {
            return nil
        }
        self = source
    }
    
    var pickerItem: PickerItem {
        PickerItem(
            id: "\(self.rawValue)",
            title: pickerDescription,
            detail: nil,
            secondaryDetail: pickerDetail,
            systemImage: systemImage
        )
    }
    
    var pickerDetail: String {
        switch self {
        case .fatPercentage:
            return "Calculate using your fat percentage."
        case .formula:
            return "Calculate using a formula."
        case .health:
            return "Updates automatically."
        case .userEntered:
            return "You will need to manually update this."
        }
    }
}

extension ActiveEnergySource {
    static var pickerItems: [PickerItem] {
        allCases.map { $0.pickerItem }
    }
    
    init?(pickerItem: PickerItem) {
        guard let int16 = Int16(pickerItem.id),
              let source = ActiveEnergySource(rawValue: int16) else {
            return nil
        }
        self = source
    }
    
    var pickerItem: PickerItem {
        PickerItem(
            id: "\(self.rawValue)",
            title: pickerDescription,
            detail: nil,
            secondaryDetail: pickerDetail,
            systemImage: systemImage
        )
    }
    
    var pickerDetail: String {
        switch self {
        case .activityLevel:
            return "Calculate by choosing how active you are on a scale."
        case .health:
            return "Updates automatically."
        case .userEntered:
            return "You will need to manually update this."
        }
    }
}

extension RestingEnergySource {
    static var pickerItems: [PickerItem] {
        allCases.map { $0.pickerItem }
    }
    
    init?(pickerItem: PickerItem) {
        guard let int16 = Int16(pickerItem.id),
              let source = RestingEnergySource(rawValue: int16) else {
            return nil
        }
        self = source
    }
    
    var pickerItem: PickerItem {
        PickerItem(
            id: "\(self.rawValue)",
            title: pickerDescription,
            detail: nil,
            secondaryDetail: pickerDetail,
            systemImage: systemImage,
            colorStyle: colorStyle
        )
    }
    
    var colorStyle: PickerItem.ColorStyle? {
        switch self {
        case .health:
            return .gradient(HealthTopColor, HealthBottomColor)
        default:
            return nil
        }
    }
    
    var pickerDetail: String {
        switch self {
        case .formula:
            return "Calculate using a formula."
        case .health:
            return "Updates automatically."
        case .userEntered:
            return "You will need to manually update this."
        }
    }
}
