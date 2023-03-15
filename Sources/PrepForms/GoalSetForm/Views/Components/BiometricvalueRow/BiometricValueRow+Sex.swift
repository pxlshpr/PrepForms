import SwiftUI
import SwiftUISugar
import PrepDataTypes
import PrepCoreDataStack
import SwiftHaptics
import ActivityIndicatorView

extension BiometricValueRow {
    
    var sexPicker: some View {
        let sexBinding = Binding<BiometricSex>(
            get: { value?.sex ?? .female },
            set: { newValue in
                value = .sex(newValue)
            }
        )
        
        var labelString: String {
//            if !isUserEntered, fetchStatus == .noData {
            if !isUserEntered, syncStatus != .syncing, value == nil {
                return "no data"
            } else {
                return sexBinding.wrappedValue.description
            }
        }
        
        return Menu {
            Picker(selection: sexBinding, label: EmptyView()) {
                ForEach([BiometricSex.female, BiometricSex.male], id: \.self) {
                    Text($0.description).tag($0)
                }
            }
        } label: {
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
        .animation(.none, value: value)
        .fixedSize(horizontal: true, vertical: false)
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture().onEnded {
            Haptics.feedback(style: .light)
        })
        .disabled(!isUserEntered)
    }
    
}
