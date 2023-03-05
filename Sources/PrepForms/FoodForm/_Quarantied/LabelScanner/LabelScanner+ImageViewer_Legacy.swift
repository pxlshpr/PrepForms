//import SwiftUI
//import FoodLabelCamera
//import FoodLabelScanner
//import SwiftHaptics
//import ZoomableScrollView
//import SwiftSugar
//import Shimmer
//
//extension LabelScanner {
//    
//    var imageViewerLayer: some View {
//        
//        func imageViewer(_ image: UIImage) -> some View {
//            ImageViewer(
//                id: UUID(),
//                image: image,
//                textBoxes: $model.textBoxes,
//                scannedTextBoxes: $model.scannedTextBoxes,
//                contentMode: .fit,
//                zoomBox: $model.zoomBox,
//                showingBoxes: $model.showingBoxes,
//                showingCutouts: $model.showingCutouts,
//                shimmering: $model.shimmering,
//                isFocused: $model.showingColumnPicker
//            )
//            .edgesIgnoringSafeArea(.all)
////            .background(.black)
//            .scaleEffect(model.animatingCollapse ? 0 : 1)
//            .opacity(model.shimmeringImage ? 0.4 : 1)
//        }
//        
//        return Group {
//            if let image = model.image {
//                ZStack {
//                    imageViewer(image)
//                    croppedImagesLayer
//                        .scaleEffect(model.animatingCollapseOfCroppedImages ? 0 : 1)
//                        .padding(.top, model.animatingCollapseOfCroppedImages ? 0 : 0)
//                        .padding(.trailing, model.animatingCollapseOfCroppedImages ? 300 : 0)
//                }
////            } else {
////                Color.black
//            }
//        }
////        .edgesIgnoringSafeArea(.all)
//        .transition(.opacity)
//    }
//}
