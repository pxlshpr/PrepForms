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
            Text("This is the biological sex used in the formula.")
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
        var sourceMenu: some View {
            Menu {
                Picker(selection: model.sexSourceBinding, label: EmptyView()) {
                    ForEach(MeasurementSource.allCases, id: \.self) {
                        Label($0.pickerDescription, systemImage: $0.systemImage).tag($0)
                    }
                }
            } label: {
                BiometricSourcePickerLabel(source: model.sexSourceBinding.wrappedValue)
            }
            .id(model.sexSource)
            .animation(.none, value: model.sexSource)
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
    
    var header: some View {
        BiometricSectionHeader(type: .sex)
            .environmentObject(model)
    }
}
