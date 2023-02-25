import SwiftUI
import FoodLabelScanner
import ActivityIndicatorView
import PrepDataTypes

public struct AttributesLayer: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Namespace var namespace
    @FocusState var isFocused: Bool

    @ObservedObject var extractor: Extractor
    /// Try and embed this in `extractor`
//    var actionHandler: (AttributesLayerAction) -> ()
    
    @State var hideBackground: Bool = false
    @State var showingNutrientsPicker = false
    @State var showingTutorial = false
    @State var disableNextTutorialInvocation = false
    @State var dragTranslationX: CGFloat?

    let attributesListAnimation: Animation = K.Animations.bounce
    let scannerDidChangeAttribute = NotificationCenter.default.publisher(for: .scannerDidChangeAttribute)
    
    public init(extractor: Extractor) {
        self.extractor = extractor
    }
    
    public var body: some View {
        ZStack {
//            topButtonsLayer
            supplementaryContentLayer
            primaryContentLayer
            buttonsLayer
//            columnPickerLayer
            tutorialLayer
        }
        .onChange(of: showingTutorial) { newValue in
            cprint("📚 showingTutorial: \(newValue)")
        }
//        .onChange(of: extractor.state, perform: stateChanged)
    }
    
    var primaryContentLayer: some View {
        VStack {
            Spacer()
            primaryContent
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    var primaryContent: some View {
        var background: some ShapeStyle {
            .thinMaterial.opacity(extractor.state == .showingKeyboard ? 0 : 1)
//            Color.green.opacity(hideBackground ? 0 : 1)
        }
        
        return ZStack {
            if let description = extractor.state.loadingDescription {
                loadingView(description)
            } else {
                primaryView
                    .transition(.move(edge: .bottom))
                    .zIndex(10)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: K.attributesLayerHeight)
        .background(background)
        .clipped()
    }
    
    func loadingView(_ string: String) -> some View {
        VStack {
            Spacer()
            VStack {
                Text(string)
                    .font(.system(.title3, design: .rounded, weight: .medium))
                    .foregroundColor(Color(.secondaryLabel))
                ActivityIndicatorView(isVisible: .constant(true), type: .opacityDots())
                    .frame(width: 30, height: 30)
                    .foregroundColor(Color(.secondaryLabel))
            }
            Spacer()
        }
    }
}
