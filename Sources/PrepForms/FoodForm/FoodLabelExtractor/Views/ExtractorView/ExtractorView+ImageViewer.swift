import SwiftUI

extension ExtractorView {
    
    @ViewBuilder
    var imageViewerLayer: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Color.clear.frame(height: K.topBarHeight)
                ZStack {
                    imageViewer
                    croppedImagesLayer
            }
                Spacer()
            }
            .transition(.opacity)
            .frame(height: imageViewerHeight)
            Spacer()
        }
        .edgesIgnoringSafeArea(.all)
        .opacity(extractor.transitionState.isTransitioning ? 0 : 1)
        .zIndex(8)
    }
    
    var imageViewer: some View {
        /// Overlay used to block scrolling when dismissing
        @ViewBuilder
        var overlay: some View {
            if extractor.dismissState.shouldHideUI {
                Color.white.opacity(0)
            }
        }
        
        return ImageViewer(viewModel: imageViewerViewModel)
            .overlay(overlay)
//            .opacity(extractor.dismissState.shouldShrinkImage ? 0 : 1)
            .offset(y: extractor.dismissState.shouldShrinkImage ? UIScreen.main.bounds.height + extractor.imageOffset : 0)
//            .scaleEffect(extractor.dismissState.shouldShrinkImage ? 0 : 1)
//            .padding(.top, extractor.dismissState.shouldShrinkImage ? 400 : 0)
//            .padding(.trailing, extractor.dismissState.shouldShrinkImage ? 300 : 0)
    }
    
    var imageViewerHeight: CGFloat {
        let screenHeight = UIScreen.main.bounds.height
        /// 🪄 Magic Number, no idea why but this works on iPhone 13 Pro Max, iPhone 14 Pro Max and iPhone X (there's a gap without it)
        let correctivePadding = 8.0
        return screenHeight - (K.keyboardHeight + K.topButtonPaddedHeight + K.suggestionsBarHeight) + correctivePadding
    }

    func imageChanged(_ image: UIImage?) {
        guard let image else { return }
        guard !extractor.isUsingCamera else { return }
        setImageInImageViewer(image)
        startExtracting(image: image)
    }
    
    func setImageInImageViewer(_ image: UIImage) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                imageViewerViewModel.image = image
            }
        }
    }
    
    func startExtracting(image: UIImage) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            extractor.begin()
        }
    }
}
