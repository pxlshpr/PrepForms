import SwiftUI
import SwiftUISugar
import PrepDataTypes
import PrepCoreDataStack
import SwiftHaptics
import ActivityIndicatorView

extension BiometricValueRow {
    
    var sexPicker: some View {
        
        var labelString: String {
            if !isUserEntered, syncStatus != .syncing, value == nil {
                return "no data"
            } else {
                return (value?.sex ?? .female).description
            }
        }
        
        var label: some View {
            HStack {
                Text(labelString)
                    .font(font)
                    .multilineTextAlignment(.trailing)
                if isUserEntered {
                    Image(systemName: "chevron.up.chevron.down")
                        .fontWeight(.semibold)
                        .imageScale(.small)
                }
            }
            .fixedSize(horizontal: true, vertical: false)
            .foregroundColor(textColor)
            .padding(.vertical, isUserEntered ? 8 : 0)
            .padding(.horizontal, isUserEntered ? 15 : 0)
            .background(background)
        }
        
        var menu: some View {
            let binding = Binding<BiometricSex>(
                get: { value?.sex ?? .female },
                set: { newValue in
                    value = .sex(newValue)
                }
            )
            
            return Menu {
                Picker(selection: binding, label: EmptyView()) {
                    ForEach([BiometricSex.female, BiometricSex.male], id: \.self) {
                        Text($0.description).tag($0)
                    }
                }
            } label: {
                label
            }
            .animation(.none, value: value)
            .fixedSize(horizontal: true, vertical: false)
            .contentShape(Rectangle())
            .simultaneousGesture(TapGesture().onEnded {
                Haptics.feedback(style: .light)
            })
        }
        
        var button: some View {
            Button {
                Haptics.feedback(style: .soft)
                present(.sexPickerSheet)
            } label: {
                label
            }
        }
        
//        return menu
        return button
            .disabled(!isUserEntered)
    }
    
}
