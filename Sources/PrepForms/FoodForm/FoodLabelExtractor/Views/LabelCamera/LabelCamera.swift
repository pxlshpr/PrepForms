import SwiftUI
import SwiftHaptics
import ActivityIndicatorView
import Camera
import FoodLabelScanner

public struct LabelCamera: View {

    @Environment(\.dismiss) var dismiss
    @StateObject var cameraViewModel: CameraViewModel
    @StateObject var viewModel: ViewModel
    @State var hasAppeared = false
    
    let didTapDismiss: () -> ()
    
    public init(
        mockData: (ScanResult, UIImage)? = nil,
        imageHandler: @escaping ImageHandler,
        didTapDismiss: @escaping () -> ()
    ) {
        self.didTapDismiss = didTapDismiss
        
        let viewModel = ViewModel(mockData: mockData, imageHandler: imageHandler)
        _viewModel = StateObject(wrappedValue: viewModel)
        
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
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            cameraLayer
                .opacity(hasAppeared ? 1 : 0)
            if !viewModel.started {
                Instructions(tappedStart: tappedStart)
                    .zIndex(10)
                    .transition(.opacity)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    hasAppeared = true
                }
            }
        }
        .onChange(of: viewModel.shouldDismiss) { newValue in
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
    
    func tappedStart() {
        Haptics.feedback(style: .heavy)
        withAnimation {
            cameraViewModel.shouldShowScanOverlay = true
            viewModel.started = true
        }
#if targetEnvironment(simulator)
        viewModel.simulateScan()
#endif
    }
    
    var cameraLayer: some View {
        BaseCamera(imageHandler: handleCapturedImage)
            .environmentObject(cameraViewModel)
    }
    
    func handleCapturedImage(_ image: UIImage) {
        viewModel.imageHandler?(image)
        viewModel.imageHandler = nil
    }
}
