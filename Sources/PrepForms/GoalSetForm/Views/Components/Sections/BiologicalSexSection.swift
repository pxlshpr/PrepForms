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
    
    @Namespace var namespace
    
    init(largeTitle: Bool = false, includeFooter: Bool = false) {
        self.largeTitle = largeTitle
        self.includeFooter = includeFooter
    }
    
    var body: some View {
        FormStyledSection(header: header, footer: footer) {
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
                        case .healthApp:
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
        model.changeSexSource(to: .healthApp)
    }
    
    func tappedManualEntry() {
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
        var picker: some View {
            Menu {
                if model.sexSource == .userEntered {
                    Picker(selection: model.sexPickerBinding, label: EmptyView()) {
                        Text("female").tag(HKBiologicalSex.female)
                        Text("male").tag(HKBiologicalSex.male)
                    }
                }
            } label: {
                switch model.sexFetchStatus {
                case .noData:
                    Text("No Data")
                case .noDataOrNotAuthorized:
                    Text("No Data or Not Authorized")
                case .notFetched, .fetching, .fetched:
                    HStack(spacing: 5) {
                        if model.sexFetchStatus == .fetching {
                            ActivityIndicatorView(isVisible: .constant(true), type: .opacityDots())
                                .frame(width: 25, height: 25)
                                .foregroundColor(.secondary)
                        } else {
                            Text(model.sexFormatted ?? "not specified")
                                .font(.system(.title3, design: .rounded, weight: .semibold))
                                .foregroundColor(model.sexSource == .userEntered ? .primary : .secondary)
                                .foregroundColor(.primary)
                                .animation(.none, value: model.sex)
                                .animation(.none, value: model.sexSource)
                                .fixedSize(horizontal: true, vertical: true)
                                .if(!model.hasSex && model.sexSource != .userEntered) { view in
                                    view
                                        .redacted(reason: .placeholder)
                                }
                            if model.sexSource == .userEntered {
                                Image(systemName: "chevron.up.chevron.down")
                                    .imageScale(.small)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .contentShape(Rectangle())
            .simultaneousGesture(TapGesture().onEnded {
                if model.sexSource == .userEntered {
                    Haptics.feedback(style: .soft)
                }
            })
        }
        
        return HStack {
            Spacer()
            picker
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
