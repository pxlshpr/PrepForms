import SwiftUI
import PrepDataTypes
import SwiftHaptics
import HealthKit

extension TDEEForm {

//    var bodyMeasurementsSection: some View {
//        @ViewBuilder
//        var footer: some View {
//            if viewModel.restingEnergyUsesHealthMeasurements {
//                Text("Your measurements from HealthKit will be kept in sync to keep your maintenance calories up-to-date.")
//            }
//        }
//
//        var header: some View {
//            Text("Body Measurements")
//        }
//
//        return Section(header: header, footer: footer) {
//            Toggle(isOn: formToggleBinding($viewModel.restingEnergyUsesHealthMeasurements)) {
//                HStack {
//                    Image(systemName: "heart.fill")
//                        .renderingMode(.original)
//                    Text("Sync with HealthKit")
//                }
//            }
//            biologicalSexField
//            weightField
//            heightField
//        }
//    }
//    
//    var biologicalSexField: some View {
//        var picker: some View {
//            Menu {
//                Picker(selection: $biologicalSex, label: EmptyView()) {
//                    Text("female").tag(HKBiologicalSex.female)
//                    Text("male").tag(HKBiologicalSex.male)
//                }
//            } label: {
//                HStack(spacing: 5) {
//                    Text(biologicalSex.description.lowercased())
//                    if !viewModel.restingEnergyUsesHealthMeasurements {
//                        Image(systemName: "chevron.up.chevron.down")
//                            .imageScale(.small)
//                    }
//                }
//                .foregroundColor(.accentColor)
//                .animation(.none, value: biologicalSex)
//                .fixedSize(horizontal: true, vertical: true)
//            }
//            .simultaneousGesture(TapGesture().onEnded {
//                Haptics.feedback(style: .soft)
//            })
//            .disabled(viewModel.restingEnergyUsesHealthMeasurements)
//        }
//
//        return HStack {
//            Text("Biological Sex")
//            Spacer()
//            picker
//        }
//    }
    
}
