import SwiftUI
import PrepDataTypes

extension TDEEForm {
    
    var maintenanceSection: some View {
        
        var content: some View {

            func filled(value: Double, unit: EnergyUnit) -> some View {
                MaintenanceEnergyView(
                    value: value,
                    unit: unit,
                    namespace: namespace
                )
                .fixedSize(horizontal: true, vertical: false)
            }
            
            var empty: some View {
                Text("Set your resting and active energies to determine this")
                    .foregroundColor(Color(.tertiaryLabel))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
//                    .padding(.vertical)
            }
            
            return Group {
                if let value = model.maintenanceEnergy {
                    filled(value: value, unit: model.userEnergyUnit)
                } else {
                    empty
                }
            }
            .frame(height: 60)
        }
        
        var header: some View {
            var empty: some View {
                HStack {
                    Image(systemName: "flame.fill")
                        .matchedGeometryEffect(id: "maintenance-header-icon", in: namespace)
                    Text("Setup Maintenance Calories")
                        .fixedSize(horizontal: true, vertical: false)
                        .matchedGeometryEffect(id: "maintenance-header-title", in: namespace)
                }
            }
            
            var filled: some View {
                HStack {
                    Image(systemName: "flame.fill")
                        .matchedGeometryEffect(id: "maintenance-header-icon", in: namespace)
                    Text("Maintenance Energy")
                }
            }
            return Group {
                if model.maintenanceEnergy == nil {
                    empty
                } else {
                    filled
                }
            }
        }
        
        return Group {
            VStack(spacing: 7) {
                header
                    .textCase(.uppercase)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(Color(.secondaryLabel))
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                content
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 0)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(Color(.secondarySystemGroupedBackground))
                            .matchedGeometryEffect(id: "maintenance-bg", in: namespace)
                    )
//                model.tdeeDescriptionText
//                    .matchedGeometryEffect(id: "maintenance-footer", in: namespace)
//                    .fixedSize(horizontal: false, vertical: false)
//                    .foregroundColor(Color(.secondaryLabel))
//                    .font(.footnote)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
    }
}

struct MaintenanceEnergyView: View {
    
    @State var valueWidth: CGFloat = 0
    @State var unitWidth: CGFloat = 0
    
    let value: Double
    let unit: EnergyUnit
    
    let namespace: Namespace.ID
    
    var body: some View {
        content
    }
    
    var content: some View {
        Color.clear
            .animatedMaintenanceEnergyModifier(
                value: value,
                energyUnit: unit,
                namespace: namespace
            )
            .fixedSize(horizontal: true, vertical: false)
            .frame(maxWidth: .infinity, alignment: .center)
    }
    
    var content_legacy: some View {
        VStack {
            ZStack {
                Text(value.formattedEnergy)
                    .fixedSize(horizontal: true, vertical: false)
                    .matchedGeometryEffect(id: "maintenance", in: namespace)
                    .font(.system(.largeTitle, design: .rounded, weight: .semibold))
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .preference(key: ValueWidthPreferenceKey.self, value: proxy.size.width)
                        }
                    )
                Text(unit.shortDescription)
                    .foregroundColor(.secondary)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .preference(key: UnitWidthPreferenceKey.self, value: proxy.size.width)
                        }
                    )
                    .offset(x: (valueWidth / 2.0) + (unitWidth / 2.0) + 5)
            }
        }
        .frame(maxWidth: .infinity)
        .onPreferenceChange(ValueWidthPreferenceKey.self, perform: valueWidthChanged)
        .onPreferenceChange(UnitWidthPreferenceKey.self, perform: unitWidthChanged)
    }
    
    func valueWidthChanged(to newValue: CGFloat) {
        valueWidth = newValue
    }

    func unitWidthChanged(to newValue: CGFloat) {
        unitWidth = newValue
    }

    struct ValueWidthPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {}
    }
    
    struct UnitWidthPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {}
    }
}

struct AnimatableMaintenanceEnergyModifier: AnimatableModifier {
    
    @Environment(\.colorScheme) var colorScheme
    @State var size: CGSize = .zero

    var value: Double
    var energyUnit: EnergyUnit
    var namespace: Namespace.ID
    
    var animatableData: Double {
        get { value }
        set { value = newValue }
    }
    
    func body(content: Content) -> some View {
        content
            .frame(width: size.width, height: size.height)
            .overlay(
                animatedLabel
                    .readSize { size in
                        self.size = size
                    }
            )
    }
    
    var animatedLabel: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(value.formattedEnergy)
                .matchedGeometryEffect(id: "maintenance", in: namespace)
                .fixedSize(horizontal: true, vertical: false)
                .font(.system(.largeTitle, design: .rounded, weight: .semibold))
                .foregroundColor(.primary)
            Text(energyUnit.shortDescription)
                .foregroundColor(.secondary)
                .font(.system(.body, design: .rounded, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.trailing)
        .fixedSize(horizontal: true, vertical: false)
    }
}

public extension View {
    func animatedMaintenanceEnergyModifier(value: Double, energyUnit: EnergyUnit, namespace: Namespace.ID) -> some View {
        modifier(AnimatableMaintenanceEnergyModifier(value: value, energyUnit: energyUnit, namespace: namespace))
    }
}
