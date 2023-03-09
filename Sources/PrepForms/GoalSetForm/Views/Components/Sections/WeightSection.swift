import SwiftUI
import SwiftHaptics
import PrepDataTypes
import ActivityIndicatorView
import SwiftUISugar
import HealthKit

struct WeightSection: View {
    
    @EnvironmentObject var model: BiometricsModel
    @Namespace var namespace
    @FocusState var isFocused: Bool
    let includeHeader: Bool
    
    init(includeHeader: Bool = true) {
        self.includeHeader = includeHeader
    }
    
    var content: some View {
        VStack {
            Group {
                if let source = model.weightSource {
                    Group {
                        sourceSection
                        switch source {
                        case .healthApp:
//                            healthContent
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
        model.changeWeightSource(to: .healthApp)
    }
    
    func tappedManualEntry() {
        model.changeWeightSource(to: .userEntered)
        isFocused = true
    }
    
    var emptyContent: some View {
        HStack {
            BiometricButton(healthTitle: "Sync", action: tappedSyncWithHealth)
            BiometricButton("Enter", systemImage: "keyboard", action: tappedManualEntry)
        }
    }

    @ViewBuilder
    var footer: some View {
        switch model.weightSource {
        case .userEntered:
            Text("You will need to update your weight manually.")
        case .healthApp:
            Text("Your weight will be kept in sync with the Health App.")
        default:
            EmptyView()
        }
    }
    
    var bottomRow: some View {
        @ViewBuilder
        var health: some View {
            switch model.weightFetchStatus {
            case .noData:
                Text("No Data")
            case .noDataOrNotAuthorized:
                Text("No Data or Not Authorized")
            case .notFetched, .fetching, .fetched:
                HStack {
                    Spacer()
                    if model.weightFetchStatus == .fetching {
                        ActivityIndicatorView(isVisible: .constant(true), type: .opacityDots())
                            .frame(width: 25, height: 25)
                            .foregroundColor(.secondary)
                    } else {
                        if let date = model.weightDate {
                            Text("as of \(date.tdeeFormat)")
                                .font(.subheadline)
                                .foregroundColor(Color(.tertiaryLabel))
                        }
                        Text(model.weightFormatted)
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                            .foregroundColor(model.weightSource == .userEntered ? .primary : .secondary)
                            .matchedGeometryEffect(id: "weight", in: namespace)
                            .if(!model.hasWeight) { view in
                                view
                                    .redacted(reason: .placeholder)
                            }
                        Text(model.userWeightUnit.shortDescription)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        
        var manualEntry: some View {
            var prompt: String {
                "weight in"
            }
            var binding: Binding<String> {
                model.weightTextFieldStringBinding
            }
            var unitString: String {
                model.userWeightUnit.shortDescription
            }
            return HStack {
                Spacer()
                TextField(prompt, text: binding)
                    .keyboardType(.decimalPad)
                    .focused($isFocused)
                    .multilineTextAlignment(.trailing)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .matchedGeometryEffect(id: "weight", in: namespace)
                Text(unitString)
                    .foregroundColor(.secondary)
            }
        }
        
        return Group {
            switch model.weightSource {
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
    
    func weightSourceChanged(to newSource: MeasurementSource?) {
        switch newSource {
        case .userEntered:
            isFocused = true
        default:
            break
        }
    }
 
    @ViewBuilder
    var header: some View {
        if includeHeader {
            Text("Weight")
        }
    }
    
    var body: some View {
        FormStyledSection(header: header, footer: footer) {
            content
        }
        .onChange(of: model.weightSource, perform: weightSourceChanged)
    }
}
