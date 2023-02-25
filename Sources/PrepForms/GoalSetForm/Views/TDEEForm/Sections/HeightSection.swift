import SwiftUI
import SwiftHaptics
import PrepDataTypes
import ActivityIndicatorView
import SwiftUISugar

struct HeightSection: View {
    
    @EnvironmentObject var viewModel: TDEEForm.ViewModel
    @Namespace var namespace
    @FocusState var isFocused: Bool
    
    var content: some View {
        VStack {
            Group {
                if let source = viewModel.heightSource {
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
        viewModel.changeHeightSource(to: .healthApp)
    }
    
    func tappedManualEntry() {
        viewModel.changeHeightSource(to: .userEntered)
        isFocused = true
    }
    
    var emptyContent: some View {
//        VStack(spacing: 10) {
//            emptyButton("Sync with Health app", showHealthAppIcon: true, action: tappedSyncWithHealth)
//            emptyButton("Let me type it in", systemImage: "keyboard", action: tappedManualEntry)
//        }
        FlowView(alignment: .center, spacing: 10, padding: 37) {
            emptyButton2("Sync with Health App", showHealthAppIcon: true, action: tappedSyncWithHealth)
            emptyButton2("Enter manually", systemImage: "keyboard", action: tappedManualEntry)
        }
    }

    @ViewBuilder
    var footer: some View {
        switch viewModel.heightSource {
        case .userEntered:
            Text("You will need to update your height manually.")
        case .healthApp:
            Text("Your height will be kept in sync with the Health App.")
        default:
            EmptyView()
        }
    }
    
    var bottomRow: some View {
        @ViewBuilder
        var health: some View {
            if viewModel.heightFetchStatus != .notAuthorized {
                HStack {
                    Spacer()
                    if viewModel.heightFetchStatus == .fetching {
                        ActivityIndicatorView(isVisible: .constant(true), type: .opacityDots())
                            .frame(width: 25, height: 25)
                            .foregroundColor(.secondary)
                    } else {
                        if let date = viewModel.heightDate {
                            Text("as of \(date.tdeeFormat)")
                                .font(.subheadline)
                                .foregroundColor(Color(.tertiaryLabel))
                        }
                        Text(viewModel.heightFormatted)
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                            .foregroundColor(viewModel.sexSource == .userEntered ? .primary : .secondary)
                            .matchedGeometryEffect(id: "height", in: namespace)
                            .if(!viewModel.hasHeight) { view in
                                view
                                    .redacted(reason: .placeholder)
                            }
                        Text(viewModel.userHeightUnit.shortDescription)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        
        var manualEntry: some View {
            var prompt: String {
                "height in"
            }
            var binding: Binding<String> {
                viewModel.heightTextFieldStringBinding
            }
            var unitString: String {
                viewModel.userHeightUnit.shortDescription
            }
            return HStack {
                Spacer()
                TextField(prompt, text: binding)
                    .keyboardType(.decimalPad)
                    .focused($isFocused)
                    .multilineTextAlignment(.trailing)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .matchedGeometryEffect(id: "height", in: namespace)
                Text(unitString)
                    .foregroundColor(.secondary)
            }
        }
        
        return Group {
            switch viewModel.heightSource {
            case .healthApp:
                health
            case .userEntered:
                manualEntry
            default:
                EmptyView()
            }
        }
    }
    
    var sourceSection: some View {
        var sourceMenu: some View {
            Menu {
                Picker(selection: viewModel.heightSourceBinding, label: EmptyView()) {
                    ForEach(MeasurementSource.allCases, id: \.self) {
                        Label($0.pickerDescription, systemImage: $0.systemImage).tag($0)
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    HStack {
                        if viewModel.heightSource == .healthApp {
                            appleHealthSymbol
                        } else {
                            if let systemImage = viewModel.heightSource?.systemImage {
                                Image(systemName: systemImage)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Text(viewModel.heightSource?.menuDescription ?? "")
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    Image(systemName: "chevron.up.chevron.down")
                        .imageScale(.small)
                }
                .foregroundColor(.secondary)
                .animation(.none, value: viewModel.heightSource)
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
    
    func heightSourceChanged(to newSource: MeasurementSource?) {
        switch newSource {
        case .userEntered:
            isFocused = true
        default:
            break
        }
    }
 
    var header: some View {
        Text("Height")
    }
    
    var body: some View {
        FormStyledSection(header: header, footer: footer) {
            content
        }
        .onChange(of: viewModel.heightSource, perform: heightSourceChanged)
    }
}
