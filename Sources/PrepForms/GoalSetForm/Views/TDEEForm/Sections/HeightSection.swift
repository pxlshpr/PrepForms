import SwiftUI
import SwiftHaptics
import PrepDataTypes
import ActivityIndicatorView
import SwiftUISugar

struct HeightSection: View {
    
    @EnvironmentObject var model: BiometricsModel
    @Namespace var namespace
    @FocusState var isFocused: Bool
    
    var content: some View {
        VStack {
            Group {
                if let source = model.heightSource {
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
        model.changeHeightSource(to: .healthApp)
    }
    
    func tappedManualEntry() {
        model.changeHeightSource(to: .userEntered)
        isFocused = true
    }
    
    var emptyContent: some View {
//        VStack(spacing: 10) {
//            emptyButton("Sync with Health app", showHealthAppIcon: true, action: tappedSyncWithHealth)
//            emptyButton("Let me type it in", systemImage: "keyboard", action: tappedManualEntry)
//        }
        FlowView(alignment: BiometricButtonsAlignment, spacing: 10, padding: 37) {
//            emptyButton2("Sync", showHealthAppIcon: true, action: tappedSyncWithHealth)
//            emptyButton2("Enter", systemImage: "keyboard", action: tappedManualEntry)
            BiometricHealthButton("Sync", action: tappedSyncWithHealth)
            BiometricButton("Enter", systemImage: "keyboard", action: tappedManualEntry)
        }
    }

    @ViewBuilder
    var footer: some View {
        switch model.heightSource {
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
            if model.heightFetchStatus != .notAuthorized {
                HStack {
                    Spacer()
                    if model.heightFetchStatus == .fetching {
                        ActivityIndicatorView(isVisible: .constant(true), type: .opacityDots())
                            .frame(width: 25, height: 25)
                            .foregroundColor(.secondary)
                    } else {
                        if let date = model.heightDate {
                            Text("as of \(date.tdeeFormat)")
                                .font(.subheadline)
                                .foregroundColor(Color(.tertiaryLabel))
                        }
                        Text(model.heightFormatted)
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                            .foregroundColor(model.sexSource == .userEntered ? .primary : .secondary)
                            .matchedGeometryEffect(id: "height", in: namespace)
                            .if(!model.hasHeight) { view in
                                view
                                    .redacted(reason: .placeholder)
                            }
                        Text(model.userHeightUnit.shortDescription)
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
                model.heightTextFieldStringBinding
            }
            var unitString: String {
                model.userHeightUnit.shortDescription
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
            switch model.heightSource {
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
                Picker(selection: model.heightSourceBinding, label: EmptyView()) {
                    ForEach(MeasurementSource.allCases, id: \.self) {
                        Label($0.pickerDescription, systemImage: $0.systemImage).tag($0)
                    }
                }
            } label: {
                BiometricSourcePickerLabel(source: model.heightSourceBinding.wrappedValue)
            }
            .animation(.none, value: model.heightSource)
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
        .onChange(of: model.heightSource, perform: heightSourceChanged)
    }
}
