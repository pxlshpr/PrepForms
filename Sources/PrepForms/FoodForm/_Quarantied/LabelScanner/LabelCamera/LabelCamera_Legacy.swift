//import SwiftUI
//import SwiftHaptics
//import ActivityIndicatorView
//import Camera
//import FoodLabelScanner
//
//public struct LabelCamera: View {
//
//    @Environment(\.dismiss) var dismiss
//    @StateObject var cameraModel: CameraModel
//    @StateObject var model: Model
//    
//    public init(mockData: (ScanResult, UIImage)? = nil, imageHandler: @escaping ImageHandler) {
//        
//        let model = Model(mockData: mockData, imageHandler: imageHandler)
//        _model = StateObject(wrappedValue: model)
//        
//        let cameraModel = CameraModel(
//            mode: .capture,
//            showCaptureAnimation: false,
//            shouldShowScanOverlay: false,
//            showDismissButton: true,
//            showFlashButton: false,
//            showTorchButton: true,
//            showPhotoPickerButton: false,
//            showCapturedImagesCount: false
//        )
//        _cameraModel = StateObject(wrappedValue: cameraModel)
//    }
//    
//    @State var hasAppeared = false
//    
//    public var body: some View {
//        ZStack {
//            Color.black
//                .edgesIgnoringSafeArea(.all)
//            cameraLayer
//                .opacity(hasAppeared ? 1 : 0)
//            if !model.started {
//                Instructions(tappedStart: tappedStart)
//                    .zIndex(10)
//                    .transition(.opacity)
//            }
//        }
//        .onAppear {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                withAnimation {
//                    hasAppeared = true
//                }
//            }
//        }
//        .onChange(of: model.shouldDismiss) { newShouldDismiss in
//            if newShouldDismiss {
//                dismiss()
//            }
//        }
//        .onChange(of: cameraModel.shouldDismiss) { newShouldDismiss in
//            if newShouldDismiss {
//                dismiss()
//            }
//        }
//    }
//    
//    func tappedStart() {
//        Haptics.feedback(style: .heavy)
//        withAnimation {
//            cameraModel.shouldShowScanOverlay = true
//            model.started = true
//        }
//#if targetEnvironment(simulator)
//        model.simulateScan()
//#endif
//    }
//    
//    var cameraLayer: some View {
//        BaseCamera(imageHandler: handleCapturedImage)
//            .environmentObject(cameraModel)
//    }
//    
//    func handleCapturedImage(_ image: UIImage) {
//        model.imageHandler?(image)
//        model.imageHandler = nil
//    }
//}
