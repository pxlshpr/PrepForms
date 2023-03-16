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

    @State var leftValue: Double? = nil
    @State var rightValue: Double? = nil
    @State var equivalentLeftValue: Double? = nil
    @State var equivalentRightValue: Double? = nil
    @State var animatedUsesSingleValue: Bool
    
    init(
        values: Binding<GoalValues>,
        equivalentValues: Binding<GoalValues>,
        usesSingleValue: Binding<Bool> = .constant(false)
    ) {
        _values = values
        _equivalentValues = equivalentValues
        _usesSingleValue = usesSingleValue
        
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
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.values = .init(lower: 2.0, upper: nil)
            }
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
            
            var unitString: String {
                valueString != nil ? "g" : ""
            }
            
            var label: some View {
                Group {
                    if let value {
                        Color.clear
                            .animatedGoalEquivalentValueModifier(
                                value: value,
                                unitString: unitString
                            )
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
