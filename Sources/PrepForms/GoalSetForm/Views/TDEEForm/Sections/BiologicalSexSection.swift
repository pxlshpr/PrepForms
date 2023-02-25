import SwiftUI
import SwiftHaptics
import PrepDataTypes
import ActivityIndicatorView
import SwiftUISugar
import HealthKit

struct BiologicalSexSection: View {
    
    @EnvironmentObject var viewModel: TDEEForm.ViewModel
    @Namespace var namespace
    
    var content: some View {
        VStack {
            Group {
                if let source = viewModel.sexSource {
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
        viewModel.changeSexSource(to: .healthApp)
    }
    
    func tappedManualEntry() {
        viewModel.changeSexSource(to: .userEntered)
    }
    
    var emptyContent: some View {
//        VStack(spacing: 10) {
//            emptyButton("Sync with Health app", showHealthAppIcon: true, action: tappedSyncWithHealth)
//            emptyButton("Let me specify it", systemImage: "hand.tap", action: tappedManualEntry)
//        }
        FlowView(alignment: .center, spacing: 10, padding: 37) {
            emptyButton2("Import from Health App", showHealthAppIcon: true, action: tappedSyncWithHealth)
            emptyButton2("Choose", systemImage: "hand.tap", action: tappedManualEntry)
        }
    }

    @ViewBuilder
    var footer: some View {
        Text("This is the biological sex you would like to use in the formula.")
    }
    
    var bottomRow: some View {
        var picker: some View {
            Menu {
                if viewModel.sexSource == .userEntered {
                    Picker(selection: viewModel.sexPickerBinding, label: EmptyView()) {
                        Text("female").tag(HKBiologicalSex.female)
                        Text("male").tag(HKBiologicalSex.male)
                    }
                }
            } label: {
                if viewModel.sexFetchStatus != .notAuthorized {
                    HStack(spacing: 5) {
                        if viewModel.sexFetchStatus == .fetching {
                            ActivityIndicatorView(isVisible: .constant(true), type: .opacityDots())
                                .frame(width: 25, height: 25)
                                .foregroundColor(.secondary)
                        } else {
                            Text(viewModel.sexFormatted ?? "not specified")
                                .font(.system(.title3, design: .rounded, weight: .semibold))
                                .foregroundColor(viewModel.sexSource == .userEntered ? .primary : .secondary)
                                .foregroundColor(.primary)
                                .animation(.none, value: viewModel.sex)
                                .animation(.none, value: viewModel.sexSource)
                                .fixedSize(horizontal: true, vertical: true)
                                .if(!viewModel.hasSex && viewModel.sexSource != .userEntered) { view in
                                    view
                                        .redacted(reason: .placeholder)
                                }
                            if viewModel.sexSource == .userEntered {
                                Image(systemName: "chevron.up.chevron.down")
                                    .imageScale(.small)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .simultaneousGesture(TapGesture().onEnded {
                if viewModel.sexSource == .userEntered {
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
                Picker(selection: viewModel.sexSourceBinding, label: EmptyView()) {
                    ForEach(MeasurementSource.allCases, id: \.self) {
                        Label($0.pickerDescription, systemImage: $0.systemImage).tag($0)
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    HStack {
                        if viewModel.sexSource == .healthApp {
                            appleHealthSymbol
                        } else {
                            if let systemImage = viewModel.sexSource?.systemImage {
                                Image(systemName: systemImage)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Text(viewModel.sexSource?.menuDescription ?? "")
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    Image(systemName: "chevron.up.chevron.down")
                        .imageScale(.small)
                }
                .foregroundColor(.secondary)
                .animation(.none, value: viewModel.sexSource)
                .fixedSize(horizontal: true, vertical: false)
            }
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
        Text("Biological Sex")
    }
    
    var body: some View {
        FormStyledSection(header: header, footer: footer) {
            content
        }
        .onChange(of: viewModel.sexSource, perform: sexSourceChanged)
    }
}
