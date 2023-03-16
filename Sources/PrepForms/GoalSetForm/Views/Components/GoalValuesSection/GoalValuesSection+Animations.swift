import SwiftUI

struct AnimatableGoalValueModifier: AnimatableModifier {
    
    @Environment(\.colorScheme) var colorScheme
    @State var size: CGSize = .zero

    var value: Double
    var fontSize: CGFloat
    
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
            .font(.system(size: fontSize, weight: .bold, design: .rounded))
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.trailing)
            .fixedSize(horizontal: true, vertical: false)
    }
}

public extension View {
    func animatedGoalValueModifier(value: Double, fontSize: CGFloat) -> some View {
        modifier(AnimatableGoalValueModifier(value: value, fontSize: fontSize))
    }
}

struct AnimatableGoalEquivalentValueModifier: AnimatableModifier {
    
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
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .foregroundColor(Color(.secondaryLabel))
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.trailing)
            .fixedSize(horizontal: true, vertical: false)
    }
}

public extension View {
    func animatedGoalEquivalentValueModifier(value: Double) -> some View {
        modifier(AnimatableGoalEquivalentValueModifier(value: value))
    }
}
