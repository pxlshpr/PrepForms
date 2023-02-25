import SwiftUI
import SwiftHaptics
import SwiftUISugar
import PrepDataTypes

struct HealthAppPeriodPicker: View {
    
    @State var selection: Int = 1
    
    @State var quantity: Int = 1
    @State var interval: HealthAppInterval = .week
    
    var typePicker: some View {
        let selectionBinding = Binding<Int>(
            get: { selection },
            set: { newValue in
                withAnimation {
                    Haptics.feedback(style: .soft)
                    selection = newValue
                }
            }
        )
        
        return Picker("", selection: selectionBinding) {
            Text("From Previous Day").tag(0)
            Text("Average").tag(1)
        }
        .pickerStyle(.segmented)
    }
    
    var body: some View {
        FormStyledScrollView {
            FormStyledSection {
                VStack(spacing: 20) {
                    typePicker
                    if selection == 1 {
                        HStack {
                            Menu {
                                Picker(selection: $quantity, label: EmptyView()) {
                                    ForEach(Array(interval.minValue...interval.maxValue), id: \.self) { quantity in
                                        Text("\(quantity)").tag(quantity)
                                    }
                                }
                            } label: {
                                HStack {
                                    Text("\(quantity)")
                                    Image(systemName: "chevron.up.chevron.down")
                                        .imageScale(.small)
                                }
                            }
                            Menu {
                                Picker(selection: $interval, label: EmptyView()) {
                                    ForEach(HealthAppInterval.allCases, id: \.self) { interval in
                                        Text("\(interval.description)\(quantity > 1 ? "s" : "")").tag(interval)
                                    }
                                }
                            } label: {
                                HStack {
                                    Text("\(interval.description)\(quantity > 1 ? "s" : "")")
                                    Image(systemName: "chevron.up.chevron.down")
                                        .imageScale(.small)
                                }
                            }
                        }
                    }
                }
            }
        }
//        .navigationTitle("Active Energy")
        .toolbar { principalContent }
    }
    
    var principalContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack {
                appleHealthSymbol
                Text("Health App")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}
