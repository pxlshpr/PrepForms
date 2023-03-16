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
    let equivalentUnitString: String?

    public init(goalModel: GoalModel, didTapDelete: @escaping ((GoalModel) -> ())) {
        self.model = goalModel
        self.didTapDelete = didTapDelete
        //TODO: Have a way of knowing if this goal is new
        
        _leftValue = State(initialValue: goalModel.lowerBound)
        _rightValue = State(initialValue: goalModel.upperBound)
        _equivalentLeftValue = State(initialValue: goalModel.equivalentLowerBound)
        _equivalentRightValue = State(initialValue: goalModel.equivalentUpperBound)
        _usesSingleValue = State(initialValue: goalModel.usesSingleValue)
        _hasEquivalentValues = State(initialValue: goalModel.hasEquivalentValues)
        _showSyncedIndicator = State(initialValue: goalModel.showsSyncedIndicator)
        self.equivalentUnitString = goalModel.equivalentUnitString
    }
    
    public var body: some View {
        quickForm
            .presentationDetents([.height(260)])
            .onDisappear(perform: disappeared)
    }

    var quickForm: some View {
        QuickForm(
            title: model.description,
            lighterBackground: false,
            deleteAction: deleteActionBinding
        ) {
            valuesContent
            saveButton
        }
    }
    
    var valuesContent: some View {
        VStack(spacing: 10) {
            HStack {
                contentsForSide(.left)
                if !usesSingleValue {
                    contentsForSide(.right)
                }
                unitButton
            }
            HStack {
                if hasEquivalentValues {
                    equivalentLabel
                }
                Spacer()
                syncedButton
            }
        }
        .padding(.horizontal, 20)
    }
    
    func valueForSide(_ side: Side) -> Double? {
        switch side {
        case .left:     return leftValue
        case .right:    return rightValue
        }
    }

    func contentsForSide(_ side: Side) -> some View {
        
        var valueString: String? {
            valueForSide(side)?.formattedGoalValue
        }

        var headerString: String {
            var haveBothBounds: Bool {
                leftValue != nil && rightValue != nil
            }
            
            guard !usesSingleValue else {
                return "within"
           }

            switch side {
            case .left:     return haveBothBounds ? "from" : "at least"
            case .right:    return haveBothBounds ? "to" : "at most"
            }
        }
        
        var headerLabel: some View {
            Text(headerString)
                .foregroundColor(Color(.tertiaryLabel))
        }
        
        var equivalentLabel: some View {
            var value: Double? {
                switch side {
                case .left:     return equivalentLeftValue
                case .right:    return equivalentRightValue
                }
            }
            
            var secondaryValue: Double? {
                guard usesSingleValue else { return nil }
                return equivalentRightValue
            }
            
            var unitString: String {
                guard valueString != nil, let equivalentUnitString else {
                    return ""
                }
                return equivalentUnitString
            }
            
            var label: some View {
                Group {
                    if let value {
                        HStack {
                            Image(systemName: "equal.square.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color(.quaternaryLabel))
                            HStack(spacing: 2) {
                                Color.clear
                                    .animatedGoalEquivalentValueModifier(value: value)
                                    .alignmentGuide(.customCenter) { context in
                                        context[HorizontalAlignment.center]
                                    }
                                if let secondaryValue {
                                    Text("–")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        .foregroundColor(Color(.tertiaryLabel))
                                    Color.clear
                                        .animatedGoalEquivalentValueModifier(value: secondaryValue)
                                        .alignmentGuide(.customCenter) { context in
                                            context[HorizontalAlignment.center]
                                        }
                                }
                                Text(unitString)
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color(.tertiaryLabel))
                            }
                        }
                    } else {
                        Color.clear
                    }
                }
                .frame(height: 25)
            }
            
            return label
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
//                present(side == .left ? .leftValue : .rightValue)
            } label: {
                label
            }
        }
        
        return VStack(alignment: .customCenter, spacing: 5) {
            headerLabel
            button
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
        model.validateNutrient()
        goalSetModel.createImplicitGoals()
    }
    
    var syncedButton: some View {
        var label: some View {
            HStack {
                appleHealthBolt
                    .grayscale(model.isSynced ? 0 : 1)
                Text("\(model.isSynced ? "" : "not ")synced")
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(.vertical, 5)
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
    
    var equivalentLabel: some View {
        
        var leftValue: Double? {
            equivalentLeftValue
        }
        
        var rightValue: Double? {
            equivalentRightValue
        }
        
        func label(_ leftValue: Double, unitString: String) -> some View {
            HStack {
                Image(systemName: "equal.square.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(.quaternaryLabel))
                HStack(spacing: 5) {
                    Color.clear
                        .animatedGoalEquivalentValueModifier(value: leftValue)
                        .alignmentGuide(.customCenter) { context in
                            context[HorizontalAlignment.center]
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
            if let leftValue, let equivalentUnitString {
                label(leftValue, unitString: equivalentUnitString)
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
        
        return Button {
            
        } label: {
            VStack(spacing: 5) {
                Text("...")
                    .foregroundColor(Color(.tertiaryLabel))
                    .opacity(0)
                label
            }
        }
    }
    
    var swapValuesButton: some View {
        VStack(spacing: 7) {
            Text("")
            if model.lowerBound != nil, model.upperBound == nil {
                Button {
                    Haptics.feedback(style: .rigid)
                    model.upperBound = model.lowerBound
                    model.lowerBound = nil
                } label: {
                    Image(systemName: "rectangle.righthalf.inset.filled.arrow.right")
                        .foregroundColor(.accentColor)
                }
            } else if model.upperBound != nil, model.lowerBound == nil {
                Button {
                    Haptics.feedback(style: .rigid)
                    model.lowerBound = model.upperBound
                    model.upperBound = nil
                } label: {
                    Image(systemName: "rectangle.lefthalf.inset.filled.arrow.left")
                        .foregroundColor(.accentColor)
                }
            }
        }
        .padding(.top, 10)
        .frame(width: 16, height: 20)
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
        case weightForm
        case leanMassForm
        case lowerBoundForm
        case upperBoundForm
        var id: String { rawValue }
    }
    
    enum Side {
        case left
        case right
    }
}
