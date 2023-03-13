import SwiftUI
import SwiftHaptics
import PrepDataTypes
import ActivityIndicatorView
import SwiftUISugar
import HealthKit

struct BiologicalSexSection: View {
    
    let largeTitle: Bool
    let includeFooter: Bool
    @EnvironmentObject var model: BiometricsModel
    @State var showFormOnAppear = false
    @Namespace var namespace
    
    init(largeTitle: Bool = false, includeFooter: Bool = false) {
        self.largeTitle = largeTitle
        self.includeFooter = includeFooter
    }
    
    var body: some View {
        FormStyledSection(header: header) {
            content
        }
        .onChange(of: model.sexSource, perform: sexSourceChanged)
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
//                isFetching: model.fetchingSex,
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
    
    func sexSourceChanged(to newSource: MeasurementSource?) {
        switch newSource {
        case .userEntered:
            break
        default:
            break
        }
    }
 
    var header: some View {
        biometricHeaderView("Biological Sex", largeTitle: largeTitle)
    }
}

let BiometricSectionHeaderFont: Font = .system(.title2, design: .rounded, weight: .semibold)

func biometricHeaderView(_ title: String, largeTitle: Bool) -> some View {
    var titleView: some View {
        Text(title)
    }
    return Group {
        if largeTitle {
            titleView
                .textCase(.none)
                .font(BiometricSectionHeaderFont)
                .foregroundColor(.primary)
        } else {
            titleView
        }
    }
}
