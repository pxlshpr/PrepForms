//import SwiftUI
//import FoodLabelCamera
//import FoodLabelScanner
//import SwiftHaptics
//import ZoomableScrollView
//import SwiftSugar
//import Shimmer
//
////TODO: Magic Number 🪄
////let TopBarHeight: CGFloat = 83
//let TopBarHeight: CGFloat = 59
//
//extension Scanner {
//
//    @ViewBuilder
//    var imageViewerLayer: some View {
//        if let image = model.image {
//            VStack(spacing: 0) {
//                Color.clear.frame(height: TopBarHeight)
//                ZStack {
//                    imageViewer(image)
//                    croppedImagesLayer
//                        .scaleEffect(model.animatingCollapseOfCroppedImages ? 0 : 1)
//                        .padding(.top, model.animatingCollapseOfCroppedImages ? 0 : 0)
//                        .padding(.trailing, model.animatingCollapseOfCroppedImages ? 300 : 0)
//                }
////                .frame(height: imageViewerHeight)
////                .overlay(.green.opacity(0.5))
////                if model.showingTextField {
//                    Spacer()
////                }
//            }
//            .transition(.opacity)
//        }
//    }
//
//    func imageViewer(_ image: UIImage) -> some View {
//
//        let isFocused = Binding<Bool>(
//            get: { model.showingColumnPicker || model.showingValuePicker },
//            set: { _ in }
//        )
//
//        return ImageViewer(
//            id: UUID(),
//            image: image,
//            textBoxes: $model.textBoxes,
//            scannedTextBoxes: $model.scannedTextBoxes,
//            contentMode: .fit,
//            zoomBox: $model.zoomBox,
//            showingBoxes: $model.showingBoxes,
//            showingCutouts: $model.showingCutouts,
//            shimmering: $model.shimmering,
//            isFocused: isFocused
//        )
////        .edgesIgnoringSafeArea(.all)
////        .padding(.bottom, 0)
////            .frame(height: 473)
////            .padding(.bottom, 366)
////            .background(.green)
//        .scaleEffect(model.animatingCollapse ? 0 : 1)
//        .opacity(model.shimmeringImage ? 0.4 : 1)
//    }
//
//    @ViewBuilder
//    var croppedImagesLayer: some View {
//        if model.showingCroppedImages {
//            ZStack {
//                Color.clear
////                Color.blue.opacity(0.3)
//                ForEach(model.images.indices, id: \.self) { i in
//                    croppedImage(
//                        model.images[i].0,
//                        rect: model.images[i].1,
//                        stackedAngle: model.images[i].3,
//                        wiggleAngles: model.images[i].4
//                    )
//                }
//            }
//            .edgesIgnoringSafeArea(.all)
//            .transition(.opacity)
//        }
//    }
//
//}
