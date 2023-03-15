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
        var sourceMenu: some View {
            Menu {
                Picker(selection: model.weightSourceBinding, label: EmptyView()) {
                    ForEach(MeasurementSource.allCases, id: \.self) {
                        Label($0.pickerDescription, systemImage: $0.systemImage).tag($0)
                    }
                }
            } label: {
                BiometricSourcePickerLabel(source: model.weightSourceBinding.wrappedValue)
            }
            .animation(.none, value: model.weightSource)
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
    }
}
