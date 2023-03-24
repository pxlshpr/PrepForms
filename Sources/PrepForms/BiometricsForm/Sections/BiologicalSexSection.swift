import SwiftUI
import SwiftHaptics
import PrepDataTypes
import ActivityIndicatorView
import SwiftUISugar
import HealthKit

struct BiologicalSexSection: View {
    
    let includeFooter: Bool
    @EnvironmentObject var model: BiometricsModel
    @State var showFormOnAppear = false
    @State var showingSourcePicker = false

    init(includeFooter: Bool = false) {
        self.includeFooter = includeFooter
    }
    
    var body: some View {
        FormStyledSection(header: header) {
            content
        }
    }

    var content: some View {
        VStack {
            Group {
                if let source = model.sexSource {
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

    func tappedSyncWithHealth() {
        model.changeSexSource(to: .health)
    }
    
    func tappedManualEntry() {
        model.sex = .female
        showFormOnAppear = true
        model.changeSexSource(to: .userEntered)
    }
    
    var emptyContent: some View {
        HStack {
            BiometricButton(healthTitle: "Sync", action: tappedSyncWithHealth)
            BiometricButton("Choose", systemImage: "hand.tap", action: tappedManualEntry)
        }
    }

    @ViewBuilder
    var footer: some View {
        if includeFooter {
            Text("This is the biological sex used in the equation.")
        }
    }
    
    var bottomRow: some View {
        let valueBinding = Binding<BiometricValue?>(
            get: { model.sexBiometricValue },
            set: { newValue in
                model.sex = newValue?.sex?.hkBiologicalSex
                model.saveBiometrics()
            }
        )
        
        return HStack {
            BiometricValueRow(
                value: valueBinding,
                type: .sex,
                source: model.sexSource ?? .userEntered,
                syncStatus: model.sexSyncStatus,
                prefix: nil,
                showFormOnAppear: $showFormOnAppear
            )
        }
    }
    
    var sourceSection: some View {
        var label: some View {
            let measurementSource = model.sexSource ?? .userEntered
            let measurementSexSource = MeasurementSexSource(rawValue: measurementSource.rawValue) ?? .userEntered
            return BiometricSourcePickerLabel(source: measurementSexSource)
        }
        
        var sourcePickerSheet: some View {
            PickerSheet(
                title: "Choose a Source",
                items: MeasurementSexSource.pickerItems,
                pickedItem: model.sexSource?.pickerItem,
                didPick: {
                    Haptics.feedback(style: .soft)
                    guard let pickedSource = MeasurementSource(pickerItem: $0) else { return }
                    model.changeSexSource(to: pickedSource)
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
    
    var header: some View {
        BiometricSectionHeader(type: .sex)
            .environmentObject(model)
    }
}

public enum MeasurementSexSource: Int16, Codable, CaseIterable {
    case health = 1
    case userEntered
    
    public var menuDescription: String {
        switch self {
        case .health:
            return "Health App"
        case .userEntered:
            return "Choose it"
        }
    }
}

extension MeasurementSexSource: BiometricSource {
    public var isHealthSynced: Bool {
        self == .health
    }
    public var isUserEntered: Bool {
        self == .userEntered
    }
}

extension MeasurementSexSource {
    static var pickerItems: [PickerItem] {
        allCases.map { $0.pickerItem }
    }
    
    init?(pickerItem: PickerItem) {
        guard let int16 = Int16(pickerItem.id),
              let source = MeasurementSexSource(rawValue: int16) else {
            return nil
        }
        self = source
    }
    
    var pickerItem: PickerItem {
        PickerItem(
            id: "\(self.rawValue)",
            title: pickerDescription,
            detail: nil,
            secondaryDetail: nil,
            systemImage: systemImage
        )
    }
    
    public var pickerDescription: String {
        switch self {
        case .health:
            return "Sync with Health App"
        case .userEntered:
            return "Choose it"
        }
    }
    
    public var systemImage: String {
        switch self {
        case .health:
            return "heart.fill"
        case .userEntered:
            return "hand.tap"
        }
    }
}
