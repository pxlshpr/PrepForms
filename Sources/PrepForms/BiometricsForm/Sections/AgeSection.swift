import SwiftUI
import SwiftHaptics
import PrepDataTypes
import ActivityIndicatorView
import SwiftUISugar
import HealthKit

struct AgeSection: View {
    
    @EnvironmentObject var model: BiometricsModel
    @State var showFormOnAppear = false
    let showSourcePicker: () -> ()

    var body: some View {
        FormStyledSection(header: header) {
            content
        }
    }

    var content: some View {
        VStack {
            Group {
                if let source = model.ageSource {
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
        model.changeAgeSource(to: .health)
    }
    
    func tappedManualEntry() {
        showFormOnAppear = true
        model.changeAgeSource(to: .userEntered)
    }
    
    var emptyContent: some View {
        HStack {
            BiometricButton(healthTitle: "Sync", action: tappedSyncWithHealth)
            BiometricButton("Enter", systemImage: "keyboard", action: tappedManualEntry)
        }
    }

    var bottomRow: some View {
        let valueBinding = Binding<BiometricValue?>(
            get: {
                model.ageBiometricValue
            },
            set: { newValue in
                model.age = newValue?.age
                model.saveBiometrics()
            }
        )
        
        return HStack {
            BiometricValueRow(
                value: valueBinding,
                type: .age,
                source: model.ageSource ?? .userEntered,
                syncStatus: model.dobSyncStatus,
                prefix: nil,
                showFormOnAppear: $showFormOnAppear
            )
        }
    }
    
    var sourceSection: some View {
        
        var label: some View {
            BiometricSourcePickerLabel(source: model.ageSourceBinding.wrappedValue)
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
        BiometricSectionHeader(type: .age)
            .environmentObject(model)
    }
}
