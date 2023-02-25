import SwiftUI
import PrepDataTypes
import SwiftHaptics

extension TDEEForm {
    
//    var weightField: some View {
//        var unitPicker: some View {
//            Menu {
//                Picker(selection: $weightUnit, label: EmptyView()) {
//                    ForEach([WeightUnit.kg, WeightUnit.lb], id: \.self) {
//                        Text($0.pickerDescription + "s").tag($0)
//                    }
//                }
//            } label: {
//                HStack(spacing: 5) {
//                    Text(weightUnit.shortDescription)
//                    if !viewModel.restingEnergyUsesHealthMeasurements {
//                        Image(systemName: "chevron.up.chevron.down")
//                            .imageScale(.small)
//                    }
//                }
//                .foregroundColor(.accentColor)
//                .fixedSize(horizontal: true, vertical: true)
//                .animation(.none, value: weightUnit)
//            }
//            .simultaneousGesture(TapGesture().onEnded {
//                Haptics.feedback(style: .soft)
//            })
//            .disabled(viewModel.restingEnergyUsesHealthMeasurements)
//        }
//        
//        let weightBinding = Binding<String>(
//            get: {
//                weightString
//            },
//            set: { newValue in
//                guard !newValue.isEmpty else {
//                    weightDouble = nil
//                    weightString = newValue
//                    return
//                }
//                guard let double = Double(newValue) else {
//                    return
//                }
//                self.weightDouble = double
//                withAnimation {
//                    self.weightString = newValue
//                }
//            }
//        )
//        
//        var textField: some View {
//            TextField("weight in", text: weightBinding)
//                .keyboardType(.decimalPad)
//                .multilineTextAlignment(.trailing)
//                .disabled(viewModel.restingEnergyUsesHealthMeasurements)
//        }
//        
//        @ViewBuilder
//        var date: some View {
//            if let weightDate {
//                Text("as of \(weightDate.tdeeFormat)")
//                    .foregroundColor(Color(.secondaryLabel))
//                    .font(.caption)
//                    .layoutPriority(1)
//            }
//        }
//        
//        return HStack {
//            Text("Weight")
//            date
//            Spacer()
//            textField
//            unitPicker
//        }
//    }
    
}
