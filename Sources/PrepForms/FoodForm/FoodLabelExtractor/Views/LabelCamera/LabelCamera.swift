import SwiftUI
import SwiftHaptics
import ActivityIndicatorView
import Camera
import FoodLabelScanner

public struct LabelCamera: View {

    @Environment(\.dismiss) var dismiss
    @StateObject var cameraViewModel: CameraViewModel
    @StateObject var model: Model
    @State var hasAppeared = false
    
    let didTapDismiss: () -> ()
    
    public init(
        mockData: (ScanResult, UIImage)? = nil,
        imageHandler: @escaping ImageHandler,
        didTapDismiss: @escaping () -> ()
    ) {
        self.didTapDismiss = didTapDismiss
        
        let model = Model(mockData: mockData, imageHandler: imageHandler)
        _model = StateObject(wrappedValue: model)
        
        let cameraViewModel = CameraViewModel(
            mode: .capture,
            showCaptureAnimation: false,
            shouldShowScanOverlay: false,
            showDismissButton: true,
            showFlashButton: false,
            showTorchButton: true,
            showPhotoPickerButton: false,
            showCapturedImagesCount: false
        )
        _cameraViewModel = StateObject(wrappedValue: cameraViewModel)
    }
    
    public var body: some View {
        content
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    hasAppeared = true
                }
            }
        }
        .onChange(of: model.shouldDismiss) { newValue in
            if newValue {
                dismiss()
            }
        }
        .onChange(of: cameraViewModel.shouldDismiss) { newValue in
            if newValue {
                didTapDismiss()
            }
        }
    }
    
    var content: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            cameraLayer
                .opacity(hasAppeared ? 1 : 0)
            if !model.started {
                Instructions(tappedStart: tappedStart)
                    .zIndex(10)
                    .transition(.opacity)
            }
        }
    }
    
    func tappedStart() {
        Haptics.feedback(style: .heavy)
        withAnimation {
            cameraViewModel.shouldShowScanOverlay = true
            model.started = true
        }
#if targetEnvironment(simulator)
        model.simulateScan()
#endif
    }
    
    var cameraLayer: some View {
        BaseCamera(imageHandler: handleCapturedImage)
            .environmentObject(cameraViewModel)
    }
    
    func handleCapturedImage(_ image: UIImage) {
        model.imageHandler?(image)
        model.imageHandler = nil
    }
}
