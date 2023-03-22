import SwiftUI
import SwiftUISugar
import SwiftHaptics
import PrepDataTypes
import PrepCoreDataStack

public struct GoalForm: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var goalSetModel: GoalSetForm.Model
    @ObservedObject var model: GoalModel
    
    let didTapDelete: (GoalModel) -> ()
    
    @State var leftValue: Double?
    @State var rightValue: Double?
    @State var equivalentLeftValue: Double?
    @State var equivalentRightValue: Double?
    @State var usesSingleValue: Bool
    @State var hasEquivalentValues: Bool
    @State var showSyncedIndicator: Bool
    @State var hasValidUpperBound: Bool
    @State var hasValidLowerBound: Bool
    @State var lowerBoundPrefix: String?
    @State var upperBoundPrefix: String?
    @State var lowerBoundSuffix: String?
    @State var upperBoundSuffix: String?

    let equivalentUnitString: String?

    @State var presentedSheet: Sheet? = nil

    public init(goalModel: GoalModel, didTapDelete: @escaping ((GoalModel) -> ())) {
        self.model = goalModel
//        _model = StateObject(wrappedValue: goalModel)
        self.didTapDelete = didTapDelete
        
        _leftValue = State(initialValue: goalModel.lowerBound)
        _rightValue = State(initialValue: goalModel.upperBound)
        _equivalentLeftValue = State(initialValue: goalModel.equivalentLowerBound)
        _equivalentRightValue = State(initialValue: goalModel.equivalentUpperBound)
        _usesSingleValue = State(initialValue: goalModel.usesSingleValue)
        _hasEquivalentValues = State(initialValue: goalModel.hasEquivalentValues)
        _showSyncedIndicator = State(initialValue: goalModel.showsSyncedIndicator)
        _hasValidLowerBound = State(initialValue: goalModel.hasValidLowerBound)
        _hasValidUpperBound = State(initialValue: goalModel.hasValidUpperBound)
        _lowerBoundPrefix = State(initialValue: goalModel.lowerBoundPrefix(equivalent: true))
        _upperBoundPrefix = State(initialValue: goalModel.upperBoundPrefix(equivalent: true))
        _lowerBoundSuffix = State(initialValue: goalModel.lowerBoundSuffix(equivalent: true))
        _upperBoundSuffix = State(initialValue: goalModel.upperBoundSuffix(equivalent: true))
        self.equivalentUnitString = goalModel.equivalentUnitString
    }
    
    public var body: some View {
        quickForm
            .presentationDetents([.height(200)])
            .onDisappear(perform: disappeared)
            .sheet(item: $presentedSheet) { sheet(for: $0) }
            .onChange(of: model.type) { [oldValue = model.type] newValue in
                typeChanged(from: oldValue, to: newValue)
            }
            .onChange(of: model.lowerBound, perform: lowerBoundChanged)
            .onChange(of: model.upperBound, perform: upperBoundChanged)
    }
    
    func typeChanged(from oldType: GoalType, to newType: GoalType) {
        if oldType.isDualBounded, newType.isSingleBounded,
           leftValue == nil, rightValue != nil
        {
            model.lowerBound = model.upperBound
            model.upperBound = nil
        }
        updateWithAnimation()
    }

    func upperBoundChanged(_ newValue: Double?) {
        updateWithAnimation()
    }

    func lowerBoundChanged(_ newValue: Double?) {
        updateWithAnimation()
    }

    func updateWithAnimation(_ animated: Bool = true) {
        func updates() {
            leftValue = model.lowerBound
            rightValue = model.upperBound
            equivalentLeftValue = model.equivalentLowerBound
            equivalentRightValue = model.equivalentUpperBound
            usesSingleValue = model.usesSingleValue
            hasEquivalentValues = model.hasEquivalentValues
            showSyncedIndicator = model.showsSyncedIndicator
            hasValidLowerBound = model.hasValidLowerBound
            hasValidUpperBound = model.hasValidUpperBound

            lowerBoundPrefix = model.lowerBoundPrefix(equivalent: true)
            upperBoundPrefix = model.upperBoundPrefix(equivalent: true)
            lowerBoundSuffix = model.lowerBoundSuffix(equivalent: true)
            upperBoundSuffix = model.upperBoundSuffix(equivalent: true)
        }
        
        if animated {
            withAnimation {
                updates()
            }
        } else {
            updates()
        }
    }

    var quickForm: some View {
        QuickForm(
            title: model.description,
            lighterBackground: false,
            deleteAction: deleteActionBinding
        ) {
            valuesContent
        }
    }
    
    @ViewBuilder
    func sheet(for sheet: Sheet) -> some View {
        switch sheet {
        case .lowerBound:
            valueForm(for: .left)
        case .upperBound:
            valueForm(for: .right)
        case .unit:
            unitPicker
        default:
            EmptyView()
        }
    }
    
    var unitPicker: some View {
        GoalUnitPicker(model: model)
    }
    
    func setValue(_ value: Double?, for side: Side) {
        switch side {
        case .left:
            model.lowerBound = value
            withAnimation {
                self.leftValue = value
                self.equivalentLeftValue = model.equivalentLowerBound
            }
        case .right:
            model.upperBound = value
            withAnimation {
                self.rightValue = value
                self.equivalentRightValue = model.equivalentUpperBound
            }
        }
        model.goalSetModel.createImplicitGoals()
    }

    func valueForm(for side: Side) -> some View {
        func handleNewValue(_ newValue: Double?) {
            setValue(newValue, for: side)
        }
        
        return GoalValueForm(
            goalModel: model,
            side: side,
            value: valueForSide(side),
            handleNewValue: handleNewValue
        )
    }
    
    @State var buttonsHeight: CGFloat = 0
    
    var valuesContent: some View {
        var topRow: some View {
            var valuesButtons: some View {
                var buttonsLayer: some View {
                    HStack {
                        buttonForSide(.left)
                        if !usesSingleValue {
                            buttonForSide(.right)
                        }
                    }
                }
                
                @ViewBuilder
                var swapValuesButtonLayer: some View {
                    if !usesSingleValue {
                        VStack {
                            swapValuesButton
                                .padding(.top, 2)
                            Color.clear
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: buttonsHeight, alignment: .top)
                    }
                }
                
                return ZStack {
                    buttonsLayer
                        .readSize { size in
                            self.buttonsHeight = size.height
                        }
                    swapValuesButtonLayer
                }
            }
            
            return HStack {
                valuesButtons
                unitButton
            }
        }
        
        var bottomRow: some View {
            HStack {
                if let missingRequirement = model.missingRequirement {
                    Button {
                        
                    } label: {
                        GoalRequirementLabel(requirement: missingRequirement)
                    }
                    .disabled(!missingRequirement.isBiometric)
                    .fixedSize(horizontal: false, vertical: true)
                } else if hasEquivalentValues {
//                    equivalentLabel
                    equivalentTexts
                }
                Spacer()
                syncedButton
            }
        }
        
        return VStack(spacing: 10) {
            topRow
            bottomRow
            Spacer() /// so that contents sticks to top when dragging form upwards
        }
        .padding(.horizontal, 20)
    }
    
    func valueForSide(_ side: Side) -> Double? {
        switch side {
        case .left:     return leftValue
        case .right:    return rightValue
        }
    }

    func buttonForSide(_ side: Side) -> some View {
        
        var valueString: String? {
            valueForSide(side)?.formattedGoalValue
        }

        var headerString: String? {
            var haveBothBounds: Bool {
                leftValue != nil && rightValue != nil
            }
            
            guard !usesSingleValue else {
                return nil
//                return "within"
           }

            switch side {
            case .left:     return haveBothBounds ? "from" : "at least"
            case .right:    return haveBothBounds ? "to" : "at most"
            }
        }
        
        @ViewBuilder
        var headerLabel: some View {
            if let headerString {
                Text(headerString)
                    .foregroundColor(Color(.tertiaryLabel))
            }
        }
        
        var largerValue: Double? {
            guard let leftValue else {
                return rightValue
            }
            guard let rightValue else {
                return leftValue
            }
            return leftValue.formattedGoalValue.count > rightValue.formattedGoalValue.count
            ? leftValue : rightValue
        }
        
        var button: some View {
            
            var label: some View {
                var value: Double? {
                    switch side {
                    case .left: return leftValue
                    case .right: return rightValue
                    }
                }
                
                return Group {
                    if let value {
                        Color.clear
                            .animatedGoalValueModifier(value: value, fontSize: fontSize)
                    } else {
                        Text("optional")
                            .font(.system(size: 20, weight: .regular, design: .default))
                            .opacity(0.5)
                    }
                }
                .foregroundColor(.accentColor)
                .frame(height: 60)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color.accentColor.opacity(
                            colorScheme == .dark ? 0.1 : 0.15
                        ))
                )
            }
            
            var fontSize: CGFloat {
                let DefaultSize = 30.0
                let MediumSize = 25.0
                let SmallestSize = 15.0
                
                guard let largerValue else {
                    return DefaultSize
                }
                
                let count = largerValue.formattedGoalValue.count
                switch count {
                case ...3:
                    return DefaultSize
                case 4...5:
                    return MediumSize
                default:
                    return SmallestSize
                }
            }
            
            
            return Button {
                present(side == .left ? .lowerBound : .upperBound)
            } label: {
                label
            }
        }
        
        return VStack(alignment: .customCenter, spacing: 5) {
            headerLabel
            button
        }
    }
    
    func present(_ sheet: Sheet) {
        
        func present() {
            Haptics.feedback(style: .soft)
            presentedSheet = sheet
        }

        func delayedPresent() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                present()
            }
        }

        if presentedSheet != nil {
            presentedSheet = nil
            delayedPresent()
        } else {
            present()
        }
    }
    
    var deleteActionBinding: Binding<FormConfirmableAction?> {
        Binding<FormConfirmableAction?>(
            get: {
                FormConfirmableAction(
                    buttonImage: "trash.circle.fill",
                    handler: {
                        didTapDelete(model)
                    }
                )
            },
            set: { _ in }
        )
    }
    
    func disappeared() {
        model.validateEnergy()
        model.validateNutrient()
        goalSetModel.createImplicitGoals()
    }
    
    var syncedButton: some View {
        var label: some View {
            HStack {
//                appleHealthBolt
                Image(systemName: "bolt.horizontal.fill")
                    .symbolRenderingMode(.palette)
                    .imageScale(.small)
                    .foregroundStyle(.green.gradient)
                    .grayscale(model.isSynced ? 0 : 1)
                Text("\(model.isSynced ? "" : "not ")synced")
                    .foregroundColor(Color(.tertiaryLabel))
                    .font(.system(size: 15, weight: .medium, design: .rounded))
//                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .foregroundColor(Color(.quaternarySystemFill))
            )
        }
        
        var button: some View {
            Button {
                
            } label: {
                label
            }
        }
        
        return Group {
            if showSyncedIndicator {
                button
            }
        }
    }
    
    @Namespace var namespace
    
    var equivalentTexts: some View {
        func amountAndUnitTexts(_ amount: Double, unit: String?, prefix: String?) -> some View {
            Color.clear
                .animatedGoalCellValueModifier(
                    value: amount,
                    unitString: unit,
                    prefixString: prefix,
                    isAutoGenerated: model.isAutoGenerated,
                    style: .form
                )
        }

        func texts(with unitString: String) -> some View {
            HStack(spacing: 5) {
                if let equivalentLeftValue {
                    amountAndUnitTexts(
                        equivalentLeftValue,
                        unit: lowerBoundSuffix,
                        prefix: lowerBoundPrefix
                    )
                }
                if let equivalentRightValue {
                    amountAndUnitTexts(
                        equivalentRightValue,
                        unit: upperBoundSuffix,
                        prefix: upperBoundPrefix
                    )
                }
            }
        }
        
        return Group {
            if let equivalentUnitString, hasAtLeastOneEquivalentValue {
                HStack {
                    Image(systemName: "equal.square.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(.quaternaryLabel))
                    texts(with: equivalentUnitString)
                }
            }
        }
    }
    
    var hasAtLeastOneEquivalentValue: Bool {
        equivalentLeftValue != nil || equivalentRightValue != nil
    }
    
    
    //MARK: Legacy (To be removed)
    var equivalentLabel: some View {
        
        var leftValue: Double? {
            equivalentLeftValue
        }
        
        var rightValue: Double? {
            equivalentRightValue
        }
        
        func label(leftValue: Double?, rightValue: Double?, unitString: String) -> some View {
            return HStack {
                Image(systemName: "equal.square.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(.quaternaryLabel))
                HStack(spacing: 5) {
                    if let leftValue {
                        Color.clear
                            .animatedGoalEquivalentValueModifier(value: leftValue)
                            .alignmentGuide(.customCenter) { context in
                                context[HorizontalAlignment.center]
                            }
                    }
                    if let rightValue {
                        Text("to")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(.tertiaryLabel))
                        Color.clear
                            .animatedGoalEquivalentValueModifier(value: rightValue)
                            .alignmentGuide(.customCenter) { context in
                                context[HorizontalAlignment.center]
                            }
                    }
                    Text(unitString)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }
        }
        
        
        return Group {
            if hasAtLeastOneEquivalentValue, let equivalentUnitString {
                label(leftValue: leftValue, rightValue: rightValue, unitString: equivalentUnitString)
            } else {
                Color.clear
            }
        }
        .frame(height: 35)
        .fixedSize(horizontal: true, vertical: false)
    }
    
    var unitButton: some View {
        var label: some View {
            HStack(spacing: 2) {
                VStack(alignment: .center) {
                    Text(model.unitStrings.0)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .fontWeight(.semibold)
                    if let secondaryUnitString = model.unitStrings.1 {
                        Text(secondaryUnitString)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .fontWeight(.medium)
                            .opacity(0.75)
                    }
                }
                Image(systemName: "chevron.up.chevron.down")
                    .imageScale(.small)
            }
            .foregroundColor(.accentColor)
//            .padding(.vertical, 15)
            .padding(.horizontal, 15)
//            .padding(.leading, 10)
//            .padding(.trailing, 7)
            .frame(minHeight: 60)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(
                        Color.accentColor.opacity(colorScheme == .dark ? 0.1 : 0.15)
                    )
            )
            .fixedSize(horizontal: true, vertical: false)
        }
        
        /// Used to align the buttons horizontally
        @ViewBuilder
        var headerPlaceholder: some View {
            if !usesSingleValue {
                Text("...")
                    .foregroundColor(Color(.tertiaryLabel))
                    .opacity(0)
            }
        }
        
        return Button {
            present(.unit)
        } label: {
            VStack(spacing: 5) {
                headerPlaceholder
                label
            }
        }
    }
    
    var swapValuesButton: some View {
        enum Direction {
            case left
            case right
            
            var image: String {
                switch self {
                case .left:
                    return "rectangle.lefthalf.inset.filled.arrow.left"
                case .right:
                    return "rectangle.righthalf.inset.filled.arrow.right"
                }
            }
        }
        
        var direction: Direction? {
            if model.upperBound != nil, model.lowerBound == nil {
                return .left
            }
            if model.lowerBound != nil, model.upperBound == nil {
                return .right
            }
            return nil
        }

        return Group {
            if let direction {
                Button {
                    Haptics.feedback(style: .rigid)
                    switch direction {
                    case .right:
                        model.upperBound = model.lowerBound
                        model.lowerBound = nil
                    case .left:
                        model.lowerBound = model.upperBound
                        model.upperBound = nil
                    }
                    model.animateNextBoundChange = false
                    updateWithAnimation()
               } label: {
                   Image(systemName: direction.image)
                       .foregroundColor(.accentColor)
               }
            }
        }
    }
    
    var saveButton: some View {
        var buttonWidth: CGFloat { UIScreen.main.bounds.width - (20 * 2.0) }
        var xPosition: CGFloat { UIScreen.main.bounds.width / 2.0 }
        var yPosition: CGFloat { (52.0/2.0) + 16.0 }
        var shadowOpacity: CGFloat { 0 }
        var buttonHeight: CGFloat { 52 }
        var buttonCornerRadius: CGFloat { 10 }
        var shadowSize: CGFloat { 2 }
        var foregroundColor: Color {
//            (colorScheme == .light && saveIsDisabled) ? .black : .white
            .white
        }
        
        return Button {
//            tappedSave()
        } label: {
//            Text(existingMeal == nil ? "Add" : "Save")
            Text("Save")
                .bold()
                .foregroundColor(foregroundColor)
                .frame(width: buttonWidth, height: buttonHeight)
                .background(
                    RoundedRectangle(cornerRadius: buttonCornerRadius)
                        .foregroundStyle(Color.accentColor.gradient)
                        .shadow(color: Color(.black).opacity(shadowOpacity), radius: shadowSize, x: 0, y: shadowSize)
                )
        }
        .buttonStyle(.borderless)
        .position(x: xPosition, y: yPosition)
//        .disabled(saveIsDisabled)
//        .opacity(saveIsDisabled ? (colorScheme == .light ? 0.2 : 0.2) : 1)
    }
    
    enum Sheet: String, Identifiable {
        case lowerBound
        case upperBound
        case unit
        case info
        
        var id: String { rawValue }
    }
    
    enum Side {
        case left
        case right
    }
}
