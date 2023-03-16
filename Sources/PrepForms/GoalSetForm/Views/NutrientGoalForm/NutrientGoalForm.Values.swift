import SwiftUI
import SwiftUISugar
import SwiftHaptics
import PrepDataTypes
import PrepCoreDataStack

struct GoalValues: Equatable {
    var lower: Double?
    var upper: Double?
    
    var isEmpty: Bool {
        self.lower == nil && self.upper == nil
    }
}

struct GoalValuesSection: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var values: GoalValues
    @Binding var equivalentValues: GoalValues
    @Binding var usesSingleValue: Bool
    @Binding var unitString: String
    let equivalentUnitString: String?

    @State var leftValue: Double? = nil
    @State var rightValue: Double? = nil
    @State var equivalentLeftValue: Double? = nil
    @State var equivalentRightValue: Double? = nil
    @State var animatedUsesSingleValue: Bool
    
    @State var presentedSheet: Sheet? = nil
    
    enum Sheet: String, Identifiable {
        case leftValue
        case rightValue
        var id: String { rawValue }
    }
    
    init(
        values: Binding<GoalValues>,
        equivalentValues: Binding<GoalValues>,
        usesSingleValue: Binding<Bool> = .constant(false),
        unitString: Binding<String>,
        equivalentUnitString: String?
    ) {
        _values = values
        _equivalentValues = equivalentValues
        _usesSingleValue = usesSingleValue
        _unitString = unitString
        self.equivalentUnitString = equivalentUnitString
        
        _leftValue = State(initialValue: values.wrappedValue.lower)
        _rightValue = State(initialValue: values.wrappedValue.upper)
        _equivalentLeftValue = State(initialValue: equivalentValues.wrappedValue.lower)
        _equivalentRightValue = State(initialValue: equivalentValues.wrappedValue.upper)
        _animatedUsesSingleValue = State(initialValue: usesSingleValue.wrappedValue)
    }

    var body: some View {
        FormStyledSection(header: Text("Goal")) {
            HStack {
                contentsForSide(.left)
                if !animatedUsesSingleValue {
                    contentsForSide(.right)
                }
            }
        }
        .onChange(of: values, perform: valuesChanged)
        .onChange(of: equivalentValues, perform: equivalentValuesChanged)
        .onChange(of: usesSingleValue, perform: usesSingleValueChanged)
        .sheet(item: $presentedSheet) { sheet(for: $0) }
    }
    
    @ViewBuilder
    func sheet(for sheet: Sheet) -> some View {
        switch sheet {
        case .leftValue:
            valueForm(for: .left)
        case .rightValue:
            valueForm(for: .right)
        }
    }
    
    func valueForm(for side: Side) -> some View {
        EmptyView()
    }
    
    func present(_ sheet: Sheet) {
        
        func present() {
            Haptics.feedback(style: .soft)
            presentedSheet = nil
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
    
    func usesSingleValueChanged(_ newValue: Bool) {
        withAnimation {
            animatedUsesSingleValue = newValue
        }
    }
    
    func valuesChanged(_ newValues: GoalValues) {
        withAnimation {
            leftValue = newValues.lower
            rightValue = newValues.upper
        }
    }
    
    func equivalentValuesChanged(_ newValues: GoalValues) {
        withAnimation {
            equivalentLeftValue = newValues.lower
            equivalentRightValue = newValues.upper
        }
    }
    
    func contentsForSide(_ side: Side) -> some View {
        
        var valueString: String? {
            switch side {
            case .left:     return leftValue?.formattedGoalValue
            case .right:    return rightValue?.formattedGoalValue
            }
        }

        var headerString: String {
            var haveBothBounds: Bool {
                leftValue != nil && rightValue != nil
            }
            
            guard !animatedUsesSingleValue else {
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
                            .animatedGoalValueModifier(value: value)
                    } else {
                        Text("optional")
                            .font(.system(size: 20, weight: .regular, design: .default))
                            .opacity(0.5)
                    }
                }
                .foregroundColor(.accentColor)
                .frame(height: 65)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color.accentColor.opacity(
                            colorScheme == .dark ? 0.1 : 0.15
                        ))
                )
            }
            
            return Button {
                
            } label: {
                label
            }
        }
        
        return VStack(alignment: .customCenter) {
            headerLabel
            button
            if !equivalentValues.isEmpty {
                equivalentLabel
            }
        }
    }
    
    enum Side {
        case left
        case right
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
