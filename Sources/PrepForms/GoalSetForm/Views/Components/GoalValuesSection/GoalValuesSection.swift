import SwiftUI
import SwiftUISugar
import SwiftHaptics
import PrepDataTypes
import PrepCoreDataStack


extension GoalModel {
    var usesSingleValue: Bool {
        energyGoalType?.delta == .deviation
    }

    var hasEquivalentValues: Bool {
        guard type.showsEquivalentValues else { return false }
        return equivalentUpperBound != nil || equivalentLowerBound != nil
    }

    var showsSyncedIndicator: Bool {
        switch type {
        case .energy(let type):
            return type.showsSyncedIndicator
        case .macro(let type, _):
            return type.showsSyncedIndicator
        case .micro(let type, _, _):
            return type.showsSyncedIndicator
        }
    }
}

extension EnergyGoalType {
    var showsSyncedIndicator: Bool {
        switch self {
        case .fixed:
            return false
        case .fromMaintenance, .percentFromMaintenance:
            return true
        }
    }
}

extension NutrientGoalType {
    var showsSyncedIndicator: Bool {
        switch self {
        case .fixed, .quantityPerWorkoutDuration:
            return false
        case .quantityPerBodyMass, .percentageOfEnergy, .quantityPerEnergy:
            return true
        }
    }
}

struct CustomCenter: AlignmentID {
    static func defaultValue(in context: ViewDimensions) -> CGFloat {
        context[HorizontalAlignment.center]
    }
}

extension HorizontalAlignment {
    static let customCenter: HorizontalAlignment = .init(CustomCenter.self)
}

struct GoalValues: Equatable {
    var lower: Double?
    var upper: Double?

    var isEmpty: Bool {
        self.lower == nil && self.upper == nil
    }
}

//
//struct GoalValuesSection: View {
//
//    @Environment(\.colorScheme) var colorScheme
//
//    @ObservedObject var goalModel: GoalModel
//
//    let equivalentUnitString: String?
//
//    @State var leftValue: Double? = nil
//    @State var rightValue: Double? = nil
//    @State var equivalentLeftValue: Double? = nil
//    @State var equivalentRightValue: Double? = nil
//    @State var usesSingleValue: Bool
//
//    @State var presentedSheet: Sheet? = nil
//
//    enum Sheet: String, Identifiable {
//        case leftValue
//        case rightValue
//        var id: String { rawValue }
//    }
//
//    init(
//        goalModel: GoalModel
//    ) {
//        self.goalModel = goalModel
//
//        _leftValue = State(initialValue: goalModel.lowerBound)
//        _rightValue = State(initialValue: goalModel.upperBound)
//        _equivalentLeftValue = State(initialValue: goalModel.equivalentLowerBound)
//        _equivalentRightValue = State(initialValue: goalModel.equivalentUpperBound)
//        _usesSingleValue = State(initialValue: goalModel.usesSingleValue)
//        self.equivalentUnitString = goalModel.equivalentUnitString
//    }
//
//    var body: some View {
//        FormStyledSection(header: Text("Goal")) {
//            HStack {
//                contentsForSide(.left)
//                if !usesSingleValue {
//                    contentsForSide(.right)
//                }
//            }
//        }
//        .onChange(of: goalModel.type, perform: goalModelTypeChanged)
//        .sheet(item: $presentedSheet) { sheet(for: $0) }
//    }
//
//    func goalModelTypeChanged(_ newValue: GoalType) {
//        withAnimation {
//            leftValue = goalModel.lowerBound
//            rightValue = goalModel.upperBound
//            equivalentLeftValue = goalModel.equivalentLowerBound
//            equivalentRightValue = goalModel.equivalentUpperBound
//            usesSingleValue = goalModel.usesSingleValue
//        }
//    }
//
//    @ViewBuilder
//    func sheet(for sheet: Sheet) -> some View {
//        switch sheet {
//        case .leftValue:
//            valueForm(for: .left)
//        case .rightValue:
//            valueForm(for: .right)
//        }
//    }
//
//    func valueForm(for side: Side) -> some View {
//        func handleNewValue(_ newValue: Double?) {
//            switch side {
//            case .left:
//                goalModel.lowerBound = newValue
//                withAnimation {
//                    self.leftValue = newValue
//                    self.equivalentLeftValue = goalModel.equivalentLowerBound
//                }
//            case .right:
//                goalModel.upperBound = newValue
//                withAnimation {
//                    self.rightValue = newValue
//                    self.equivalentRightValue = goalModel.equivalentUpperBound
//                }
//            }
//        }
//
//        return GoalValueForm(
//            value: valueForSide(side),
//            unitStrings: goalModel.unitStrings,
//            handleNewValue: handleNewValue
//        )
//    }
//
//    func present(_ sheet: Sheet) {
//
//        func present() {
//            Haptics.feedback(style: .soft)
//            presentedSheet = sheet
//        }
//
//        func delayedPresent() {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                present()
//            }
//        }
//
//        if presentedSheet != nil {
//            presentedSheet = nil
//            delayedPresent()
//        } else {
//            present()
//        }
//    }
//
//    func valueForSide(_ side: Side) -> Double? {
//        switch side {
//        case .left:     return leftValue
//        case .right:    return rightValue
//        }
//    }
//
//    func contentsForSide(_ side: Side) -> some View {
//
//        var valueString: String? {
//            valueForSide(side)?.formattedGoalValue
//        }
//
//        var headerString: String {
//            var haveBothBounds: Bool {
//                leftValue != nil && rightValue != nil
//            }
//
//            guard !usesSingleValue else {
//                return "within"
//            }
//
//            switch side {
//            case .left:     return haveBothBounds ? "from" : "at least"
//            case .right:    return haveBothBounds ? "to" : "at most"
//            }
//        }
//
//        var headerLabel: some View {
//            Text(headerString)
//                .foregroundColor(Color(.tertiaryLabel))
//        }
//
//        var equivalentLabel: some View {
//            var value: Double? {
//                switch side {
//                case .left:     return equivalentLeftValue
//                case .right:    return equivalentRightValue
//                }
//            }
//
//            var secondaryValue: Double? {
//                guard usesSingleValue else { return nil }
//                return equivalentRightValue
//            }
//
//            var unitString: String {
//                guard valueString != nil, let equivalentUnitString else {
//                    return ""
//                }
//                return equivalentUnitString
//            }
//
//            var label: some View {
//                Group {
//                    if let value {
//                        HStack {
//                            Image(systemName: "equal.square.fill")
//                                .font(.system(size: 20))
//                                .foregroundColor(Color(.quaternaryLabel))
//                            HStack(spacing: 2) {
//                                Color.clear
//                                    .animatedGoalEquivalentValueModifier(value: value)
//                                    .alignmentGuide(.customCenter) { context in
//                                        context[HorizontalAlignment.center]
//                                    }
//                                if let secondaryValue {
//                                    Text("–")
//                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
//                                        .foregroundColor(Color(.tertiaryLabel))
//                                    Color.clear
//                                        .animatedGoalEquivalentValueModifier(value: secondaryValue)
//                                        .alignmentGuide(.customCenter) { context in
//                                            context[HorizontalAlignment.center]
//                                        }
//                                }
//                                Text(unitString)
//                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
//                                    .foregroundColor(Color(.tertiaryLabel))
//                            }
//                        }
//                    } else {
//                        Color.clear
//                    }
//                }
//                .frame(height: 25)
//            }
//
//            return label
//        }
//
//        var button: some View {
//
//            var label: some View {
//                var value: Double? {
//                    switch side {
//                    case .left: return leftValue
//                    case .right: return rightValue
//                    }
//                }
//
//                return Group {
//                    if let value {
//                        Color.clear
//                            .animatedGoalValueModifier(value: value, fontSize: 30)
//                    } else {
//                        Text("optional")
//                            .font(.system(size: 20, weight: .regular, design: .default))
//                            .opacity(0.5)
//                    }
//                }
//                .foregroundColor(.accentColor)
//                .frame(height: 65)
//                .frame(maxWidth: .infinity)
//                .background(
//                    RoundedRectangle(cornerRadius: 7, style: .continuous)
//                        .fill(Color.accentColor.opacity(
//                            colorScheme == .dark ? 0.1 : 0.15
//                        ))
//                )
//            }
//
//            return Button {
//                present(side == .left ? .leftValue : .rightValue)
//            } label: {
//                label
//            }
//        }
//
//        return VStack(alignment: .customCenter) {
//            headerLabel
//            button
//            if goalModel.hasEquivalentValues {
//                equivalentLabel
//            }
//        }
//    }
//
//    enum Side {
//        case left
//        case right
//    }
//}

