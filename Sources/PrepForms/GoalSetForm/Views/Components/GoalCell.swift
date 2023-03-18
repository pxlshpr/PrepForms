import SwiftUI
import SwiftUISugar
import PrepDataTypes
import SwiftHaptics

let EqualSymbol = "equal.square"

struct GoalCell: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Namespace var namespace
    @ObservedObject var model: GoalModel
    @Binding var showingEquivalentValues: Bool

    @State var lowerBound: Double? = nil
    @State var upperBound: Double? = nil

    @State var shouldShowType: Bool = false
    @State var typeDescription: String? = nil
    @State var typeImage: String? = nil
    
    init(model: GoalModel, showingEquivalentValues: Binding<Bool>) {
        self.model = model
        _showingEquivalentValues = showingEquivalentValues
    }
    
    var body: some View {
        content
            .onChange(of: model.lowerBound, perform: lowerBoundChanged)
            .onChange(of: model.upperBound, perform: upperBoundChanged)
            .onChange(of: model.type, perform: typeChanged)
            .onChange(of: showingEquivalentValues, perform: showingEquivalentValuesChanged)
            .onAppear {
                updateWithAnimation()
            }
    }
    
    var computedShouldShowType: Bool {
        guard model.hasOneBound else { return false }
        guard !showingEquivalentValues else { return false }
        return model.type.showsEquivalentValues
    }
    
    var backgroundColor: Color {
        model.isAutoGenerated ? Color(.secondarySystemGroupedBackground) : Color(.secondarySystemGroupedBackground)
    }
    
    var content: some View {
        var spacing: CGFloat {
            if model.isMissingRequirement, shouldShowType {
                /// If we're showing the missing requirement button in the top right, account for
                /// the button's background pushing the bottom row down enough
                return 10
            } else {
                return 20
            }
        }
        
        return HStack {
            VStack(alignment: .leading, spacing: spacing) {
                topRow
                bottomRow
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 13)
        .padding(.top, 13)
        .background(backgroundColor)
        .cornerRadius(10)
        .padding(.bottom, 10)
    }
    
    func missingRequirementView(_ requirement: GoalRequirement) -> some View {
        var label: some View {
            HStack {
                Text(requirement.message.lowercased())
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .bold()
                Image(systemName: requirement.systemImage)
                    .imageScale(.small)
            }
            .foregroundColor(.accentColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.accentColor.opacity(
                        colorScheme == .dark ? 0.1 : 0.15
                    ))
            )
            .matchedGeometryEffect(id: MatchedGeometryId.missingRequirement, in: namespace)
        }
        
        return Button {
            Haptics.feedback(style: .rigid)
        } label: {
            label
        }
        .disabled(requirement == .workoutDuration)
    }
    
    var topRow: some View {
        @ViewBuilder
        var placeholder: some View {
            if let missingRequirement = model.missingRequirement, shouldShowType {
                missingRequirementView(missingRequirement)
            }
        }
        
        return HStack(alignment: .top) {
            Spacer().frame(width: 2)
            HStack(spacing: 4) {
                Image(systemName: model.type.systemImage)
                    .font(.system(size: 14))
                Text(model.type.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            Spacer()
            autoGeneratedIndicator
            placeholder
            syncedIndicator
        }
        .foregroundColor(labelColor)
    }
    
    @ViewBuilder
    var syncedIndicator: some View {
        if model.isSynced {
            appleHealthBolt
                .imageScale(.small)
        }
    }
    
    @ViewBuilder
    var autoGeneratedIndicator: some View {
        if model.isAutoGenerated {
            Image(systemName: "sparkles")
                .imageScale(.small)
//            Text("Auto generated")
            Text("Auto")
                .textCase(.uppercase)
                .font(.footnote)
        }
    }
    
    var typeText: some View {
        func label_legacy(_ string: String, image: String) -> some View {
            HStack {
                Text(string)
                Image(systemName: image)
            }
            .foregroundColor(Color(.secondaryLabel))
            .font(.footnote)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color(.tertiarySystemFill))
            )
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity))
            )
        }
        
        func label(_ string: String, image: String) -> some View {
            HStack {
                Text(string)
                Image(systemName: image)
            }
            .foregroundColor(Color(.secondaryLabel))
            .font(.system(.subheadline, design: .rounded, weight: .medium))
//            .transition(.asymmetric(
//                insertion: .move(edge: .top).combined(with: .opacity),
//                removal: .move(edge: .top).combined(with: .opacity))
//            )
        }
        
        return Group {
            if shouldShowType, let typeDescription, let typeImage {
//                label_legacy(typeDescription, image: typeImage)
                label(typeDescription, image: typeImage)
            }
        }
    }
    
    var labelColor: Color {
        guard !model.isAutoGenerated else {
            return Color(.tertiaryLabel)
        }
        guard !isEmpty else {
            return Color(.secondaryLabel)
        }
        return model.type.labelColor(for: colorScheme)
    }
    
    var isEmpty: Bool {
        model.lowerBound == nil && model.upperBound == nil
    }
    
    var height: CGFloat {
        !showingEquivalentValues && shouldShowType ? 50 : 35
    }
    
    var bottomRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                bottomRowTexts
                typeText
            }
            Spacer()
        }
        .frame(height: height)
    }
    
    var placeholderString: String? {
        guard let placeholderText = model.placeholderText else {
            return nil
        }
        /// If the goal has at least one value
        if model.hasOneBound {
            /// Only show the placeholder text (if available) when showing equivalent values
            guard showingEquivalentValues else {
                return nil
            }
        }
        
        return placeholderText
    }
    
    var placeholderTextColor: Color {
        model.placeholderTextColor ?? Color(.quaternaryLabel)
    }
    
    @ViewBuilder
    var bottomRowTexts: some View {
        if model.type.showsEquivalentValues && showingEquivalentValues {
            equivalentTexts
//                .transition(.asymmetric(
//                    insertion: .move(edge: .bottom).combined(with: .opacity),
//                    removal: .move(edge: .bottom).combined(with: .opacity)
//                ))

        } else {
            texts
//                .transition(.asymmetric(
//                    insertion: .move(edge: .top).combined(with: .opacity),
//                    removal: .move(edge: .top).combined(with: .opacity)
//                ))
        }
    }
    
    var equalSymbol: some View {
        Image(systemName: EqualSymbol)
            .foregroundColor(Color(.secondaryLabel))
//            .transition(.asymmetric(
//                insertion: .move(edge: .leading),
//                removal: .scale.combined(with: .opacity).combined(with: .move(edge: .bottom))
//            ))
    }
    
    @ViewBuilder
    var disclosureArrow: some View {
        if !model.isAutoGenerated {
            Image(systemName: "chevron.forward")
                .font(.system(size: 14))
                .foregroundColor(Color(.tertiaryLabel))
                .fontWeight(.semibold)
        }
    }
    
    var unitString: String {
        if showingEquivalentValues, let unitString = model.equivalentUnitString {
            return unitString
        } else {
            return model.type.unitString
        }
    }
    
    var computedUpperBound: Double? {
        if showingEquivalentValues, let upperBound = model.equivalentUpperBound {
            return upperBound
        } else {
            return model.upperBound ?? 0
        }
    }
    
    var computedLowerBound: Double? {
        if showingEquivalentValues, let lowerBound = model.equivalentLowerBound {
            return lowerBound
        } else {
            return model.lowerBound
        }
    }
    
//    func amountAndUnitTexts_legacy(_ amount: Double, _ unit: String?) -> some View {
//        HStack(alignment: .firstTextBaseline, spacing: 3) {
//            amountText(amount)
//                .multilineTextAlignment(.leading)
//            if !isEmpty, let unit {
//                unitText(unit)
//            }
//        }
//    }
    
    func showingEquivalentValuesChanged(_ newValue: Bool) {
        updateWithAnimation()
    }
    
    func lowerBoundChanged(_ newValue: Double?) {
        updateWithAnimation()
    }
    
    func upperBoundChanged(_ newValue: Double?) {
        updateWithAnimation()
    }

    func typeChanged(_ newValue: GoalType) {
        updateWithAnimation()
    }

    func updateWithAnimation() {
        withAnimation {
            self.lowerBound = computedLowerBound
            self.upperBound = computedUpperBound
            self.shouldShowType = computedShouldShowType
            self.typeDescription = model.type.accessoryDescription
            self.typeImage = model.type.accessorySystemImage
        }
    }

    func amountAndUnitTexts(_ amount: Double, unit: String?, prefix: String?) -> some View {
        Color.clear
            .animatedGoalCellValueModifier(
                value: amount,
                unitString: unit,
                prefixString: prefix,
                isAutoGenerated: model.isAutoGenerated
            )
        
//        HStack(alignment: .firstTextBaseline, spacing: 3) {
//            amountText(amount)
//                .multilineTextAlignment(.leading)
//            if !isEmpty, let unit {
//                unitText(unit)
//            }
//        }
    }

    func amountText_legacy(_ double: Double) -> Text {
        var foregroundColor: Color {
            guard !model.isAutoGenerated else {
                return Color(.tertiaryLabel)
            }
            return isEmpty ? Color(.quaternaryLabel) : Color(.label)
        }

        return Text("\(double.formattedGoalValue)")
            .foregroundColor(foregroundColor)
            .font(.system(size: isEmpty ? 20 : 28, weight: .medium, design: .rounded))
    }
    
//    func amountText(_ double: Double) -> some View {
//        var foregroundColor: Color {
//            guard !model.isAutoGenerated else {
//                return Color(.tertiaryLabel)
//            }
//            return isEmpty ? Color(.quaternaryLabel) : Color(.label)
//        }
//
//        return Color.clear
//            .animatedGoalCellValueModifier(value: double, color: foregroundColor)
//    }
    
    func unitText(_ string: String) -> Text {
        var foregroundColor: Color {
            model.isAutoGenerated ? Color(.tertiaryLabel) : Color(.secondaryLabel)
        }
        
        return Text(string)
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .bold()
            .foregroundColor(foregroundColor)
    }
    
    var texts: some View {
        
        var texts: some View {
            HStack {
                if let lowerBound {
//                    if upperBound == nil {
//                        accessoryText("at least")
//                    }
                    amountAndUnitTexts(
                        lowerBound,
                        unit: upperBound == nil ? unitString : nil,
                        prefix: upperBound == nil ? "at least" : nil
                    )
                }
                if let upperBound {
                    amountAndUnitTexts(
                        upperBound,
                        unit: unitString,
                        prefix: lowerBound == nil ? "at most" : "to"
                    )
                    .opacity(upperBound == 0 ? 0 : 1)
                }
            }
        }

        return Group {
            if model.isEmpty {
                placeholderText("Set Goal")
//            } else if let requirement = model.missingRequirement {
//                placeholderText(requirement.message)
//            if let placeholderString {
//                placeholderText(placeholderString)
            } else {
                texts
            }
        }
    }
    
    func placeholderText(_ string: String) -> some View {
        Text(string)
            .foregroundColor(placeholderTextColor)
            .font(.system(size: 20, weight: .medium, design: .rounded))
    }
    
    var equivalentTexts: some View {
        var filled: some View {
            HStack {
                if let lowerBound {
                    amountAndUnitTexts(
                        lowerBound,
                        unit: upperBound == nil ? unitString : nil,
                        prefix: upperBound == nil ? "at least" : nil
                    )
                }
                if let upperBound {
                    amountAndUnitTexts(
                        upperBound,
                        unit: unitString,
                        prefix: lowerBound == nil ? "at most" : "to"
                    )
                }
            }
        }
        
        return Group {
            if model.isEmpty {
                placeholderText("Set Goal")
            } else if let requirement = model.missingRequirement {
                missingRequirementView(requirement)
            } else {
                filled
            }
        }
    }
    
    enum MatchedGeometryId: Hashable {
        case missingRequirement
    }
    
    func accessoryText(_ string: String) -> some View {
        Text(string)
            .font(.title3)
            .textCase(.lowercase)
            .foregroundColor(Color(.tertiaryLabel))
//            .alignmentGuide(.goalCellTextAlignment) { $0[.bottom] }
    }
}


extension VerticalAlignment {
    
    private struct GoalCellTextAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[VerticalAlignment.bottom]
        }
    }

    static let goalCellTextAlignment: VerticalAlignment = VerticalAlignment(
        GoalCellTextAlignment.self
    )
}

struct AnimatableGoalCellValueModifier: Animatable, ViewModifier {
    
    @Environment(\.colorScheme) var colorScheme
    @State var size: CGSize = .zero

    var value: Double
    var unitString: String?
    var prefixString: String?
    var isAutoGenerated: Bool
    
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
    
    var valueText: some View {
        var foregroundColor: Color {
            isAutoGenerated ? Color(.tertiaryLabel) : Color(.label)
        }
        
        return Text(value.formattedGoalValue)
            .font(.system(size: 28, weight: .medium, design: .rounded))
            .foregroundColor(foregroundColor)
    }
    
    var unitText: some View {
        
        var foregroundColor: Color {
            isAutoGenerated ? Color(.tertiaryLabel) : Color(.secondaryLabel)
        }
        
        return Group {
            if let unitString {
                Text(unitString)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .bold()
                    .foregroundColor(foregroundColor)
                    .animation(.default, value: unitString)
            }
        }
    }
    
    @ViewBuilder
    var prefixText: some View {
        if let prefixString {
            Text(prefixString)
                .font(.title3)
                .textCase(.lowercase)
                .foregroundColor(Color(.tertiaryLabel))
        }
    }
    
    var animatedLabel: some View {
        HStack(alignment: .firstTextBaseline) {
            prefixText
                .fixedSize(horizontal: true, vertical: false)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                valueText
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: true, vertical: false)
                unitText
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.trailing)
        .fixedSize(horizontal: true, vertical: false)
    }
}

public extension View {
    func animatedGoalCellValueModifier(
        value: Double,
        unitString: String?,
        prefixString: String?,
        isAutoGenerated: Bool
    ) -> some View {
        modifier(AnimatableGoalCellValueModifier(
            value: value,
            unitString: unitString,
            prefixString: prefixString,
            isAutoGenerated: isAutoGenerated
        ))
    }
}
