import SwiftUI
import SwiftUISugar
import PrepDataTypes
import SwiftHaptics

extension Double {
    var isGreaterThan0: Bool {
        self > 0
    }
}

extension Optional where Wrapped == Double {
    var isGreaterThan0: Bool {
        return self?.isGreaterThan0 ?? true
    }
}

extension GoalModel {
    func cellLowerBound(_ showingEquivalentValues: Bool) -> Double? {
        if showingEquivalentValues, let equivalentLowerBound {
            return equivalentLowerBound
        } else {
            return lowerBound
        }
    }
    
    func cellUpperBound(_ showingEquivalentValues: Bool) -> Double? {
        if showingEquivalentValues, let equivalentUpperBound {
            return equivalentUpperBound
        } else {
            return upperBound ?? 0
        }
    }

    func shouldShowType(_ showingEquivalentValues: Bool) -> Bool {
        guard hasOneBound else { return false }
        guard !showingEquivalentValues else { return false }
        return type.showsEquivalentValues
    }
}
struct GoalCell: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Namespace var namespace
    @ObservedObject var model: GoalModel
    @Binding var showingEquivalentValues: Bool

    @State var lowerBound: Double?
    @State var upperBound: Double?
    @State var hasValidUpperBound: Bool
    @State var hasValidLowerBound: Bool
    @State var lowerBoundPrefix: String?
    @State var upperBoundPrefix: String?
    @State var lowerBoundSuffix: String?
    @State var upperBoundSuffix: String?
    @State var typeDescription: String?
    @State var typeImage: String?
    @State var shouldShowType: Bool

    let actionHandler: (Action) -> ()

    enum Action {
        case tappedMissingRequirement(GoalRequirement)
    }
    
    let didSetBiometrics = NotificationCenter.default.publisher(for: .didSetBiometrics)
    init(
        model: GoalModel,
        showingEquivalentValues: Binding<Bool>,
        actionHandler: @escaping (Action) -> ()
    ) {
        self.model = model
        self.actionHandler = actionHandler
        
        let isEquivalent = showingEquivalentValues.wrappedValue
        let lowerBound = model.cellLowerBound(isEquivalent)
        let upperBound = model.cellUpperBound(isEquivalent)
        _lowerBound = State(initialValue: lowerBound)
        _upperBound = State(initialValue: upperBound)
        _hasValidLowerBound = State(initialValue: lowerBound.isGreaterThan0)
        _hasValidUpperBound = State(initialValue: upperBound.isGreaterThan0)
        _lowerBoundPrefix = State(initialValue: model.lowerBoundPrefix(equivalent: isEquivalent))
        _upperBoundPrefix = State(initialValue: model.upperBoundPrefix(equivalent: isEquivalent))
        _lowerBoundSuffix = State(initialValue: model.lowerBoundSuffix(equivalent: isEquivalent))
        _upperBoundSuffix = State(initialValue: model.upperBoundSuffix(equivalent: isEquivalent))
        _typeDescription = State(initialValue: model.type.accessoryDescription)
        _typeImage = State(initialValue: model.type.accessorySystemImage)
        _shouldShowType = State(initialValue: model.shouldShowType(isEquivalent))

        _showingEquivalentValues = showingEquivalentValues
    }
    
    var body: some View {
        content
            .onChange(of: model.lowerBound, perform: lowerBoundChanged)
            .onChange(of: model.upperBound, perform: upperBoundChanged)
            .onChange(of: model.type, perform: typeChanged)
            .onChange(of: showingEquivalentValues, perform: showingEquivalentValuesChanged)
            .onReceive(didSetBiometrics, perform: didSetBiometrics)
    }
    
    func didSetBiometrics(_ notification: Notification) {
        updateWithAnimation()
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
        Button {
            Haptics.feedback(style: .rigid)
            actionHandler(.tappedMissingRequirement(requirement))
        } label: {
            GoalRequirementLabel(requirement: requirement)
        }
        .matchedGeometryEffect(
            id: MatchedGeometryId.missingRequirement,
            in: namespace
        )
        .disabled(!requirement.isBiometric)
    }
    
    var topRow: some View {
        @ViewBuilder
        var placeholder: some View {
            if let missingRequirement = model.missingRequirement, shouldShowType {
                missingRequirementView(missingRequirement)
                    .offset(x: 10, y: -7)
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
        
        func label(_ string: String, image: String?) -> some View {
            HStack {
                Text(string)
                if let image {
                    Image(systemName: image)
                }
            }
            .foregroundColor(Color(.secondaryLabel))
            .font(.system(.subheadline, design: .rounded, weight: .medium))
//            .transition(.asymmetric(
//                insertion: .move(edge: .top).combined(with: .opacity),
//                removal: .move(edge: .top).combined(with: .opacity))
//            )
        }
        
        return Group {
            if shouldShowType, let typeDescription {
                label(typeDescription, image: typeImage)
            }
        }
    }

    var bottomRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                texts
                typeText
            }
            Spacer()
        }
    }
    
    var texts: some View {
        var unitText: some View {
            var foregroundColor: Color {
                model.isAutoGenerated ? Color(.tertiaryLabel) : Color(.secondaryLabel)
            }
            
            var unitString: String? {
                switch (lowerBound, upperBound) {
                case (.some, .some), (nil, .some):
                    return upperBoundSuffix
                case (.some, nil):
                    return lowerBoundSuffix
                case (nil, nil):
                    return nil
                }
            }
            
            return Group {
                if let unitString {
                    Text(unitString)
                        .foregroundColor(foregroundColor)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                }
            }
        }
        
        var filled: some View {
            HStack(spacing: 5) {
                if let lowerBound, hasValidLowerBound {
                    amountAndUnitTexts(
                        lowerBound,
                        unit: lowerBoundSuffix,
                        prefix: lowerBoundPrefix
                    )
                }
                if let upperBound {
                    amountAndUnitTexts(
                        upperBound,
                        unit: upperBoundSuffix,
                        prefix: upperBoundPrefix
                    )
                    .opacity(upperBound == 0 ? 0 : 1)
                }
            }
        }
        
        return Group {
            if model.isEmpty {
                placeholderText("Set Goal")
            } else if let requirement = model.missingRequirement, model.type.showsEquivalentValues, showingEquivalentValues {
                missingRequirementView(requirement)
            } else {
                filled
            }
        }
    }
    
    //MARK: - Components
    
    func placeholderText(_ string: String) -> some View {
        var color: Color {
            model.placeholderTextColor ?? Color(.quaternaryLabel)
        }
        
        return Text(string)
            .foregroundColor(color)
            .font(.system(size: 20, weight: .medium, design: .rounded))
    }
    
    func amountAndUnitTexts(_ amount: Double, unit: String?, prefix: String?) -> some View {
        Color.clear
            .animatedGoalCellValueModifier(
                value: amount,
                unitString: unit,
                prefixString: prefix,
                isAutoGenerated: model.isAutoGenerated
            )
    }
    
    //MARK: - Convenience
    
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
    
    var backgroundColor: Color {
        model.isAutoGenerated
        ? Color(.secondarySystemGroupedBackground)
        : Color(.secondarySystemGroupedBackground)
    }
    
    //MARK: - Computed
    
    var computedShouldShowType: Bool {
        model.shouldShowType(showingEquivalentValues)
//        guard model.hasOneBound else { return false }
//        guard !showingEquivalentValues else { return false }
//        return model.type.showsEquivalentValues
    }
    
    var computedUpperBound: Double? {
        model.cellUpperBound(showingEquivalentValues)
//        if showingEquivalentValues, let upperBound = model.equivalentUpperBound {
//            return upperBound
//        } else {
//            return model.upperBound ?? 0
//        }
    }
    
    var computedLowerBound: Double? {
        model.cellLowerBound(showingEquivalentValues)
//        if showingEquivalentValues, let lowerBound = model.equivalentLowerBound {
//            return lowerBound
//        } else {
//            return model.lowerBound
//        }
    }

    var computedHasValidLowerBound: Bool {
        lowerBound.isGreaterThan0
//        guard let lowerBound else { return false }
//        return lowerBound > 0
    }
    
    var computedHasValidUpperBound: Bool {
        upperBound.isGreaterThan0
//        guard let upperBound else { return false }
//        return upperBound > 0
    }

    //MARK: - Actions
    
    func updateWithAnimation(_ animated: Bool = true) {
        
        func updates() {
            self.lowerBound = computedLowerBound
            self.upperBound = computedUpperBound
            
            self.hasValidLowerBound = computedHasValidLowerBound
            self.hasValidUpperBound = computedHasValidUpperBound
            
            self.lowerBoundPrefix = model.lowerBoundPrefix(equivalent: showingEquivalentValues)
            self.upperBoundPrefix = model.upperBoundPrefix(equivalent: showingEquivalentValues)
            self.lowerBoundSuffix = model.lowerBoundSuffix(equivalent: showingEquivalentValues)
            self.upperBoundSuffix = model.upperBoundSuffix(equivalent: showingEquivalentValues)

            self.typeDescription = model.type.accessoryDescription
            self.typeImage = model.type.accessorySystemImage
            self.shouldShowType = computedShouldShowType
        }
        
        if animated {
            withAnimation {
                updates()
            }
        } else {
            updates()
        }
    }
    
    func showingEquivalentValuesChanged(_ newValue: Bool) {
        updateWithAnimation()
    }
    
    func lowerBoundChanged(_ newValue: Double?) {
        updateWithAnimation(model.animateNextBoundChange)
        model.animateNextBoundChange = true
    }
    
    func upperBoundChanged(_ newValue: Double?) {
        updateWithAnimation(model.animateNextBoundChange)
        model.animateNextBoundChange = true
    }

    func typeChanged(_ newValue: GoalType) {
        updateWithAnimation()
    }
    
    enum MatchedGeometryId: Hashable {
        case missingRequirement
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

    let style: AnimatableGoalValueStyle
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
            .font(style.valueFont)
            .foregroundColor(style.valueColor(isAutoGenerated: isAutoGenerated))
    }
    
    var unitText: some View {
        
        var foregroundColor: Color {
            isAutoGenerated ? Color(.tertiaryLabel) : Color(.secondaryLabel)
        }
        
        return Group {
            if let unitString {
                Text(unitString)
                    .foregroundColor(style.unitColor(isAutoGenerated: isAutoGenerated))
                    .font(style.unitFont)
                    .transition(.asymmetric(insertion: .opacity, removal: .scale))
            }
        }
    }
    
    @ViewBuilder
    var prefixText: some View {
        if let prefixString {
            Text(prefixString)
                .textCase(.lowercase)
                .font(style.prefixFont)
                .foregroundColor(style.prefixColor)
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
        isAutoGenerated: Bool,
        style: AnimatableGoalValueStyle = .cell
    ) -> some View {
        modifier(AnimatableGoalCellValueModifier(
            style: style,
            value: value,
            unitString: unitString,
            prefixString: prefixString,
            isAutoGenerated: isAutoGenerated
        ))
    }
}

struct GoalRequirementLabel: View {
    
    @Environment(\.colorScheme) var colorScheme
    let requirement: GoalRequirement
    
    @ViewBuilder
    var body: some View {
        if requirement.isBiometric {
            biometricLabel
        } else {
            label
        }
    }
    
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
    }
    
    var biometricLabel: some View {
        PickerLabel(
            requirement.description,
            prefix: "set",
            prefixImage: requirement.systemImage,
            systemImage: "chevron.forward",
            imageColor: Color.white.opacity(0.75),
            backgroundColor: .accentColor,
            foregroundColor: .white,
            prefixColor: Color.white.opacity(0.75),
            imageScale: .small
        )
    }
}
