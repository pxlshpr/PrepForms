import SwiftUI
import SwiftUISugar
import SwiftHaptics
import PrepDataTypes
import HealthKit

enum TDEEFormRoute: Hashable {
    case leanBodyMassForm
    case profileForm
}

extension TDEEForm {
    
    func initialTask() async {
//        guard let restingEnergy = await HealthKitManager.shared.getLatestRestingEnergy() else {
//            return
//        }
//        await MainActor.run {
//            self.healthRestingEnergy = restingEnergy
//        }
//
//        guard let activeEnergy = await HealthKitManager.shared.getLatestActiveEnergy() else {
//            return
//        }
//        await MainActor.run {
//            self.healthActiveEnergy = activeEnergy
//        }
    }
    
    var maintenanceEnergy: Double? {
        guard let healthActiveEnergy, let healthRestingEnergy else {
            return nil
        }
        return healthActiveEnergy + healthRestingEnergy
    }
    
    var title: String {
        guard let maintenanceEnergy else {
            return "Maintenace Energy"
        }
        return maintenanceEnergy.formattedEnergy + " kcal"
    }

    var leadingContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                Haptics.feedback(style: .soft)
                dismiss()
                resetTDEEFormDetents()
            } label: {
                closeButtonLabel
            }
        }
    }

    var principalContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            HStack(alignment: .center) {
                Text("4,024")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text("kcal")
                    .foregroundColor(.secondary)
            }
//            if maintenanceEnergy != nil {
                Text("Your Maintenance Energy")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
//            }
        }
    }
    
    var restingHeader: some View {
        HStack {
            Image(systemName: EnergyComponent.resting.systemImage)
                .matchedGeometryEffect(id: "resting-header-icon", in: namespace)
            Text("Resting Energy")
        }
    }
    
    //TODO: Make these changes
    /// [ ] Have a section for total with matched geometries moving the labels for the components to their sections (and the headers)
    /// [ ] Include a control that lets us switch between both views
    ///     [ ] Maybe have a button on the total itself that expands and collapses it, so when expanded it doesn't show the components inside it, they get moved away to their sections
    
    var formulaSection: some View {
        var topSection: some View {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "function")
                        .foregroundColor(.secondary)
                    Text("Calculated")
                        .foregroundColor(.secondary)
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundColor(Color(.tertiaryLabel))
                        .imageScale(.small)
                }
                Spacer()
                HStack {
                    Text("2,024")
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                    Text("kcal")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 17)
            .padding(.vertical, 15)
        }
        
        var formulaRow: some View {
            HStack {
                HStack {
                    Text("using")
                        .foregroundColor(.secondary)
                    PickerLabel("Katch-McArdle")
                    Text("equation")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 8)
        }
        
        var flowView: some View {
            func label(_ prefix: String, _ string: String) -> some View {
                var backgroundColor: Color {
                    return colorScheme == .light ? Color(hex: "e8e9ea") : Color(hex: "434447")
                }
                return PickerLabel(
                    string,
                    prefix: prefix,
                    systemImage: viewModel.restingEnergyFormulaUsingSyncedHealthData ? nil : "chevron.right",
//                    imageColor: <#T##Color#>,
                    backgroundColor:  viewModel.restingEnergyFormulaUsingSyncedHealthData ? Color(.systemGroupedBackground) : backgroundColor,
                    foregroundColor: viewModel.restingEnergyFormulaUsingSyncedHealthData ? Color(.secondaryLabel) : Color.primary,
                    prefixColor: viewModel.restingEnergyFormulaUsingSyncedHealthData ? Color(.tertiaryLabel) : Color.secondary,
//                    imageScale: <#T##Image.Scale#>,
                    infiniteMaxHeight: false
                )
            }
            
            return FlowView(alignment: .center, spacing: 10, padding: 15) {
                ZStack {
                    Capsule(style: .continuous)
                        .foregroundColor(Color(.clear))
                    HStack(spacing: 5) {
                        Text("with")
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                    .frame(height: 25)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                }
                .fixedSize(horizontal: true, vertical: true)
                Menu {
                    Picker(selection: .constant(true), label: EmptyView()) {
                        Text("Male").tag(true)
                        Text("Female").tag(false)
                    }
                } label: {
                    label("sex", "male")
                }
                Button {
                    viewModel.path.append(.leanBodyMassForm)
                } label: {
                    label("fat", "29 %")
                }
            }
            .padding(.bottom, 5)
        }
        
        let useHealthAppDataBinding = Binding<Bool>(
            get: { viewModel.restingEnergyFormulaUsingSyncedHealthData },
            set: { newValue in
            }
        )
        return FormStyledSection(header: restingHeader, horizontalPadding: 0, verticalPadding: 0) {
            VStack {
                topSection
                formulaRow
                Divider()
                    .frame(width: 300)
                    .padding(.vertical, 5)
                flowView
                Divider()
                    .frame(width: 300)
                    .padding(.vertical, 5)
                HStack {
                    Toggle(isOn: useHealthAppDataBinding) {
                        HStack {
                            appleHealthSymbol
                            Text("\(viewModel.restingEnergyFormulaUsingSyncedHealthData ? "Using " : "Use") Health App Data")
                        }
                    }
                    .toggleStyle(.button)
//                    Spacer()
                }
//                .padding(.leading)
            }
            .padding(.bottom)
            .clipShape(
                RoundedRectangle(cornerRadius: 10)
            )
        }
    }
}

public struct TDEEFormPreview: View {
    public init() { }
    public var body: some View {
        TDEEForm(userUnits: .standard) { profile in
            
        }
    }
}

struct LeftAlignedFlowLayout: Layout {
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let height = calculateRects(origin: CGPoint.zero, width: proposal.width ?? 0, subviews: subviews).last?.maxY ?? 0
        return CGSize(width: proposal.width ?? 0, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        
        calculateRects(origin: bounds.origin, width: bounds.width, subviews: subviews).enumerated().forEach { index, rect in
            let sizeProposal = ProposedViewSize(rect.size)
            subviews[index].place(at: rect.origin, proposal: sizeProposal)
        }
    }
    
    func calculateRects(origin: CGPoint, width: CGFloat, subviews: Subviews) -> [CGRect] {
        
        var nextPosition = origin // was CGPoint.zero
        return subviews.indices.map { index in
            
            let size = subviews[index].sizeThatFits(.unspecified)
            
            var nextHSpacing: CGFloat = 0
            var previousVSpacing: CGFloat = 0
            
            if index > subviews.startIndex {
                let previousIndex = index.advanced(by: -1)
                previousVSpacing = subviews[previousIndex].spacing.distance(to: subviews[index].spacing, along: .vertical)
            }
            
            if index < subviews.endIndex.advanced(by: -1) {
                let nextIndex = index.advanced(by: 1)
                nextHSpacing = subviews[index].spacing.distance(to: subviews[nextIndex].spacing, along: .horizontal)
            }
            
            if nextPosition.x + nextHSpacing + size.width > width {
                nextPosition.x = 0
                nextPosition.y += size.height + previousVSpacing
            }
            
            let thisPosition = nextPosition
            nextPosition.x += nextHSpacing + size.width
            return CGRect(origin: thisPosition, size: size)
        }
    }
}

extension TDEEForm {
    
    var activeEnergyHealthAppPeriodLink: some View {
        Button {
//            viewModel.path.append(.healthAppPeriod)
        } label: {
            HStack(spacing: 5) {
                Text("Average of past 2 weeks")
                    .multilineTextAlignment(.leading)
//                    .foregroundColor(.secondary)
                Image(systemName: "chevron.right")
//                    .foregroundColor(Color(.tertiaryLabel))
                    .fontWeight(.semibold)
                    .imageScale(.small)
            }
            .foregroundColor(.accentColor)
        }
        .buttonStyle(.borderless)
    }
}

