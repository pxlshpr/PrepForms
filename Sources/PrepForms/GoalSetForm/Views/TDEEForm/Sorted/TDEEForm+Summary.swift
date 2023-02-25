import SwiftUI

extension TDEEForm {
    
    var summarySection: some View {
        Button {
            transitionToEditState()
        } label: {
            HStack {
                VStack(spacing: 10) {
                    Image(systemName: "flame.fill")
                        .matchedGeometryEffect(id: "maintenance-header-icon", in: namespace)
                        .foregroundColor(Color(.tertiaryLabel))
                        .imageScale(.medium)
                    Text(viewModel.maintenanceEnergyFormatted)
                        .foregroundColor(.primary)
                        .matchedGeometryEffect(id: "maintenance", in: namespace)
                        .font(.system(.title3, design: .default, weight: .bold))
                        .monospacedDigit()
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .foregroundColor(Color(.secondarySystemGroupedBackground))
                                .matchedGeometryEffect(id: "maintenance-bg", in: namespace)
                        )
                }
                VStack(spacing: 10) {
                    Image(systemName: EnergyComponent.resting.systemImage)
                        .foregroundColor(Color(.tertiaryLabel))
                        .imageScale(.medium)
                        .opacity(0)
                    Text("=")
                        .matchedGeometryEffect(id: "equals", in: namespace)
                        .font(.title)
                        .foregroundColor(Color(.quaternaryLabel))
                }
                VStack(spacing: 10) {
                    HStack(spacing: 3) {
                        Image(systemName: EnergyComponent.resting.systemImage)
                            .matchedGeometryEffect(id: "resting-header-icon", in: namespace)
                            .foregroundColor(Color(.tertiaryLabel))
                            .imageScale(.medium)
                        if viewModel.restingEnergyIsDynamic {
//                            appleHealthSymbol
                            appleHealthBolt
                                .imageScale(.small)
                                .matchedGeometryEffect(id: "resting-health-icon", in: namespace)
                        }
                    }
                    Text(viewModel.restingEnergyFormatted)
                        .matchedGeometryEffect(id: "resting", in: namespace)
                        .fixedSize(horizontal: true, vertical: false)
                        .font(.system(.title3, design: .default, weight: .regular))
                        .foregroundColor(.primary)
                        .monospacedDigit()
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .foregroundColor(Color(.secondarySystemGroupedBackground))
                                    .matchedGeometryEffect(id: "resting-bg", in: namespace)
                            }
                        )
                }
                VStack(spacing: 10) {
                    Image(systemName: EnergyComponent.resting.systemImage)
                        .foregroundColor(Color(.tertiaryLabel))
                        .imageScale(.medium)
                        .opacity(0)
                    Text("+")
                        .matchedGeometryEffect(id: "plus", in: namespace)
                        .font(.title)
                        .foregroundColor(Color(.quaternaryLabel))
                }
                VStack(spacing: 10) {
                    HStack(spacing: 3) {
                        Image(systemName: EnergyComponent.active.systemImage)
                            .matchedGeometryEffect(id: "active-header-icon", in: namespace)
                            .foregroundColor(Color(.tertiaryLabel))
                            .imageScale(.medium)
                        if viewModel.activeEnergyIsDynamic {
//                            appleHealthSymbol
                            appleHealthBolt
                                .matchedGeometryEffect(id: "active-health-icon", in: namespace)
                                .imageScale(.small)
                        }
                    }
                    Text(viewModel.activeEnergyFormatted)
                        .matchedGeometryEffect(id: "active", in: namespace)
                        .font(.system(.title3, design: .default, weight: .regular))
                        .foregroundColor(.primary)
                        .monospacedDigit()
                        .padding(.vertical, 20)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .foregroundColor(Color(.secondarySystemGroupedBackground))
                                .matchedGeometryEffect(id: "active-bg", in: namespace)
                        )
                }
            }
            .padding(.horizontal, 17)
        }
    }
}
