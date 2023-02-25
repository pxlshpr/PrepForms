import SwiftUI
import SwiftHaptics
import PrepDataTypes

extension TDEEForm {
    
    var restingEnergyField: some View {
        var unitPicker: some View {
            Menu {
                Picker(selection: $tdeeUnit, label: EmptyView()) {
                    ForEach(EnergyUnit.allCases, id: \.self) {
                        Text($0.shortDescription).tag($0)
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Text(tdeeUnit.shortDescription)
                    Image(systemName: "chevron.up.chevron.down")
                        .imageScale(.small)
                }
                .foregroundColor(.accentColor)
                .fixedSize(horizontal: true, vertical: true)
                .animation(.none, value: tdeeUnit)
            }
            .simultaneousGesture(TapGesture().onEnded {
                Haptics.feedback(style: .soft)
            })
        }
        
        let tdeeBinding = Binding<String>(
            get: {
                tdeeString
            },
            set: { newValue in
                guard !newValue.isEmpty else {
                    tdeeDouble = nil
                    tdeeString = newValue
                    return
                }
                guard let double = Double(newValue) else {
                    return
                }
                tdeeDouble = double
                withAnimation {
                    tdeeString = newValue
                }
            }
        )
        
        var textField: some View {
            TextField("energy in", text: tdeeBinding)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
        }
        
        return HStack {
            Text("Resting Energy")
            Spacer()
            textField
            unitPicker
        }
    }
            
//    var sourceSection: some View {
//
//        var sourcePicker: some View {
//            let tdeeSourceBinding = Binding<RestingEnergySourceOption>(
//                get: { restingEnergySource },
//                set: { newValue in
//                    Haptics.feedback(style: .soft)
//                    withAnimation {
//                        restingEnergySource = newValue
//                    }
//                }
//            )
//
//            return Menu {
//                Picker(selection: tdeeSourceBinding, label: EmptyView()) {
//                    ForEach(RestingEnergySourceOption.allCases, id: \.self) {
//                        Label($0.menuDescription, systemImage: $0.systemImage).tag($0)
//                    }
//                }
//            } label: {
//                HStack(spacing: 5) {
//                    Text(restingEnergySource.pickerDescription)
//                        .frame(maxWidth: .infinity, alignment: .trailing)
//                    Image(systemName: "chevron.up.chevron.down")
//                        .imageScale(.small)
//                }
//                .foregroundColor(.secondary)
//                .animation(.none, value: restingEnergySource)
//            }
//            .simultaneousGesture(TapGesture().onEnded {
//                Haptics.feedback(style: .soft)
//            })
//        }
//
//        var header: some View {
//            HStack {
//                Text("Choose a Source")
//            }
//        }
//
//        var sourceField: some View {
//            HStack {
//                Text("Source")
//                Spacer()
//                sourcePicker
//            }
//        }
//
//        return Section(header: header) {
//            sourceField
//        }
//    }
}
