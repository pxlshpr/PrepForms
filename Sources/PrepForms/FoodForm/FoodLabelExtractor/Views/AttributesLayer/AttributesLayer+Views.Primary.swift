import SwiftUI
import FoodLabelScanner

extension AttributesLayer {

    var primaryView: some View {
        var shadowLayer: some View {
            GeometryReader { proxy in
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: K.topButtonPaddedHeight)
                    ZStack {
                        VStack {
                            Rectangle()
                                .fill(.green)
                                .frame(height: 20)
                                .shadow(radius: 5.0, y: 2.0)
                                .position(x: proxy.size.width / 2.0, y: -10)
                                .opacity(0.4)
                            Spacer()
                        }
                    }
                    .frame(height: 20)
//                    .background(.yellow)
                    .clipped()
                    Spacer()
                }
            }
        }
        
        return ZStack {
            VStack(spacing: 0) {
                currentAttributeRow
                    .padding(.horizontal, K.topButtonsHorizontalPadding)
                if extractor.state.showsDivider {
                    Divider()
                        .opacity(0.5)
                        .padding(.top, K.topButtonsVerticalPadding)
                        .transition(.opacity)
                }
                if !extractor.extractedNutrients.isEmpty {
                    attributesList
                        .transition(.move(edge: .bottom))
                        .opacity(extractor.state == .showingKeyboard ? 0 : 1)
                } else if extractor.state == .awaitingColumnSelection {
                    columnPicker
                }
            }
            .padding(.vertical, K.topButtonsVerticalPadding)
            if extractor.state.showsDivider {
                shadowLayer
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: UIScreen.main.bounds.width)
    }
    
    var attributesList: some View {
        ScrollViewReader { scrollProxy in
            List($extractor.extractedNutrients, id: \.self.hashValue, editActions: .delete) { $nutrient in
                cell(for: nutrient)
                    .frame(maxWidth: .infinity)
                    .id(nutrient.attribute)
            }
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 60)
            }
            .scrollContentBackground(.hidden)
            .listStyle(.plain)
            .buttonStyle(.borderless)
            .onReceive(scannerDidChangeAttribute) { notification in
                
                guard let userInfo = notification.userInfo,
                      let attribute = userInfo[Notification.ScannerKeys.nextAttribute] as? Attribute,
                      extractor.extractedNutrients.contains(where: { $0.attribute == attribute })
                else { return }
                
                withAnimation {
                    scrollProxy.scrollTo(attribute, anchor: .center)
                }
                
            }
        }
    }
}
