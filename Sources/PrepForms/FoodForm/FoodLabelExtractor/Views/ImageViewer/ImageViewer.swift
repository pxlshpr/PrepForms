import SwiftUI
import Shimmer

public struct ImageViewer: View {
    
    @ObservedObject var viewModel: ImageViewer.ViewModel
    
    public init(viewModel: ImageViewer.ViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ZStack {
            Color(.systemBackground)
            zoomableScrollView
        }
        .onChange(of: viewModel.image, perform: imageChanged)
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
        if let image = viewModel.image {
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
            .opacity(viewModel.imageOverlayOpacity)
            .animation(.default, value: viewModel.showingBoxes)
    }
    
    var textBoxesLayer: some View {
        TextBoxesLayer(
            textBoxes: $viewModel.textBoxes,
            shimmering: $viewModel.isShimmering
        )
        .opacity(viewModel.textBoxesOpacity)
        .animation(.default, value: viewModel.textPickerHasAppeared)
        .animation(.interactiveSpring(), value: viewModel.textBoxes)
        .animation(.default, value: viewModel.showingBoxes)
        .animation(.default, value: viewModel.isShimmering)
        .animation(.default, value: viewModel.cutoutTextBoxes.count)
        .shimmering(active: viewModel.isShimmering)
    }
    
    var selectableTextBoxesLayer: some View {
        TextBoxesLayer(
            textBoxes: $viewModel.selectableTextBoxes,
            shimmering: .constant(false)
        )
        .opacity(viewModel.textBoxesOpacity)
        .animation(.none, value: viewModel.textPickerHasAppeared)
        .animation(.none, value: viewModel.selectableTextBoxes)
        .animation(.none, value: viewModel.showingBoxes)
        .animation(.none, value: viewModel.isShimmering)
        .animation(.none, value: viewModel.cutoutTextBoxes.count)
    }
    
    var scannedTextBoxesLayer: some View {
        TextBoxesLayer(
            textBoxes: $viewModel.cutoutTextBoxes,
            isCutOut: true
        )
        .opacity(viewModel.cutoutTextBoxesOpacity)
        .animation(.default, value: viewModel.textPickerHasAppeared)
        .animation(.default, value: viewModel.showingBoxes)
        .animation(.default, value: viewModel.showingCutouts)
    }
}
