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
    let showSourcePicker: () -> ()

    init(includeFooter: Bool = false, showSourcePicker: @escaping () -> ()) {
        self.includeFooter = includeFooter
        self.showSourcePicker = showSourcePicker
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
                withAnimation {
                    model.sex = newValue?.sex?.hkBiologicalSex
                }
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

        var pickerButton: some View {
            Button {
                Haptics.feedback(style: .soft)
                showSourcePicker()
            } label: {
                label
            }
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
