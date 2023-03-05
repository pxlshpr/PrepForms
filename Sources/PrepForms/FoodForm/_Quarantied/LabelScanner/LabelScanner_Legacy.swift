//import SwiftUI
//import FoodLabelCamera
//import FoodLabelScanner
//import SwiftHaptics
//import ZoomableScrollView
//import SwiftSugar
//import Shimmer
//import VisionSugar
//
//public struct LabelScanner: View {
//    
//    @Binding var selectedImage: UIImage?
//
//    //TODO: Remove these after moving to Model
//
////    @StateObject var model: LabelScannerModel
//    @ObservedObject var model: LabelScannerModel
//
////    public init(
////        isCamera: Bool = true,
////        image: Binding<UIImage?> = .constant(nil),
////        animatingCollapse: Binding<Bool>? = nil,
////        animateCollapse: (() -> ())? = nil,
////        imageHandler: @escaping (UIImage, ScanResult) -> (),
////        scanResultHandler: @escaping (ScanResult, Int?) -> (),
////        dismissHandler: @escaping () -> ()
////    ) {
////        self.animateCollapse = animateCollapse
////        _selectedImage = image
////        _animatingCollapse = animatingCollapse ?? .constant(false)
////
////
////        let model = LabelScannerModel(
////            isCamera: isCamera,
////            animatingCollapse: animatingCollapse?.wrappedValue ?? false,
////            imageHandler: imageHandler,
////            scanResultHandler: scanResultHandler,
////            dismissHandler: dismissHandler
////        )
////        _model = StateObject(wrappedValue: model)
////    }
//    
//    public init(
//        scanner: LabelScannerModel,
//        image: Binding<UIImage?> = .constant(nil)
//    ) {
//        _selectedImage = image
//        self.model = scanner
//    }
//    
//    public var body: some View {
//        ZStack {
//            if model.showingBlackBackground {
//                Color(.systemBackground)
////                Color.black
//                    .edgesIgnoringSafeArea(.all)
//            }
////            imageLayer
//            imageViewerLayer
//            cameraLayer
//            columnPickerLayer
//            if !model.animatingCollapse {
//                dismissLayer
//                    .transition(.scale)
//            }
//        }
//        .onChange(of: selectedImage) { newValue in
//            guard let newValue else { return }
//            handleCapturedImage(newValue)
//        }
////        .onChange(of: model.animatingCollapse) { newValue in
////            withAnimation {
////                self.animatingCollapse = newValue
////            }
////        }
//        .onChange(of: model.clearSelectedImage) { newValue in
//            guard newValue else { return }
//            withAnimation {
//                self.selectedImage = nil
//            }
//        }
//    }
//    
//    func dismiss() {
//        Haptics.feedback(style: .soft)
//        model.cancelAllTasks()
//        model.dismissHandler?()
//    }
//    
//    var dismissLayer: some View {
//        var cornerRadius: CGFloat {
//            model.showingColumnPickerUI ? 12 : 19
//        }
//        
//        var height: CGFloat {
//            model.showingColumnPickerUI ? 50 : 38
//        }
//        
//        var foregroundStyle: Material {
//            model.showingColumnPickerUI
//            ? .ultraThinMaterial
//            : .ultraThickMaterial
//        }
//
//        var bottomPadding: CGFloat {
//            model.showingColumnPickerUI ? 16 : 0
//        }
//        
//        return VStack {
//            Spacer()
//            HStack {
//                Button {
//                    dismiss()
//                } label: {
//                    Image(systemName: "chevron.down")
//                        .imageScale(.medium)
//                        .fontWeight(.medium)
//                        .foregroundColor(Color(.secondaryLabel))
//                        .frame(width: height, height: height)
//                        .background(
//                            RoundedRectangle(cornerRadius: cornerRadius)
//                                .foregroundStyle(foregroundStyle)
//                                .shadow(color: Color(.black).opacity(0.2), radius: 3, x: 0, y: 3)
//                        )
//                }
//                Spacer()
//            }
//            .padding(.horizontal, 20)
//            .padding(.bottom, bottomPadding)
//        }
//    }
//    
//    var columnPickerLayer: some View {
//        ColumnPickerOverlay(
//            isVisibleBinding: $model.showingColumnPickerUI,
//            leftTitle: model.leftColumnTitle,
//            rightTitle: model.rightColumnTitle,
//            selectedColumn: model.selectedColumnBinding,
//            didTapDismiss: model.dismissHandler,
//            didTapAutofill: { model.columnSelectionHandler() }
//        )
//    }
//    
//    @ViewBuilder
//    var imageLayer: some View {
//        if let selectedImage {
//            ZStack {
//                ZStack {
//                    Color.black
//
//                    Image(uiImage: selectedImage)
//                        .resizable()
//                        .aspectRatio(contentMode: .fit)
////                    Color.black
////                        .opacity(shimmeringImage ? 0.6 : 0)
//                }
//                .scaleEffect(model.animatingCollapse ? 0 : 1)
//                .padding(.top, model.animatingCollapse ? 400 : 0)
//                .padding(.trailing, model.animatingCollapse ? 300 : 0)
//                textBoxesLayer
//                croppedImagesCutoutLayer
//                    .scaleEffect(model.animatingCollapseOfCutouts ? 0 : 1)
//                    .opacity(model.animatingCollapseOfCutouts ? 0 : 1)
//                    .padding(.top, model.animatingCollapseOfCutouts ? 400 : 0)
//                    .padding(.trailing, model.animatingCollapseOfCutouts ? 300 : 0)
//                croppedImagesLayer
//                    .scaleEffect(model.animatingCollapseOfCroppedImages ? 0 : 1)
//                    .padding(.top, model.animatingCollapseOfCroppedImages ? 0 : 0)
//                    .padding(.trailing, model.animatingCollapseOfCroppedImages ? 300 : 0)
//            }
//            .edgesIgnoringSafeArea(.all)
////            .transition(.move(edge: .bottom))
//            .transition(.opacity)
//        }
//    }
//}
//
//extension ScanResult {
//
//    var relevantTexts: [RecognizedText] {
//        let texts = nutrientValueTexts + resultTexts
//        return texts.removingDuplicates()
//    }
//
//    var textBoxes: [TextBox] {
//        
//        var textBoxes: [TextBox] = []
//        textBoxes = allTexts.map {
//            TextBox(
//                id: $0.id,
//                boundingBox: $0.boundingBox,
//                color: .accentColor,
//                opacity: 0.8,
//                tapHandler: {}
//            )
//        }
//        
////        textBoxes.append(
////            contentsOf: barcodes(for: imageModel).map {
////                TextBox(boundingBox: $0.boundingBox,
////                        color: color(for: $0),
////                        tapHandler: tapHandler(for: $0)
////                )
////        })
//        return textBoxes
//    }
//    
//}
//
//extension UIImage {
//    
//    //TODO: Make this work for images that are TALLER than the screen width
//    var boundingBoxForScreenFill: CGRect {
//        
//        
//        let screen = UIScreen.main.bounds
//        
//        let scaledWidth: CGFloat = (size.width * screen.height) / size.height
//
//        let x: CGFloat = ((scaledWidth - screen.width) / 2.0)
//        let h: CGFloat = size.height
//        
//        let rect = CGRect(
//            x: x / scaledWidth,
//            y: 0,
//            width: (screen.width / scaledWidth),
//            height: h / size.height
//        )
//
//        cprint("🧮 scaledWidth: \(scaledWidth)")
//        cprint("🧮 screen: \(screen)")
//        cprint("🧮 imageSize: \(size)")
//        cprint("🧮 rect: \(rect)")
//        return rect
//    }
//}
//
//struct PreviewView: PreviewProvider {
//    static let r: CGFloat = 1
//    static var previews: some View {
//        Rectangle()
//            .fill(
////                .shadow(.inner(color: Color(red: 197/255, green: 197/255, blue: 197/255),radius: r, x: r, y: r))
////                .shadow(.inner(color: .white, radius: r, x: -r, y: -r))
//                .shadow(.inner(color: Color(red: 197/255, green: 197/255, blue: 197/255),radius: r, x: r, y: r))
//                .shadow(.inner(color: .white, radius: r, x: -r, y: -r))
//            )
////            .foregroundColor(Color(red: 236/255, green: 234/255, blue: 235/255))
//            .foregroundColor(Color(hex: "2A2A2C"))
//            .frame(width: 100, height: 100)
//    }
//}
