import SwiftUI
import Shimmer

public struct ImageViewer: View {
    
    @ObservedObject var model: ImageViewer.Model
    
    public init(model: ImageViewer.Model) {
        self.model = model
    }
    
    public var body: some View {
        ZStack {
            Color(.systemBackground)
            zoomableScrollView
        }
        .onChange(of: model.image, perform: imageChanged)
    }
    
    func imageChanged(_ image: UIImage?) {
        guard let image else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(name: .scannerDidSetImage, object: nil, userInfo: [
                Notification.ZoomableScrollViewKeys.imageSize: image.size
            ])
        }
    }
    
    @ViewBuilder
    var zoomableScrollView: some View {
        if let image = model.image {
            ZoomScrollView {
                VStack(spacing: 0) {
                    imageView(image)
                        .overlay(textBoxesLayer)
                        .overlay(scannedTextBoxesLayer)
                        .overlay(selectableTextBoxesLayer)
                }
            }
            .transition(.opacity)
        }
    }
    
    @ViewBuilder
    func imageView(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .background(.black)
            .opacity(model.imageOverlayOpacity)
            .animation(.default, value: model.showingBoxes)
    }
    
    var textBoxesLayer: some View {
        TextBoxesLayer(
            textBoxes: $model.textBoxes,
            shimmering: $model.isShimmering
        )
        .opacity(model.textBoxesOpacity)
        .animation(.default, value: model.textPickerHasAppeared)
        .animation(.interactiveSpring(), value: model.textBoxes)
        .animation(.default, value: model.showingBoxes)
        .animation(.default, value: model.isShimmering)
        .animation(.default, value: model.cutoutTextBoxes.count)
        .shimmering(active: model.isShimmering)
    }
    
    var selectableTextBoxesLayer: some View {
        TextBoxesLayer(
            textBoxes: $model.selectableTextBoxes,
            shimmering: .constant(false)
        )
        .opacity(model.textBoxesOpacity)
        .animation(.none, value: model.textPickerHasAppeared)
        .animation(.none, value: model.selectableTextBoxes)
        .animation(.none, value: model.showingBoxes)
        .animation(.none, value: model.isShimmering)
        .animation(.none, value: model.cutoutTextBoxes.count)
    }
    
    var scannedTextBoxesLayer: some View {
        TextBoxesLayer(
            textBoxes: $model.cutoutTextBoxes,
            isCutOut: true
        )
        .opacity(model.cutoutTextBoxesOpacity)
        .animation(.default, value: model.textPickerHasAppeared)
        .animation(.default, value: model.showingBoxes)
        .animation(.default, value: model.showingCutouts)
    }
}
