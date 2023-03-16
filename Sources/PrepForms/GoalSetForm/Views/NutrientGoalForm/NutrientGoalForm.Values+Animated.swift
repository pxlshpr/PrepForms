import SwiftUI

struct AnimatableGoalValueModifier: AnimatableModifier {
    
    @Environment(\.colorScheme) var colorScheme
    @State var size: CGSize = .zero

    var value: Double
    
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
    
    var animatedLabel: some View {
        Text(value.formattedGoalValue)
            .font(.system(size: 30, weight: .bold, design: .rounded))
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.trailing)
            .fixedSize(horizontal: true, vertical: false)
    }
}

public extension View {
    func animatedGoalValueModifier(value: Double) -> some View {
        modifier(AnimatableGoalValueModifier(value: value))
    }
}

struct AnimatableGoalEquivalentValueModifier: AnimatableModifier {
    
    @Environment(\.colorScheme) var colorScheme
    @State var size: CGSize = .zero

    var value: Double
    var unitString: String
    
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
    
    var animatedLabel: some View {
        HStack {
            Image(systemName: "equal.square.fill")
                .font(.system(size: 20))
                .foregroundColor(Color(.quaternaryLabel))
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value.formattedGoalValue)
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
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.trailing)
        .fixedSize(horizontal: true, vertical: false)
    }
}

public extension View {
    func animatedGoalEquivalentValueModifier(value: Double, unitString: String) -> some View {
        modifier(AnimatableGoalEquivalentValueModifier(value: value, unitString: unitString))
    }
}
