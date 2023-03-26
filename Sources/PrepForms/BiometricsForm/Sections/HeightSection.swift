import SwiftUI
import SwiftHaptics
import PrepDataTypes
import ActivityIndicatorView
import SwiftUISugar
import PrepCoreDataStack

struct HeightSection: View {
    
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
    
    var sourceSection: some View {
        var label: some View {
            BiometricSourcePickerLabel(source: model.heightSourceBinding.wrappedValue)
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
}
