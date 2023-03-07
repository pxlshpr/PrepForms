import SwiftUI
import SwiftHaptics
import PrepDataTypes
import ActivityIndicatorView
import SwiftUISugar
import HealthKit

struct AgeSection: View {
    
    @EnvironmentObject var model: BodyProfileModel
    @Namespace var namespace
    @FocusState var isFocused: Bool
    
    var content: some View {
        VStack {
            Group {
                if let source = model.ageSource {
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
        model.changeAgeSource(to: .healthApp)
    }
    
    func tappedManualEntry() {
        model.changeAgeSource(to: .userEntered)
        isFocused = true
    }
    
    var emptyContent: some View {
//        VStack(spacing: 10) {
//            emptyButton("Sync with Health app", showHealthAppIcon: true, action: tappedSyncWithHealth)
//            emptyButton("Let me type it in", systemImage: "keyboard", action: tappedManualEntry)
//        }
        FlowView(alignment: .leading, spacing: 10, padding: 37) {
            emptyButton2("Sync", showHealthAppIcon: true, action: tappedSyncWithHealth)
            emptyButton2("Enter", systemImage: "keyboard", action: tappedManualEntry)
        }
    }

    var bottomRow: some View {
        @ViewBuilder
        var health: some View {
            if model.dobFetchStatus != .notAuthorized {
                HStack {
                    Spacer()
                    if model.dobFetchStatus == .fetching {
                        ActivityIndicatorView(isVisible: .constant(true), type: .opacityDots())
                            .frame(width: 25, height: 25)
                            .foregroundColor(.secondary)
                    } else {
                        Text(model.ageFormatted)
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                            .foregroundColor(model.sexSource == .userEntered ? .primary : .secondary)
                            .matchedGeometryEffect(id: "age", in: namespace)
                            .if(!model.hasAge) { view in
                                view
                                    .redacted(reason: .placeholder)
                            }
                        Text("years")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        
        var manualEntry: some View {
            HStack {
                Spacer()
                TextField("age", text: model.ageTextFieldStringBinding)
                    .keyboardType(.decimalPad)
                    .focused($isFocused)
                    .multilineTextAlignment(.trailing)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .matchedGeometryEffect(id: "age", in: namespace)
                Text("years")
                    .foregroundColor(.secondary)
            }
        }
        
        return Group {
            switch model.ageSource {
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
                Picker(selection: model.ageSourceBinding, label: EmptyView()) {
                    ForEach(MeasurementSource.allCases, id: \.self) {
                        Label($0.pickerDescription, systemImage: $0.systemImage).tag($0)
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    HStack {
                        if model.ageSource == .healthApp {
                            appleHealthSymbol
                        } else {
                            if let systemImage = model.ageSource?.systemImage {
                                Image(systemName: systemImage)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Text(model.ageSource?.menuDescription ?? "")
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    Image(systemName: "chevron.up.chevron.down")
                        .imageScale(.small)
                }
                .foregroundColor(.secondary)
                .animation(.none, value: model.ageSource)
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
    
    func ageSourceChanged(to newSource: MeasurementSource?) {
        switch newSource {
        case .userEntered:
            isFocused = true
        default:
            break
        }
    }
 
    var header: some View {
        Text("Age")
    }
    
    var body: some View {
        FormStyledSection(header: header) {
            content
        }
        .onChange(of: model.ageSource, perform: ageSourceChanged)
    }
}

func emptyButton2(_ title: String, systemImage: String? = nil, showHealthAppIcon: Bool = false, action: (() -> ())? = nil) -> some View {
    
    @ViewBuilder
    var label: some View {
        if showHealthAppIcon {
            AppleHealthButtonLabel(title: title)
        } else {
            ButtonLabel(title: title, systemImage: systemImage)
        }
    }
    
    var label_legacy: some View {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundColor(Color(.tertiaryLabel))
            } else if showHealthAppIcon {
                appleHealthSymbol
            }
            Text(title)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(.secondary)
        }
        .frame(minHeight: 30)
        .padding(.horizontal, 15)
        .padding(.vertical, 5)
        .background (
            Capsule(style: .continuous)
                .foregroundColor(Color(.secondarySystemFill))
        )
    }
    
    return Button {
        action?()
    } label: {
        label
    }
}
