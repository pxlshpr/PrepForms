import SwiftUI
import SwiftHaptics
import PrepDataTypes
import ActivityIndicatorView
import SwiftUISugar
import HealthKit

struct AgeSection: View {
    
    let largeTitle: Bool
    @EnvironmentObject var model: BiometricsModel
    @Namespace var namespace
    @FocusState var isFocused: Bool
    @State var showFormOnAppear = false

    init(largeTitle: Bool = false) {
        self.largeTitle = largeTitle
    }
    
    var body: some View {
        FormStyledSection(header: header) {
            content
        }
        .onChange(of: model.ageSource, perform: ageSourceChanged)
    }

    var content: some View {
        VStack {
            Group {
                if let source = model.ageSource {
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
        model.changeAgeSource(to: .health)
    }
    
    func tappedManualEntry() {
        showFormOnAppear = true
        model.changeAgeSource(to: .userEntered)
        isFocused = true
    }
    
    var emptyContent: some View {
        HStack {
            BiometricButton(healthTitle: "Sync", action: tappedSyncWithHealth)
            BiometricButton("Enter", systemImage: "keyboard", action: tappedManualEntry)
        }
    }

    var bottomRow: some View {
//        @ViewBuilder
//        var healthContent: some View {
//            switch model.dobFetchStatus {
//            case .noData:
//                Text("No Data")
//            case .noDataOrNotAuthorized:
//                Text("No Data or Not Authorized")
//            case .notFetched, .fetched, .fetching:
//                HStack {
//                    Spacer()
//                    if model.dobFetchStatus == .fetching {
//                        ActivityIndicatorView(isVisible: .constant(true), type: .opacityDots())
//                            .frame(width: 25, height: 25)
//                            .foregroundColor(.secondary)
//                    } else {
//                        Text(model.ageFormatted)
//                            .font(.system(.title3, design: .rounded, weight: .semibold))
//                            .foregroundColor(model.sexSource == .userEntered ? .primary : .secondary)
//                            .matchedGeometryEffect(id: "age", in: namespace)
//                            .if(!model.hasAge) { view in
//                                view
//                                    .redacted(reason: .placeholder)
//                            }
//                        Text("years")
//                            .foregroundColor(.secondary)
//                    }
//                }
//            }
//        }
//
//        var manualEntry: some View {
//            HStack {
//                Spacer()
//                TextField("age", text: model.ageTextFieldStringBinding)
//                    .keyboardType(.decimalPad)
//                    .focused($isFocused)
//                    .multilineTextAlignment(.trailing)
//                    .font(.system(.title3, design: .rounded, weight: .semibold))
//                    .matchedGeometryEffect(id: "age", in: namespace)
//                Text("years")
//                    .foregroundColor(.secondary)
//            }
//        }
//
//        return Group {
//            switch model.ageSource {
//            case .health:
//                healthContent
//            case .userEntered:
//                manualEntry
//            default:
//                EmptyView()
//            }
//        }
        
        let valueBinding = Binding<BiometricValue?>(
            get: {
                model.ageBiometricValue
            },
            set: { newValue in
                model.age = newValue?.age
                model.saveBiometrics()
            }
        )
        
        return HStack {
            BiometricValueRow(
                value: valueBinding,
                type: .age,
                source: model.ageSource ?? .userEntered,
                fetchStatus: model.dobFetchStatus,
                prefix: nil,
                showFormOnAppear: $showFormOnAppear
            )
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
                BiometricSourcePickerLabel(source: model.ageSourceBinding.wrappedValue)
            }
            .animation(.none, value: model.ageSource)
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
    
    func ageSourceChanged(to newSource: MeasurementSource?) {
        switch newSource {
        case .userEntered:
            isFocused = true
        default:
            break
        }
    }
 
    var header: some View {
        biometricHeaderView("Age", largeTitle: largeTitle)
    }
}
