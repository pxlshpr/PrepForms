import SwiftUI
import SwiftHaptics
import PrepDataTypes
import ActivityIndicatorView
import SwiftUISugar
import HealthKit
import PrepCoreDataStack

struct WeightSection: View {
    
    let includeHeader: Bool
    
    @EnvironmentObject var model: BiometricsModel
    @State var showFormOnAppear = false
    @State var showingSourcePicker = false

    init(includeHeader: Bool = true) {
        self.includeHeader = includeHeader
    }
    
    var body: some View {
        FormStyledSection(header: header) {
            content
        }
    }

    @ViewBuilder
    var header: some View {
        if includeHeader {
            BiometricSectionHeader(type: .weight)
                .environmentObject(model)
        }
    }

    var content: some View {
        VStack {
            Group {
                if let source = model.weightSource {
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
        model.changeWeightSource(to: .health)
    }
    
    func tappedManualEntry() {
        showFormOnAppear = true
        model.changeWeightSource(to: .userEntered)
    }
    
    var emptyContent: some View {
        HStack {
            BiometricButton(healthTitle: "Sync", action: tappedSyncWithHealth)
            BiometricButton("Enter", systemImage: "keyboard", action: tappedManualEntry)
        }
    }

    var bottomRow: some View {
        let valueBinding = Binding<BiometricValue?>(
            get: { model.weightBiometricValue },
            set: { newValue in
                guard let bodyMassUnit = newValue?.unit?.bodyMassUnit else { return }
                model.weight = newValue?.double
                
                /// Convert other `.bodyMassUnit` based values in `BiometricModel` before setting the unit
                if let lbmValue = model.lbmValue, let lbmSource = model.lbmSource {
                    if lbmSource != .fatPercentage {
                        model.lbm = UserManager.bodyMassUnit.convert(lbmValue, to: bodyMassUnit)
                    }
                }
                
                UserManager.bodyMassUnit = bodyMassUnit
                
                /// Delay this by a second so that the core-data persistence doesn't interfere with
                /// the change of energy unit
                model.saveBiometrics(afterDelay: true)
            }
        )
        
        return HStack {
            BiometricValueRow(
                value: valueBinding,
                type: .weight,
                source: model.weightSource ?? .userEntered,
                syncStatus: model.weightSyncStatus,
                prefix: model.weightDateFormatted,
                showFormOnAppear: $showFormOnAppear
            )
        }
    }
    
    var sourceSection: some View {

        var label: some View {
            BiometricSourcePickerLabel(source: model.weightSourceBinding.wrappedValue)
        }
        
        var sourcePickerSheet: some View {
            PickerSheet(
                title: "Choose a Source",
                items: MeasurementSource.pickerItems,
                pickedItem: model.weightSource?.pickerItem,
                didPick: {
                    Haptics.feedback(style: .soft)
                    guard let pickedSource = MeasurementSource(pickerItem: $0) else { return }
                    model.changeWeightSource(to: pickedSource)
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
