//import SwiftUI
//import FoodLabelCamera
//import FoodLabelScanner
//import SwiftHaptics
//import ZoomableScrollView
//import SwiftSugar
//import Shimmer
//import VisionSugar
//
//@MainActor
//public class LabelScannerViewModel: ObservableObject {
//
//    var isCamera: Bool
//    var imageHandler: ((UIImage, ScanResult) -> ())?
//    var scanResultHandler: ((ScanResult, Int?) -> ())?
//    var dismissHandler: (() -> ())?
//
//    @Published var hideCamera = false
//    @Published var textBoxes: [TextBox] = []
//    @Published var textSet: RecognizedTextSet? = nil
//    @Published var scanResult: ScanResult? = nil
//    @Published var image: UIImage? = nil
//    @Published var images: [(UIImage, CGRect, UUID, Angle, (Angle, Angle, Angle, Angle))] = []
//    @Published var stackedOnTop: Bool = false
//    @Published var scannedTextBoxes: [TextBox] = []
//    @Published var animatingCollapse: Bool = false
//    @Published var animatingCollapseOfCutouts = false
//    @Published var animatingCollapseOfCroppedImages = false
//    @Published var animatingLiftingUpOfCroppedImages = false
//    
//    @Published var animatingFirstWiggleOfCroppedImages = false
//    @Published var animatingSecondWiggleOfCroppedImages = false
//    @Published var animatingThirdWiggleOfCroppedImages = false
//    @Published var animatingFourthWiggleOfCroppedImages = false
//
//    @Published var columns: ScannedColumns = ScannedColumns()
//    @Published var selectedImageTexts: [ImageText] = []
//    @Published var zoomBox: ZBox? = nil
//    @Published var shimmering = false
//    @Published var shimmeringImage = false
//    @Published var showingColumnPicker = false
//    @Published var showingColumnPickerUI = false
//    @Published var showingCroppedImages = false
//    @Published var showingBlackBackground = true
//    @Published var showingBoxes = false
//    @Published var showingCutouts = false
//    @Published var clearSelectedImage: Bool = false
//    var lastContentOffset: CGPoint? = nil
//    var lastContentSize: CGSize? = nil
//    var waitingForZoomToEndToShowCroppedImages = false
//    var croppedImages: [RecognizedText : UIImage] = [:]
//    var croppingStatus: CroppingStatus = .idle
//    var waitingToShowCroppedImages = false
//
//    var scanTask: Task<(), Error>? = nil
//    var scanProcessTask: Task<(), Error>? = nil
//    var croppingTask: Task<(), Error>? = nil
//    var showingCroppedImagesTask: Task<(), Error>? = nil
//    var stackingCroppedImagesOnTopTask: Task<(), Error>? = nil
//    var zoomEndHandlerTask: Task<(), Error>? = nil
//    var columnSelectionHandlerTask: Task<(), Error>? = nil
//    var writeTestDataTask: Task<(), Error>? = nil
//
//    enum CroppingStatus {
//        case idle
//        case started
//        case complete
//    }
//    
//    let id = UUID()
//    let createTestData: Bool
//    
//    public init(
//        isCamera: Bool,
//        createTestData: Bool = false,
//        imageHandler: @escaping (UIImage, ScanResult) -> (),
//        scanResultHandler: @escaping (ScanResult, Int?) -> (),
//        dismissHandler: @escaping () -> ()
//    ) {
//        self.createTestData = createTestData
//        self.isCamera = isCamera
//        self.imageHandler = imageHandler
//        self.scanResultHandler = scanResultHandler
//        self.dismissHandler = dismissHandler
//        
//        self.hideCamera = !isCamera
////        self.showingBlackBackground = !isCamera
//        
//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(zoomableScrollViewDidEndZooming),
//            name: .zoomableScrollViewDidEndZooming,
//            object: nil
//        )
//        
//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(zoomableScrollViewDidEndZooming),
//            name: .zoomableScrollViewDidEndScrollingAnimation,
//            object: nil
//        )
//    }
//
//    @objc func zoomableScrollViewDidEndZooming(_ notification: Notification) {
//        guard let userInfo = notification.userInfo,
//              let contentOffset = userInfo[Notification.ZoomableScrollViewKeys.contentOffset] as? CGPoint,
//              let contentSize = userInfo[Notification.ZoomableScrollViewKeys.contentSize] as? CGSize
//        else { return }
//        
//        lastContentOffset = contentOffset
//        lastContentSize = contentSize
//        cprint("LabelScannerViewModel: 🚠 scrollViewDidEndZooming — offset: \(contentOffset) size: \(contentSize)")
//        
//        handleZoomEndINeeded()
//    }
//    
//    var leftColumnTitle: String {
//        guard let scanResult else { return "" }
//        return scanResult.headerTitle1
//    }
//    
//    var rightColumnTitle: String {
//        guard let scanResult else { return "" }
//        return scanResult.headerTitle2
//    }
//    
//    func handleZoomEndINeeded() {
//        guard waitingForZoomToEndToShowCroppedImages else {
//            cprint("🫥 handleZoomEndINeeded – not waiting, so returning")
//            return
//        }
//        cprint("🫥 handleZoomEndINeeded – waiting, so setting it to false and continuing")
//        waitingForZoomToEndToShowCroppedImages = false
//        zoomEndHandlerTask = Task.detached { [weak self] in
//            guard let self else { return }
//            guard !Task.isCancelled else { return }
//            switch await self.croppingStatus {
//            case .complete:
//                cprint("✂️ didEndZooming with CroppingStatus.complete — Now show cropped images")
//                await self.showCroppedImages()
//            case .started:
//                cprint("✂️ didEndZooming with CroppingStatus.started — Wait till cropping is done")
//                await MainActor.run { [weak self] in
//                    self?.waitingToShowCroppedImages = true
//                }
//            case .idle:
//                cprint("✂️ didEndZooming with CroppingStatus.idle — shouldn't ever get here")
//            }
////                try await self?.cropImages()
//        }
//    }
//    
//    public convenience init(createTestData: Bool = false) {
//        self.init(
//            isCamera: false,
//            createTestData: createTestData,
//            imageHandler: { _, _ in },
//            scanResultHandler:  { _, _ in },
//            dismissHandler: { }
//        )
//    }
//    
//    func reset() {
//        hideCamera = false
//        animatingCollapse = false
//        animatingCollapseOfCutouts = false
//        animatingCollapseOfCroppedImages = false
//        animatingLiftingUpOfCroppedImages = false
//        
//        shimmering = false
//        shimmeringImage = false
//        showingColumnPicker = false
//        showingColumnPickerUI = false
//        showingCroppedImages = false
//        showingBlackBackground = true
//        showingBoxes = false
//        showingCutouts = false
//        textBoxes = []
//        textSet = nil
//        scanResult = nil
//        image = nil
//        images = []
//        stackedOnTop = false
//        scannedTextBoxes = []
//        columns = ScannedColumns()
//        selectedImageTexts = []
//        zoomBox = nil
//        clearSelectedImage = false
//        lastContentOffset = nil
//        lastContentSize = nil
//        waitingForZoomToEndToShowCroppedImages = false
//        croppedImages = [:]
//        croppingStatus = .idle
//        waitingToShowCroppedImages = false
//        
//        cancelAllTasks()
//        scanTask = nil
//        scanProcessTask = nil
//        croppingTask = nil
//        showingCroppedImagesTask = nil
//        stackingCroppedImagesOnTopTask = nil
//        zoomEndHandlerTask = nil
//        columnSelectionHandlerTask = nil
//        writeTestDataTask = nil
//    }
//    
//    func cancelAllTasks() {
//        scanTask?.cancel()
//        scanProcessTask?.cancel()
//        croppingTask?.cancel()
//        showingCroppedImagesTask?.cancel()
//        stackingCroppedImagesOnTopTask?.cancel()
//        zoomEndHandlerTask?.cancel()
//        columnSelectionHandlerTask?.cancel()
//        writeTestDataTask?.cancel()
//    }
//    
//    func begin(_ image: UIImage) {
//        self.startScan(image)
//    }
//
//    func begin_test(_ image: UIImage) {
//        Task.detached { [weak self] in
//            guard let self else { return }
//            try await sleepTask(1.0, tolerance: 0.1)
//            await self.dismissHandler?()
////            try await self.collapse()
////            let textSet = try await image.recognizedTextSet(for: .accurate, includeBarcodes: true)
////            let scanResult = textSet.scanResult
//        }
//    }
//
//    func zoomOutCompletely(_ image: UIImage, animated: Bool = false) {
//        let zoomBox = self.getZoomBox(for: image, animated: animated)
//        let userInfo = [Notification.ZoomableScrollViewKeys.zoomBox: zoomBox]
//        NotificationCenter.default.post(name: .zoomZoomableScrollView, object: nil, userInfo: userInfo)
//    }
//    
//    func startScan(_ image: UIImage) {
//
//        scanTask = Task.detached { [weak self] in
//            
//            guard let self else { return }
//            
//            Haptics.selectionFeedback()
//            
//            guard !Task.isCancelled else { return }
//            await MainActor.run { [weak self] in
//                self?.zoomOutCompletely(image)
//            }
//            
//            guard !Task.isCancelled else { return }
//            if await self.isCamera {
//                await MainActor.run { [weak self] in
//                    withAnimation {
//                        self?.hideCamera = true
//                    }
//                }
//            } else {
//                /// Ensure the sliding up animation is complete first
//                try await sleepTask(0.2, tolerance: 0.005)
//            }
//            
//            /// Now capture recognized texts
//            /// - captures all the RecognizedTexts
//            guard !Task.isCancelled else { return }
//            let textSet = try await image.recognizedTextSet(for: .accurate, includeBarcodes: true)
//            await MainActor.run { [weak self] in
//                withAnimation {
//                    self?.textSet = textSet
//                }
//            }
//            
//            guard !Task.isCancelled else { return }
//            let textBoxes = textSet.texts.map {
//                TextBox(
//                    id: $0.id,
//                    boundingBox: $0.boundingBox,
//                    color: .accentColor,
//                    opacity: 0.8,
//                    tapHandler: {}
//                )
//            }
//            
//            Haptics.selectionFeedback()
//
//            /// **VisionKit Scan Completed**: Show all `RecognizedText`'s
//            guard !Task.isCancelled else { return }
//            await MainActor.run {  [weak self] in
//                guard let self else { return }
//                withAnimation {
//                    self.shimmeringImage = false
//                    self.textBoxes = textBoxes
//                    self.showingBoxes = true
//                }
//            }
//
//            try await sleepTask(0.2, tolerance: 0.005)
//            guard !Task.isCancelled else { return }
//            await MainActor.run { [weak self] in
//                self?.shimmering = true
//            }
//
//            try await sleepTask(1, tolerance: 0.005)
//            
//            guard !Task.isCancelled else { return }
//            try await self.scan(textSet: textSet)
//        }
//    }
//    
//    func scan(textSet: RecognizedTextSet) async throws {
//        
//        scanProcessTask = Task.detached { [weak self] in
//            guard let self else { return }
//            let scanResult = textSet.scanResult
//
//            guard !Task.isCancelled else { return }
//            await MainActor.run { [weak self] in
//                guard let self else { return }
//                self.scanResult = scanResult
//                self.showingBlackBackground = false
//            }
//            
////            await self.writeTestData()
//            
//            guard !Task.isCancelled else { return }
//
//            await self.startCroppingImages()
//
//            if scanResult.columnCount == 2 {
//                try await self.showColumnPicker()
//            } else {
//                /// If we're not showing the column picker—zoom into the texts we'll be extracting, and wait for long enough to get the new `contentOffset` and `contentSize`
//                if await self.shouldZoomToTextsToCrop == true {
//                    await self.zoomToTextsToCrop()
//                    await MainActor.run { [weak self] in
//                        self?.waitingForZoomToEndToShowCroppedImages = true
//                    }
////                } else {
////                    try await self.cropImages()
//                } else {
//                    await MainActor.run { [weak self] in
//                        self?.waitingToShowCroppedImages = true
//                    }
//                }
//            }
//        }
//    }
//    
//    func startCroppingImages() {
//        guard let image else { return }
//
//        croppingTask = Task.detached { [weak self] in
//            guard let self else { return }
//            
//            guard !Task.isCancelled else { return }
//            await MainActor.run { [weak self] in
//                self?.croppingStatus = .started
//            }
//            cprint("✂️ Starting cropping")
//            
//            var croppedImages: [RecognizedText : UIImage] = [:]
//            for text in await self.allTexts {
//                guard !Task.isCancelled else { return }
//                guard let croppedImage = await image.cropped(boundingBox: text.boundingBox) else {
//                    cprint("Couldn't get image for box: \(text)")
//                    continue
//                }
//                cprint("✂️ Cropped: \(text.string)")
//                croppedImages[text] = croppedImage
//            }
//
//            guard !Task.isCancelled else { return }
//            await MainActor.run { [weak self, croppedImages] in
//                cprint("✂️ Cropping completed, setting dict and status")
//                self?.croppedImages = croppedImages
//                self?.croppingStatus = .complete
//            }
//            
//            if await self.waitingToShowCroppedImages {
//                cprint("✂️ Was waitingToShowCroppedImages, so showing now")
//                await self.showCroppedImages()
//            }
//        }
//    }
//    
//    func showCroppedImages() {
//        cprint("✂️ Showing cropped images")
//        showingCroppedImagesTask = Task.detached { [weak self] in
//            
//            guard let self else { return }
//            guard !Task.isCancelled else { return }
//
//            for (text, cropped) in await self.croppedImages {
//                guard !Task.isCancelled else { return }
//                guard await self.textsToCrop.contains(where: { $0.id == text.id }) else {
//                    cprint("✂️ Not including: \(text.string) since it's not in textsToCrop")
//                    continue
//                }
//                
//                cprint("✂️ Getting rect for: \(text.string)")
//                let correctedRect = await self.rectForText(text)
//                
//                await MainActor.run { [weak self] in
//                    guard let self else { return }
//                    let randomWiggleAngles = self.randomWiggleAngles
//                    
//                    if !self.images.contains(where: { $0.2 == text.id }) {
//                        self.images.append((
//                            cropped,
//                            correctedRect,
//                            text.id,
//                            Angle.degrees(CGFloat.random(in: -20...20)),
//                            randomWiggleAngles
//                        ))
//                    }
//                }
//            }
//            
//            guard !Task.isCancelled else { return }
//            Haptics.selectionFeedback()
//            
//            guard !Task.isCancelled else { return }
//            await MainActor.run { [weak self] in
//                guard let self else { return }
//                withAnimation {
//                    self.textBoxes = []
//                    self.showingCroppedImages = true
//                    self.scannedTextBoxes = self.getScannedTextBoxes
//                }
//            }
//            
//            try await sleepTask(0.1, tolerance: 0.01)
//
//            guard !Task.isCancelled else { return }
//            await self.stackCroppedImagesOnTop()
//        }
//    }
//    
//    func stackCroppedImagesOnTop() {
//        stackingCroppedImagesOnTopTask = Task.detached { [weak self] in
//            
//            guard let self else { return }
//            guard !Task.isCancelled else { return }
//
//            await MainActor.run { [weak self] in
//                guard let self else { return }
//                withAnimation {
//                    self.showingCutouts = true
//                    self.animatingLiftingUpOfCroppedImages = true
//                }
//            }
//
//            let Bounce: Animation = .interactiveSpring(response: 0.35, dampingFraction: 0.66, blendDuration: 0.35)
//
//            try await sleepTask(Double.random(in: 0.05...0.15), tolerance: 0.01)
//
//            guard !Task.isCancelled else { return }
//            await MainActor.run { [weak self] in
//                guard let self else { return }
//                Haptics.selectionFeedback()
//                withAnimation(Bounce) {
//                    self.animatingFirstWiggleOfCroppedImages = true
//                }
//            }
//
//            try await sleepTask(Double.random(in: 0.05...0.15), tolerance: 0.01)
//
//            guard !Task.isCancelled else { return }
//            await MainActor.run { [weak self] in
//                guard let self else { return }
//                Haptics.selectionFeedback()
//                withAnimation(Bounce) {
//                    self.animatingFirstWiggleOfCroppedImages = false
//                    self.animatingSecondWiggleOfCroppedImages = true
//                }
//            }
//
//            try await sleepTask(Double.random(in: 0.05...0.15), tolerance: 0.01)
//
//            guard !Task.isCancelled else { return }
//            await MainActor.run { [weak self] in
//                guard let self else { return }
//                Haptics.selectionFeedback()
//                withAnimation(Bounce) {
//                    self.animatingSecondWiggleOfCroppedImages = false
//                    self.animatingThirdWiggleOfCroppedImages = true
//                }
//            }
//
//            try await sleepTask(Double.random(in: 0.05...0.15), tolerance: 0.01)
//
//            guard !Task.isCancelled else { return }
//            await MainActor.run { [weak self] in
//                guard let self else { return }
//                Haptics.selectionFeedback()
//                withAnimation(Bounce) {
//                    self.animatingThirdWiggleOfCroppedImages = false
//                    self.animatingFourthWiggleOfCroppedImages = true
//                }
//            }
//
//            try await sleepTask(Double.random(in: 0.3...0.5), tolerance: 0.01)
//
//            guard !Task.isCancelled else { return }
//            await MainActor.run { [weak self] in
//                guard let self else { return }
//                Haptics.feedback(style: .soft)
//                withAnimation(Bounce) {
//                    self.animatingFourthWiggleOfCroppedImages = false
//                    self.stackedOnTop = true
//                }
//            }
//            
//            try await sleepTask(0.8, tolerance: 0.01)
//            
//            await self.writeTestData()
//
//            guard !Task.isCancelled else { return }
//            try await self.collapse()
//        }
//    }
//    
////    func cropImages() async throws {
////        guard let image else { return }
////
////        Task.detached { [weak self] in
////
////            guard let self else { return }
////
////            for text in await self.textsToCrop {
////                guard let cropped = await image.cropped(boundingBox: text.boundingBox) else {
////                    cprint("Couldn't get image for box: \(text)")
////                    continue
////                }
////
////                cprint("📐 Getting rect for: \(text.string)")
////                let correctedRect = await self.rectForText(text)
////
////                await MainActor.run { [weak self] in
////                    guard let self else { return }
////                    let randomWiggleAngles = self.randomWiggleAngles
////
////                    if !self.images.contains(where: { $0.2 == text.id }) {
////                        self.images.append((
////                            cropped,
////                            correctedRect,
////                            text.id,
////                            Angle.degrees(CGFloat.random(in: -20...20)),
////                            randomWiggleAngles
////                        ))
////                    }
////                }
////            }
////
////            Haptics.selectionFeedback()
////
////            await MainActor.run { [weak self] in
////                guard let self else { return }
////                withAnimation {
////                    self.textBoxes = []
////                    self.showingCroppedImages = true
//////                    self.scannedTextBoxes = scanResult.textBoxes
////                    self.scannedTextBoxes = self.getScannedTextBoxes
////                }
////            }
////
////            try await sleepTask(0.1, tolerance: 0.01)
////
////            await MainActor.run { [weak self] in
////                guard let self else { return }
////                withAnimation {
////                    self.showingCutouts = true
////                    self.animatingLiftingUpOfCroppedImages = true
////                }
////            }
////
////            let Bounce: Animation = .interactiveSpring(response: 0.35, dampingFraction: 0.66, blendDuration: 0.35)
////
////            try await sleepTask(Double.random(in: 0.05...0.15), tolerance: 0.01)
////
////            await MainActor.run { [weak self] in
////                guard let self else { return }
////                Haptics.selectionFeedback()
////                withAnimation(Bounce) {
////                    self.animatingFirstWiggleOfCroppedImages = true
////                }
////            }
////
////            try await sleepTask(Double.random(in: 0.05...0.15), tolerance: 0.01)
////
////            await MainActor.run { [weak self] in
////                guard let self else { return }
////                Haptics.selectionFeedback()
////                withAnimation(Bounce) {
////                    self.animatingFirstWiggleOfCroppedImages = false
////                    self.animatingSecondWiggleOfCroppedImages = true
////                }
////            }
////
////            try await sleepTask(Double.random(in: 0.05...0.15), tolerance: 0.01)
////
////            await MainActor.run { [weak self] in
////                guard let self else { return }
////                Haptics.selectionFeedback()
////                withAnimation(Bounce) {
////                    self.animatingSecondWiggleOfCroppedImages = false
////                    self.animatingThirdWiggleOfCroppedImages = true
////                }
////            }
////
////            try await sleepTask(Double.random(in: 0.05...0.15), tolerance: 0.01)
////
////            await MainActor.run { [weak self] in
////                guard let self else { return }
////                Haptics.selectionFeedback()
////                withAnimation(Bounce) {
////                    self.animatingThirdWiggleOfCroppedImages = false
////                    self.animatingFourthWiggleOfCroppedImages = true
////                }
////            }
////
////            try await sleepTask(Double.random(in: 0.3...0.5), tolerance: 0.01)
////
////            await MainActor.run { [weak self] in
////                guard let self else { return }
////                Haptics.feedback(style: .soft)
////                withAnimation(Bounce) {
////                    self.animatingFourthWiggleOfCroppedImages = false
////                    self.stackedOnTop = true
////                }
////            }
////
////            try await sleepTask(0.8, tolerance: 0.01)
////
////            try await self.collapse()
////        }
////    }
//
//    var shouldZoomToTextsToCrop: Bool {
//        guard !showingColumnPicker else { return false }
//        let boundingBox = textsToCrop.boundingBox
//        return boundingBox.height < 0.6
//    }
//    
//    var allTexts: [RecognizedText] {
//        scanResult?.allTexts ?? []
//    }
//    
//    var textsToCrop: [RecognizedText] {
//        guard let scanResult else { return [] }
//        if showingColumnPicker {
//            var texts: [RecognizedText] = []
//            for selectedImageText in selectedImageTexts {
//                texts.append(selectedImageText.text)
//                if let attributeText = selectedImageText.attributeText {
//                    texts.append(attributeText)
//                }
//            }
//            texts.append(contentsOf: scanResult.servingTexts)
//            switch columns.selectedColumnIndex {
//            case 2:
//                if let text = scanResult.headers?.headerText2?.text  {
//                    texts.append(text)
//                }
//            default:
//                if let text = scanResult.headers?.headerText1?.text {
//                    texts.append(text)
//                }
//            }
//            return texts
//        } else {
//            return scanResult.allTexts
//        }
//    }
//    
//    var getScannedTextBoxes: [TextBox] {
//        textsToCrop.map {
//            TextBox(
//                id: $0.id,
//                boundingBox: $0.boundingBox,
//                color: .accentColor,
//                opacity: 0.8,
//                tapHandler: {}
//            )
//        }
//    }
//
//    func getRectForText(_ text: RecognizedText, contentSize: CGSize, contentOffset: CGPoint) -> CGRect {
//        /// Get the bounding box in terms of the (scaled) image dimensions
//        let rect = text.boundingBox.rectForSize(contentSize)
//
//        cprint("    📐 Getting rectForSize for: \(text.string) \(rect)")
//
//        /// Now offset it by the scrollview's current offset to get it's current position
//        return CGRect(
//            x: rect.origin.x - contentOffset.x,
//            y: rect.origin.y - contentOffset.y,
//            width: rect.size.width,
//            height: rect.size.height
//        )
//    }
//    
//    func rectForText(_ text: RecognizedText) -> CGRect {
//        
//        if let lastContentSize, let lastContentOffset {
//            cprint("    📐 Have contentSize and contentOffset, so calculating")
//            return getRectForText(text, contentSize: lastContentSize, contentOffset: lastContentOffset)
//        }
//        cprint("    📐 DON'T Have contentSize and contentOffset, doing it manually")
//
//        //TODO: Try and always have lastContentSize and lastContentOffset and calculate using those
//        let boundingBox = text.boundingBox
//        guard let image else { return .zero }
//        
//        let screen = UIScreen.main.bounds
//        
//        let correctedRect: CGRect
//        if self.isCamera {
//            let scaledWidth: CGFloat = (image.size.width * screen.height) / image.size.height
//            let scaledSize = CGSize(width: scaledWidth, height: screen.height)
//            let rectForSize = boundingBox.rectForSize(scaledSize)
//            
//            correctedRect = CGRect(
//                x: rectForSize.origin.x - ((scaledWidth - screen.width) / 2.0),
//                y: rectForSize.origin.y,
//                width: rectForSize.size.width,
//                height: rectForSize.size.height
//            )
//            
//            cprint("🌱 box.boundingBox: \(boundingBox)")
//            cprint("🌱 scaledSize: \(scaledSize)")
//            cprint("🌱 rectForSize: \(rectForSize)")
//            cprint("🌱 correctedRect: \(correctedRect)")
//            cprint("🌱 image.boundingBoxForScreenFill: \(image.boundingBoxForScreenFill)")
//            
//            
//        } else {
//            
//            let rectForSize: CGRect
//            let x: CGFloat
//            let y: CGFloat
//            
//            if image.size.widthToHeightRatio > screen.size.widthToHeightRatio {
//                /// This means we have empty strips at the top, and image gets width set to screen width
//                let scaledHeight = (image.size.height * screen.width) / image.size.width
//                let scaledSize = CGSize(width: screen.width, height: scaledHeight)
//                rectForSize = boundingBox.rectForSize(scaledSize)
//                x = rectForSize.origin.x
//                y = rectForSize.origin.y + ((screen.height - scaledHeight) / 2.0)
//                
//                cprint("🌱 scaledSize: \(scaledSize)")
//            } else {
//                let scaledWidth = (image.size.width * screen.height) / image.size.height
//                let scaledSize = CGSize(width: scaledWidth, height: screen.height)
//                rectForSize = boundingBox.rectForSize(scaledSize)
//                x = rectForSize.origin.x + ((screen.width - scaledWidth) / 2.0)
//                y = rectForSize.origin.y
//            }
//            
//            correctedRect = CGRect(
//                x: x,
//                y: y,
//                width: rectForSize.size.width,
//                height: rectForSize.size.height
//            )
//            
//            cprint("🌱 rectForSize: \(rectForSize)")
//            cprint("🌱 correctedRect: \(correctedRect), screenHeight: \(screen.height)")
//        }
//        return correctedRect
//    }
//    
//    func zoomToTextsToCrop() async {
//        guard let imageSize = image?.size else { return }
//        let boundingBox = self.textsToCrop.filter({ $0.id != defaultUUID }).boundingBox
//        
//        let columnZoomBox = ZBox(
//            boundingBox: boundingBox,
//            animated: true,
//            padded: true,
//            imageSize: imageSize
//        )
//
//        cprint("🏎 zooming to boundingBox: \(boundingBox)")
//        await MainActor.run { [weak self] in
//            guard let _ = self else { return }
//            NotificationCenter.default.post(
//                name: .zoomZoomableScrollView,
//                object: nil,
//                userInfo: [Notification.ZoomableScrollViewKeys.zoomBox: columnZoomBox]
//            )
//        }
//    }
//    
//    var randomWiggleAngles: (Angle, Angle, Angle, Angle) {
//        let left1 = Angle.degrees(CGFloat.random(in: (-8)...(-2)))
//        let right1 = Angle.degrees(CGFloat.random(in: 2...8))
//        let left2 = Angle.degrees(CGFloat.random(in: (-8)...(-2)))
//        let right2 = Angle.degrees(CGFloat.random(in: 2...8))
//        let leftFirst = Bool.random()
//        if leftFirst {
//            return (left1, right1, left2, right2)
//        } else {
//            return (right1, left1, right2, left2)
//        }
//    }
//
//    @MainActor
//    func collapse() async throws {
//        
//        guard !Task.isCancelled else { return }
//
//        withAnimation {
//            animatingCollapse = true
//            animatingCollapseOfCutouts = true
//            if let image, let scanResult {
//                imageHandler?(image, scanResult)
//                imageHandler = nil
//            }
//        }
//        
//        try await sleepTask(0.5, tolerance: 0.01)
//        
//        guard !Task.isCancelled else { return }
//        withAnimation {
//            self.animatingCollapseOfCroppedImages = true
//        }
//
//        try await sleepTask(0.2, tolerance: 0.01)
//
//        guard !Task.isCancelled else { return }
//        withAnimation {
//            //TODO: Handle this in LabelScanner with a local variable an an onChange modifier since it's a binding
//            clearSelectedImage = true
//            
//            if let scanResult {
//                if showingColumnPicker {
//                    scanResultHandler?(scanResult, columns.selectedColumnIndex)
//                } else {
//                    scanResultHandler?(scanResult, nil)
//                }
//                scanResultHandler = nil
//                dismissHandler?()
//            }
//        }
//    }
//    
//    func getZoomBox(for image: UIImage, animated: Bool) -> ZBox {
//        let boundingBox: CGRect
//        let imageSize: CGSize
//        if isCamera {
//            boundingBox = image.boundingBoxForScreenFill
//            imageSize = image.size
//        } else {
//            boundingBox = CGRect(x: 0, y: 0, width: 1, height: 1)
//            imageSize = UIScreen.main.bounds.size
//        }
//        
//        /// Having `padded` as true for picked images is crucial to make sure we don't get the bug
//        /// where the initial zoom causes the image to scroll way off screen (and hence disappear)
//        let padded = !isCamera
//        
//        return ZBox(
//            boundingBox: boundingBox,
//            animated: animated,
//            padded: padded,
//            imageSize: imageSize
//        )
//    }
//}
//
//extension LabelScannerViewModel {
//    
//    func testCaseDirectoryUrl(id: UUID) -> URL? {
//        guard let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
//            return nil
//        }
//        return documentsUrl.appending(component: id.uuidString)
//    }
//    
//    func writeTestData() {
//        guard createTestData else { return }
//        
//        writeTestDataTask = Task.detached { [weak self] in
//            guard !Task.isCancelled else { return }
//            guard
//                let self,
//                let image = await self.image,
//                let scanResult = await self.scanResult,
//                let directoryUrl = await self.testCaseDirectoryUrl(id: scanResult.id),
//                let textSet = await self.textSet
//            else { return }
//
//            do {
//                /// Create the folder with the `id`
//                try FileManager.default.createDirectory(at: directoryUrl, withIntermediateDirectories: false)
//                /// Save the image
//                guard !Task.isCancelled else { return }
////                let resized = resizeImage(image: image, targetSize: CGSize(width: 2048, height: 2048))
//                guard let imageData = image.heic else {
////                guard let imageData = image.pngData() else {
//                    cprint("💾🚧 Couldn't get imageData")
//                    return
//                }
//                
//                let imageUrl = directoryUrl.appending(component: "\(scanResult.id).heic")
//                guard !Task.isCancelled else { return }
//                try imageData.write(to: imageUrl)
//
//                guard !Task.isCancelled else { return }
//                let textSetData = try JSONEncoder().encode(textSet)
//
//                let textSetUrl = directoryUrl.appending(component: "\(scanResult.id)_textSet.json")
//                guard !Task.isCancelled else { return }
//                try textSetData.write(to: textSetUrl)
//                
//                let data = try JSONEncoder().encode(scanResult)
//                let url = directoryUrl.appending(component: "\(scanResult.id)_scanResult.json")
//                
//                guard !Task.isCancelled else { return }
//                try data.write(to: url)
//                cprint("💾 Wrote test data to: \(directoryUrl)")
//                
//            } catch {
//                cprint("💾🚧 Error in writeTestData: \(error)")
//            }
//        }
//    }
//    
//    
////    func writeScanResultToDiskIfNeeded() {
////        guard createTestData else { return }
////
////        writeScanResultTask = Task.detached { [weak self] in
////            guard !Task.isCancelled else { return }
////            guard
////                let self,
////                let scanResult = await self.scanResult,
////                let directoryUrl = await self.testCaseDirectoryUrl
////            else { return }
////
////            do {
////                guard !Task.isCancelled else { return }
////                let data = try JSONEncoder().encode(scanResult)
////                let url = directoryUrl.appending(component: "scanResult.json")
////
////                guard !Task.isCancelled else { return }
////                try data.write(to: url)
////                cprint("💾 Wrote scanResult.json")
////
////            } catch {
////                cprint("💾🚧 Error in writeScanResultToDiskIfNeeded: \(error)")
////            }
////        }
////    }
//}
//
//
//extension UIImage {
//    var heic: Data? { heic() }
//    func heic(compressionQuality: CGFloat = 1) -> Data? {
//        guard
//            let mutableData = CFDataCreateMutable(nil, 0),
//            let destination = CGImageDestinationCreateWithData(mutableData, "public.heic" as CFString, 1, nil),
//            let cgImage = cgImage
//        else { return nil }
//        CGImageDestinationAddImage(destination, cgImage, [kCGImageDestinationLossyCompressionQuality: compressionQuality, kCGImagePropertyOrientation: cgImageOrientation.rawValue] as CFDictionary)
//        guard CGImageDestinationFinalize(destination) else { return nil }
//        return mutableData as Data
//    }
//}
//
//extension CGImagePropertyOrientation {
//    init(_ uiOrientation: UIImage.Orientation) {
//        switch uiOrientation {
//            case .up: self = .up
//            case .upMirrored: self = .upMirrored
//            case .down: self = .down
//            case .downMirrored: self = .downMirrored
//            case .left: self = .left
//            case .leftMirrored: self = .leftMirrored
//            case .right: self = .right
//            case .rightMirrored: self = .rightMirrored
//        @unknown default:
//            fatalError()
//        }
//    }
//}
//
//extension UIImage {
//    var cgImageOrientation: CGImagePropertyOrientation { .init(imageOrientation) }
//}
