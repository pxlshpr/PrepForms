import SwiftUI
import PrepDataTypes
import SwiftHaptics
import SwiftUISugar

extension AttributesLayer {
    
    var supplementaryContentLayer: some View {
        @ViewBuilder
        var attributeLayer: some View {
            if let currentAttribute = extractor.currentAttribute {
                VStack {
                    HStack {
                        Text(currentAttribute.description)
                            .matchedGeometryEffect(id: "attributeName", in: namespace)
//                            .textCase(.uppercase)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .offset(y: -3)
                            .foregroundColor(Color(.secondaryLabel))
                            .padding(.horizontal, 15)
                            .background(
                                Capsule(style: .continuous)
                                    .foregroundColor(keyboardColor)
//                                    .foregroundColor(.blue)
                                    .frame(height: 35)
                                    .transition(.scale)
                            )
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .frame(height: 20)
                    .offset(y: -10)
                    Spacer()
                }
            }
        }
        
        return VStack(spacing: 0) {
            Spacer()
            if extractor.state == .showingKeyboard {
                ZStack(alignment: .bottom) {
                    keyboardColor
                    attributeLayer
                    suggestionsLayer
                }
                .frame(maxWidth: .infinity)
                .frame(height: K.attributesLayerHeight)
                .transition(.opacity)
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

extension AttributesLayer {
    
    var topButtonsLayer: some View {
        var bottomPadding: CGFloat {
            K.topButtonPaddedHeight + K.suggestionsBarHeight + 8.0
        }
        
        var keyboardButton: some View {
            Button {
                tappedDismissKeyboard()
            } label: {
                DismissButtonLabel(forKeyboard: true)
            }
        }
        
        var sideButtonsLayer: some View {
            HStack {
//                dismissButton
                Spacer()
                keyboardButton
            }
            .transition(.opacity)
        }
        
        var shouldShow: Bool {
            extractor.state == .showingKeyboard
        }
        
        return Group {
            if shouldShow {
                VStack {
                    Spacer()
                    ZStack(alignment: .bottom) {
                        sideButtonsLayer
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, bottomPadding)
                    .frame(width: UIScreen.main.bounds.width)
                }
            }
        }
    }

}

extension AttributesLayer {

    var dismissButton: some View {
        Button {
            tappedDismiss()
        } label: {
            Image(systemName: "multiply")
                .imageScale(.medium)
                .fontWeight(.medium)
                .foregroundColor(Color(.secondaryLabel))
                .frame(width: 38, height: 38)
                .background(
                    Circle()
                        .foregroundStyle(.ultraThinMaterial)
                        .shadow(color: Color(.black).opacity(0.2), radius: 3, x: 0, y: 3)
                )
        }
    }
    
    var buttonsLayer: some View {
        
        var bottomPadding: CGFloat {
            return K.bottomSafeAreaPadding
        }
        
        var addButton: some View {
            var label: some View {
                Image(systemName: "plus")
                    .imageScale(.medium)
                    .fontWeight(.medium)
                    .foregroundColor(Color(.secondaryLabel))
                    .frame(width: 38, height: 38)
                    .background(
                        Circle()
                            .foregroundStyle(.ultraThinMaterial)
                            .shadow(color: Color(.black).opacity(0.2), radius: 3, x: 0, y: 3)
                    )
            }
            
            var button: some View {
                Button {
                    Haptics.feedback(style: .soft)
                    showingNutrientsPicker = true
                } label: {
                    label
                }
                .sheet(isPresented: $showingNutrientsPicker) { nutrientsPicker }
            }
            
            return ZStack {
                label
                button
            }
        }
        
        var addButtonRow: some View {
            var shouldShow: Bool {
                !extractor.state.isLoading
                && extractor.state != .awaitingColumnSelection
            }
            
            return HStack {
                Spacer()
                if shouldShow {
                    addButton
                        .transition(.move(edge: .trailing))
                }
            }
        }
        
        var doneButton: some View {
            var textColor: Color {
                extractor.state == .allConfirmed
                ? Color.white
                : Color.primary
            }
            
            @ViewBuilder
            var backgroundView: some View {
                ZStack {
                    RoundedRectangle(cornerRadius: 19, style: .continuous)
                        .foregroundStyle(.ultraThinMaterial)
                        .opacity(extractor.state == .allConfirmed ? 0 : 1)
                    RoundedRectangle(cornerRadius: 19, style: .continuous)
                        .foregroundStyle(Color.accentColor)
                        .opacity(extractor.state == .allConfirmed ? 1 : 0)
                }
                .shadow(color: Color(.black).opacity(0.2), radius: 3, x: 0, y: 3)
            }
            
            var shouldShow: Bool {
                let bool = !extractor.state.isLoading
                && extractor.state != .awaitingColumnSelection
                cprint("🟡 shouldShow for Done button: \(bool): extractor.state is \(extractor.state.rawValue)")
                return bool
            }
            
            return Group {
                if shouldShow {
                    Button {
                        tappedDone()
                    } label: {
                        Text("Done")
                            .imageScale(.medium)
                            .fontWeight(.medium)
                            .foregroundColor(textColor)
                            .frame(height: 38)
                            .padding(.horizontal, 15)
                            .background(backgroundView)
                    }
                    .transition(.move(edge: .trailing))
                }
            }
        }
        
        var topButtons: some View {
            HStack {
                dismissButton
                Spacer()
                doneButton
            }
        }
        
        var layer: some View {
            VStack {
                if !extractor.dismissState.shouldHideUI {
                    topButtons
                        .padding(.horizontal, 10)
                        .padding(.top, 10)
                        .transition(.move(edge: .top))
                }
                Spacer()
                if !extractor.dismissState.shouldHideUI {
                    addButtonRow
                        .padding(.horizontal, 20)
                        .padding(.bottom, bottomPadding)
                        .transition(.move(edge: .bottom))
                }
            }
            .frame(width: UIScreen.main.bounds.width)
            .edgesIgnoringSafeArea(.bottom)
        }
            
        return layer
    }
}
