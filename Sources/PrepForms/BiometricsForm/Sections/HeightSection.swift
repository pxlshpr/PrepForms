import SwiftUI
import SwiftHaptics
import PrepDataTypes
import ActivityIndicatorView
import SwiftUISugar
import PrepCoreDataStack

struct HeightSection: View {
    
    let largetTitle: Bool
    @EnvironmentObject var model: BiometricsModel
    @Namespace var namespace
    @FocusState var isFocused: Bool
    @State var showFormOnAppear = false

    init(largeTitle: Bool = false) {
        self.largetTitle = largeTitle
    }
    
    var content: some View {
        VStack {
            Group {
                if let source = model.heightSource {
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
        model.changeHeightSource(to: .health)
    }
    
    func tappedManualEntry() {
        showFormOnAppear = true
        model.changeHeightSource(to: .userEntered)
        isFocused = true
    }
    
    var emptyContent: some View {
        HStack {
            BiometricButton(healthTitle: "Sync", action: tappedSyncWithHealth)
            BiometricButton("Enter", systemImage: "keyboard", action: tappedManualEntry)
        }
    }

    var bottomRow: some View {
        let valueBinding = Binding<BiometricValue?>(
            get: { model.heightBiometricValue },
            set: { newValue in
                guard let heightUnit = newValue?.unit?.heightUnit else { return }
                model.height = newValue?.double
                model.userHeightUnit = heightUnit
                UserManager.heightUnit = heightUnit
                
                /// Delay this by a second so that the core-data persistence doesn't interfere with
                /// the change of energy unit
                model.saveBiometrics(afterDelay: true)
            }
        )
        
        return HStack {
            BiometricValueRow(
                value: valueBinding,
                type: .height,
                source: model.heightSource ?? .userEntered,
                syncStatus: model.heightSyncStatus,
                prefix: model.heightDateFormatted,
                showFormOnAppear: $showFormOnAppear
            )
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
        biometricHeaderView("Height", largeTitle: largetTitle)
    }
    
    var body: some View {
        FormStyledSection(header: header) {
            content
        }
        .onChange(of: model.heightSource, perform: heightSourceChanged)
    }
}
