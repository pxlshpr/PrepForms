import SwiftUI
import SwiftUISugar
import SwiftHaptics
import PrepDataTypes

extension ParentFoodForm {
    struct SaveSheet: View {
        
        @EnvironmentObject var model: ParentFoodForm.Model
        @EnvironmentObject var fields: FoodForm.Fields
        
        @Environment(\.colorScheme) var colorScheme
        @State var size: CGSize = .zero
        @State var safeAreaInsets: EdgeInsets = .init()
        @State var height: CGFloat = 0
        @State var dragOffsetY: CGFloat = 0.0
        @State var fadeOutOverlay: Bool = false
        let hardcodedSafeAreaBottomInset: CGFloat = 34.0

        @Binding var isPresented: Bool
        @Binding var validationMessage: ValidationMessage?
        let didTapSave: () -> ()
    }
}
 
extension ParentFoodForm.SaveSheet {
    var body: some View {
        ZStack {
            if isPresented && !fadeOutOverlay {
                Color.black.opacity(colorScheme == .light ? 0.2 : 0.5)
                    .transition(.opacity)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture { tappedDismiss() }
                shadowLayer
                    .transition(.move(edge: .bottom))
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture { tappedDismiss() }
            }
            if isPresented {
                VStack {
                    Spacer()
                    sheet
                }
                .edgesIgnoringSafeArea(.all)
                .animation(.interactiveSpring(), value: isPresented)
                .transition(.move(edge: .bottom))
            }
        }
    }
    
    func tappedDismiss() {
//        Haptics.feedback(style: .soft)
        let totalHeight = height + hardcodedSafeAreaBottomInset
        withAnimation {
            dragOffsetY = totalHeight
            fadeOutOverlay = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isPresented = false
                dragOffsetY = 0
                fadeOutOverlay = false
            }
        }
    }
    
    var shadowLayer: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                Spacer()
                ZStack {
                    VStack {
                        Rectangle()
                            .fill(.green)
                            .frame(height: 210)
                            .shadow(radius: 70.0, y: 0)
                            .position(x: proxy.size.width / 2.0, y: 210 + 70.0 + 35)
                        Spacer()
                    }
                }
                .frame(height: 210)
                .clipped()
                .offset(y: dragOffsetY)
                Color.clear
                    .frame(height: height + 38.0 - 10.0) /// not sure what the 38 is, 10 is corner radius
            }
        }
    }
    
    var sheet: some View {
        contents
            .readSafeAreaInsets { insets in
                safeAreaInsets = insets
            }
            .onChange(of: size) { newValue in
                self.height = calculatedHeight
            }
            .onChange(of: safeAreaInsets) { newValue in
                self.height = calculatedHeight
            }
            .onChange(of: colorScheme) { newValue in
                /// Workaround for a bug where color scheme changes shifts the presented sheet downwards for some reason
                /// (This seems to happen only when we have a dynamic height—even if we're not actually changing the height)
                height = height + 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    height = height - 1
                }
            }
            .safeAreaInset(edge: .bottom) {
                Spacer().frame(height: hardcodedSafeAreaBottomInset)
            }
            .gesture(dragGesture)
    }
    
    var dragGesture: some Gesture {
        func logC(val: Double, forBase base: Double) -> Double {
            return log(val)/log(base)
        }
        
        func changed(_ value: DragGesture.Value) {
            let y = value.translation.height
//            guard y < 0 else {
            guard y < -22 else {
                dragOffsetY = y
                return
            }
            let log = logC(val: (-y) + 11.5, forBase: 1.05) - 50
            dragOffsetY = -log
        }
        
        func ended(_ value: DragGesture.Value) {
            let totalHeight = height + hardcodedSafeAreaBottomInset
//            cprint("🥸 predictedEndLocation.y: \(value.predictedEndLocation.y)")
//            cprint("🥸 height: \(totalHeight)")
            if value.predictedEndLocation.y > totalHeight / 2.0 {
//                isPresented = false
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                    dragOffsetY = 0.0
//                }
                /// Animate the offset with the speed that the drag ended with, but
                let velocity = CGSize(
                    width:  value.predictedEndLocation.x - value.location.x,
                    height: value.predictedEndLocation.y - value.location.y
                )
                cprint("🥸 velocity: \(velocity)")

                let duration = (1.0 / velocity.height) * 45.0
                withAnimation(.easeInOut(duration: duration)) {
                    dragOffsetY = totalHeight
                }
                /// Animate the fade normally
                withAnimation {
                    fadeOutOverlay = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                     fadeOutOverlay = false
                     isPresented = false
                     dragOffsetY = 0.0
                }
            } else {
                withAnimation {
                    dragOffsetY = 0.0
                }
            }
        }
        
        return DragGesture()
            .onChanged(changed)
            .onEnded(ended)
    }

    var contents: some View {
        ZStack {
            FormBackground()
                .cornerRadius(10.0, corners: [.topLeft, .topRight])
                .edgesIgnoringSafeArea(.all)
                .frame(height: height)
                .offset(y: max(0, dragOffsetY))
            form
                .frame(height: height)
                .offset(y: dragOffsetY)
        }
    }
    
    var form: some View {
        var closeButton: some View {
            Button {
                Haptics.feedback(style: .soft)
                tappedDismiss()
            } label: {
                CloseButtonLabel(forUseOutsideOfNavigationBar: true)
            }
        }

        var topRow: some View {
            HStack {
                Text("Save")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxHeight: .infinity, alignment: .center)
                    .padding(.top, 5)
                Spacer()
                closeButton
            }
            .frame(height: 30)
            .padding(.leading, 20)
            .padding(.trailing, 14)
            .padding(.top, 12)
            .padding(.bottom, 18)
        }
        
        var content: some View {
            VStack(spacing: 0) {
                topRow
                VStack {
                    if let validationMessage {
                        validationInfo(validationMessage)
                    }
                    saveButton
//                        .padding(.bottom, 20)
                }
                .readSize { size in
                    self.size = size
                }
                .frame(maxWidth: .infinity)
                Spacer()
            }
            .background(
                FormBackground()
                    .edgesIgnoringSafeArea(.all)
                    .cornerRadius(10.0)
            )
        }
        
        return content
    }
    
    var calculatedHeight: CGFloat {
        size.height + 60.0
    }

    var saveIsDisabled: Binding<Bool> {
        Binding<Bool>(
            get: { model.items.count < 2 || fields.name.isEmpty },
            set: { _ in }
        )
    }
    
    var buttonWidth: CGFloat { UIScreen.main.bounds.width - (20 * 2) }
    var buttonHeight: CGFloat { 52 }
    var buttonCornerRadius: CGFloat { 10 }
    var shadowSize: CGFloat { 2 }
    var shadowOpacity: CGFloat { 0.2 }
    
    var saveTitle: String {
        "\(model.isEditing ? "Save" : "Add") \(model.forRecipe ? "Recipe" : "Plate")"
    }
    
    var saveButton: some View {
        var foregroundColor: Color {
            (colorScheme == .light && saveIsDisabled.wrappedValue) ? .black : .white
        }
        
        var opacity: CGFloat {
            saveIsDisabled.wrappedValue ? (colorScheme == .light ? 0.2 : 0.2) : 1
        }
        
        return Button {
            didTapSave()
        } label: {
            Text(saveTitle)
                .bold()
                .foregroundColor(foregroundColor)
                .frame(width: buttonWidth, height: buttonHeight)
                .background(
                    RoundedRectangle(cornerRadius: buttonCornerRadius)
                        .foregroundStyle(Color.accentColor.gradient)
                        .shadow(
                            color: Color(.black).opacity(shadowOpacity),
                            radius: shadowSize,
                            x: 0, y: shadowSize
                        )
                )
        }
        .disabled(saveIsDisabled.wrappedValue)
        .opacity(opacity)
    }
    
    func validationInfo(_ validationMessage: ValidationMessage) -> some View {
        let fill: Color = colorScheme == .light
//        ? Color(hex: "EFEFF0")
        ? Color(.quaternarySystemFill)
        : Color(.secondarySystemFill)
        
        return VStack {
            
            switch validationMessage {
            case .missingFields(let fieldNames):
                if let fieldName = fieldNames.first, fieldNames.count == 1 {
                    Text("Please fill in the \(Text(fieldName).bold()) value to be able to save this \(model.entityName.lowercased()).")
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    VStack(alignment: .leading) {
                        Text("Please fill in the following to be able to save this \(model.entityName.lowercased()):")
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 1)
                        ForEach(fieldNames, id: \.self) { fieldName in
                            Text("• \(fieldName)")
                                .bold()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            case .notEnoughIngredients:
                Text("Please add at least two \(model.ingredientsTitle.lowercased()) to be able to save this \(model.entityName.lowercased()).")
                    .fixedSize(horizontal: false, vertical: true)
            default:
                EmptyView()
            }
        }
        .foregroundColor(.secondary)
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .foregroundColor(fill)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
}
