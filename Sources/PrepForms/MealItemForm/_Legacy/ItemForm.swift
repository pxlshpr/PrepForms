//import SwiftUI
//import SwiftUISugar
//import SwiftHaptics
//import PrepFoodSearch
//import PrepCoreDataStack
//import PrepDataTypes
//
//public struct ItemForm: View {
//    
//    @Environment(\.colorScheme) var colorScheme
//    @Binding var isPresented: Bool
//    @State var fadeOutOverlay: Bool = false
//    @State var size: CGSize = .zero
//    @State var height: CGFloat = 0
//    @State var safeAreaInsets: EdgeInsets = .init()
//    @State var dragOffsetY: CGFloat = 0.0
//
//    let hardcodedSafeAreaBottomInset: CGFloat = 34.0
//
//    @State var searchIsFocused: Bool = false
//
//    public init(isPresented: Binding<Bool>) {
//        _isPresented = isPresented
//    }
//    
//    @State var showingFoodSearch = true
//    
//    public var body: some View {
//        ZStack {
//            if isPresented && !fadeOutOverlay {
//                Color.black.opacity(colorScheme == .light ? 0.2 : 0.5)
//                    .transition(.opacity)
//                    .edgesIgnoringSafeArea(.all)
//                    .onTapGesture { tappedDismiss() }
//                shadowLayer
//                    .transition(.move(edge: .bottom))
//                    .edgesIgnoringSafeArea(.all)
//                    .onTapGesture { tappedDismiss() }
//            }
//            if isPresented {
//                VStack {
//                    Spacer()
//                    sheet
//                }
//                .edgesIgnoringSafeArea(.all)
//                .animation(.interactiveSpring(), value: isPresented)
//                .transition(.move(edge: .bottom))
//            }
//            if isPresented {
//                foodSearchLayer
//                    .transition(.move(edge: .bottom))
//                    .zIndex(10)
//            }
//        }
//    }
//    
//    var foodSearchLayer: some View {
//        func didTapFood(_ food: Food) {
//            Haptics.feedback(style: .soft)
////            viewModel.setFood(food)
////
////            if isInitialFoodSearch {
////                viewModel.path = [.mealItemForm]
////            } else {
////                dismiss()
////            }
//        }
//        
//        func didTapMacrosIndicatorForFood(_ food: Food) {
//            Haptics.feedback(style: .soft)
////            foodToShowMacrosFor = food
//        }
//        
//        func didTapClose() {
//            Haptics.feedback(style: .soft)
//            withAnimation {
//                isPresented = false
////                searchIsFocused = false
////                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
////                    withAnimation {
////                        showingFoodSearch = false
////                    }
////                }
//            }
//        }
//        
//        var searchView: some View {
//            FoodSearch(
//                dataProvider: DataManager.shared,
//                shouldDelayContents: true,
//                focusOnAppear: true,
//                searchIsFocused: $searchIsFocused,
//                didTapClose: didTapClose,
//                didTapFood: didTapFood,
//                didTapMacrosIndicatorForFood: didTapMacrosIndicatorForFood
//            )
//        }
//        
//        return NavigationStack {
//            searchView
//        }
//    }
//    
//    var sheet: some View {
//        contents
//            .readSafeAreaInsets { insets in
//                safeAreaInsets = insets
//            }
//            .onChange(of: size) { newValue in
//                self.height = calculatedHeight
//            }
//            .onChange(of: safeAreaInsets) { newValue in
//                self.height = calculatedHeight
//            }
//            .onChange(of: colorScheme) { newValue in
//                /// Workaround for a bug where color scheme changes shifts the presented sheet downwards for some reason
//                /// (This seems to happen only when we have a dynamic height—even if we're not actually changing the height)
//                height = height + 1
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
//                    height = height - 1
//                }
//            }
//            .safeAreaInset(edge: .bottom) {
//                Spacer().frame(height: hardcodedSafeAreaBottomInset)
//            }
//            .gesture(dragGesture)
//    }
//
//    var contents: some View {
//        ZStack {
//            FormBackground()
//                .cornerRadius(10.0, corners: [.topLeft, .topRight])
//                .edgesIgnoringSafeArea(.all)
//                .frame(height: height)
//                .offset(y: max(0, dragOffsetY))
////            shadowLayer
//            form
////                .edgesIgnoringSafeArea(.bottom)
//                .frame(height: height)
//                .offset(y: dragOffsetY)
//        }
//    }
//    
//    var form: some View {
//        var closeButton: some View {
//            Button {
//                Haptics.feedback(style: .soft)
//                tappedDismiss()
//            } label: {
//                CloseButtonLabel()
//            }
//        }
//
//        var topRow: some View {
//            HStack {
//                Text("Log Food")
//                    .font(.title2)
//                    .fontWeight(.bold)
//                    .frame(maxHeight: .infinity, alignment: .center)
//                    .padding(.top, 5)
//                Spacer()
//                closeButton
//            }
//            .frame(height: 30)
//            .padding(.leading, 20)
//            .padding(.trailing, 14)
//            .padding(.top, 12)
//            .padding(.bottom, 18)
//        }
//        
//        var content: some View {
////            GeometryReader { proxy in
//                VStack(spacing: 0) {
//                    topRow
//                    VStack {
//                        Text("Contents go here")
//                            .frame(height: 300)
//                    }
//                    .readSize { size in
//                        self.size = size
//                    }
//                    .frame(maxWidth: .infinity)
//                    Spacer()
//                }
//                .background(
//                    FormBackground()
//                        .edgesIgnoringSafeArea(.all)
//                        .cornerRadius(10.0)
//                )
////                .frame(height: proxy.size.height, alignment: .top)
////            }
//        }
//        
//        return content
//    }
//    
//    var calculatedHeight: CGFloat {
//        size.height + 60.0
//    }
//
//    var dragGesture: some Gesture {
//        func logC(val: Double, forBase base: Double) -> Double {
//            return log(val)/log(base)
//        }
//        
//        func changed(_ value: DragGesture.Value) {
//            let y = value.translation.height
////            guard y < 0 else {
//            guard y < -22 else {
//                dragOffsetY = y
//                return
//            }
//            let log = logC(val: (-y) + 11.5, forBase: 1.05) - 50
//            dragOffsetY = -log
//        }
//        
//        func ended(_ value: DragGesture.Value) {
//            let totalHeight = height + hardcodedSafeAreaBottomInset
////            cprint("🥸 predictedEndLocation.y: \(value.predictedEndLocation.y)")
////            cprint("🥸 height: \(totalHeight)")
//            if value.predictedEndLocation.y > totalHeight / 2.0 {
////                isPresented = false
////                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
////                    dragOffsetY = 0.0
////                }
//                /// Animate the offset with the speed that the drag ended with, but
//                let velocity = CGSize(
//                    width:  value.predictedEndLocation.x - value.location.x,
//                    height: value.predictedEndLocation.y - value.location.y
//                )
//                cprint("🥸 velocity: \(velocity)")
//
//                let duration = (1.0 / velocity.height) * 45.0
//                withAnimation(.easeInOut(duration: duration)) {
//                    dragOffsetY = totalHeight
//                }
//                /// Animate the fade normally
//                withAnimation {
//                    fadeOutOverlay = true
//                }
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                     fadeOutOverlay = false
//                     isPresented = false
//                     dragOffsetY = 0.0
//                }
//            } else {
//                withAnimation {
//                    dragOffsetY = 0.0
//                }
//            }
//        }
//        
//        return DragGesture()
//            .onChanged(changed)
//            .onEnded(ended)
//    }
//
//    func tappedDismiss() {
////        Haptics.feedback(style: .soft)
//        let totalHeight = height + hardcodedSafeAreaBottomInset
//        withAnimation {
//            dragOffsetY = totalHeight
//            fadeOutOverlay = true
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                isPresented = false
//                dragOffsetY = 0
//                fadeOutOverlay = false
//            }
//        }
//    }
//    
//    var shadowLayer: some View {
//        GeometryReader { proxy in
//            VStack(spacing: 0) {
//                Spacer()
//                ZStack {
//                    VStack {
//                        Rectangle()
//                            .fill(.green)
//                            .frame(height: 210)
//                            .shadow(radius: 70.0, y: 0)
//                            .position(x: proxy.size.width / 2.0, y: 210 + 70.0 + 35)
//                        Spacer()
//                    }
//                }
//                .frame(height: 210)
//                .clipped()
//                .offset(y: dragOffsetY)
//                Color.clear
//                    .frame(height: height + 38.0 - 10.0) /// not sure what the 38 is, 10 is corner radius
//            }
//        }
//    }
//}
