import SwiftUI
import SwiftUISugar
import SwiftHaptics
import PrepDataTypes
import PrepCoreDataStack

extension Double {
    internal var formatted: String {
        formatted(decimalValuesDisplayedUnder: 10)
    }
}

extension NutrientGoalForm_New {
    
    enum Side {
        case left
        case right
    }
    
    var valuesSection: some View {
        FormStyledSection(header: Text("Goal")) {
            HStack {
                contentsForSide(.left)
                contentsForSide(.right)
            }
        }
    }

    func contentsForSide(_ side: Side) -> some View {
        
        let leftValue = goal.lowerBound
        let rightValue = goal.upperBound
        let equivalentValues: (Double?, Double?)? = (goal.equivalentLowerBound, goal.equivalentUpperBound)
        
        var valueString: String? {
            switch side {
            case .left:     return leftValue?.formatted
            case .right:    return rightValue?.formatted
            }
        }

        var headerString: String {
            var haveBothBounds: Bool {
                leftValue != nil && rightValue != nil
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
            var string: String {
                switch side {
                case .left:     return equivalentValues?.0?.formatted ?? ""
                case .right:    return equivalentValues?.1?.formatted ?? ""
                }
            }
            
            var unitString: String {
                valueString != nil ? "g" : ""
            }
            
            return HStack {
                Image(systemName: "equal.square.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(.quaternaryLabel))
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(string)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(.secondaryLabel))
                        .alignmentGuide(.customCenter) { context in
                            context[HorizontalAlignment.center]
                        }
                    Text(unitString)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }
            .frame(height: 25)
        }
                
        var button: some View {
            
            var label: some View {
                var isEmpty: Bool { valueString == nil }
                var fontSize: CGFloat { isEmpty ? 20 : 30 }
                var opacity: CGFloat { isEmpty ? 0.5 : 1 }
                var fontWeight: Font.Weight { isEmpty ? .regular : .bold }
                var fontDesign: Font.Design { isEmpty ? .default : .rounded }
                
                return Text(valueString ?? "optional")
                    .font(.system(size: fontSize, weight: fontWeight, design: fontDesign))
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 15)
                    .opacity(opacity)
                    .frame(height: 65)
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
            if goal.haveEquivalentValues {
                equivalentLabel
            }
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
