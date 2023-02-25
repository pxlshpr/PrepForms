//import SwiftUI
//import FoodLabelCamera
//import FoodLabelScanner
//import SwiftHaptics
//import ZoomableScrollView
//import SwiftSugar
//import Shimmer
//import VisionSugar
//
//extension CGRect {
//    /// Assuming this was a `boundingBox` (ie with the y coordinate starting from the bottom)
//    /// it gets converted to one with the y coordinate starting from the top.
////    var boundingRect: CGRect {
////
////    }
//}
//
//extension Array where Element == RecognizedText {
//    var topMostText: RecognizedText? {
//        sorted(by: { $0.boundingBox.minY < $1.boundingBox.minY }).first
//    }
//    
//    var bottomMostText: RecognizedText? {
//        sorted(by: { $0.boundingBox.maxY > $1.boundingBox.maxY }).first
//    }
//}
//
//extension LabelScannerViewModel {
//    
//    func zoomToColumns() async {
//        guard let imageSize = image?.size,
//              let boundingBox = scanResult?.nutrientsBoundingBox(includeAttributes: true)
//        else { return }
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
//    func showColumnPicker() async throws {
//        guard let scanResult else { return }
//
////        self.shimmering = false
////        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//        await MainActor.run { [weak self] in
//            self?.shimmering = false
//        }
////        }
//        
//        Haptics.feedback(style: .soft)
//        withAnimation {
//            showingColumnPicker = true
//            showingColumnPickerUI = true
//        }
//
//        columns = scanResult.scannedColumns
//        selectedImageTexts = columns.selectedImageTexts
//
//        cprint("🥑 selectedColumnIndex is \(columns.selectedColumnIndex)")
//        await zoomToColumns()
//        showColumnTextBoxes()
//        await showColumnPickingUI()
//    }
//
//    /// [ ] Show column boxes (animate changes, have default column preselected)
//    func showColumnTextBoxes() {
//        self.textBoxes = columns.texts.map {
//            TextBox(
//                boundingBox: $0.boundingBox,
//                color: color(for: $0),
//                tapHandler: tapHandler(for: $0)
//            )
//        }
//    }
//
//    func tapHandler(for text: RecognizedText) -> (() -> ())? {
//        let allowsTaps = !columns.selectedColumn.contains(text)
//        guard allowsTaps else { return nil }
//        
//        return { [weak self] in
//            guard let self else { return }
//            withAnimation(.interactiveSpring()) {
//                cprint("🥑 Before toggling \(self.columns.selectedColumnIndex)")
//                Haptics.feedback(style: .soft)
//                self.columns.toggleSelectedColumnIndex()
//                self.selectedImageTexts = self.columns.selectedImageTexts
//                cprint("🥑 AFTER toggling \(self.columns.selectedColumnIndex)")
//            }
//            self.showColumnTextBoxes()
//        }
//    }
//
//    func color(for text: RecognizedText) -> Color {
//        if selectedImageTexts.contains(where: { $0.text == text }) {
//            return Color.accentColor
//        } else {
//            return Color(.systemBackground).opacity(0.8)
////            return Color.white
//        }
//    }
//
//    /// [ ] Show column picking UI
//    func showColumnPickingUI() async {
//    }
//    
//    var selectedColumnBinding: Binding<Int> {
//        Binding<Int>(
//            get: { [weak self] in
//                guard let self else { return 0 }
//                return self.columns.selectedColumnIndex
//            },
//            set: { [weak self] newValue in
//                guard let self else { return }
//                cprint("Setting column to \(newValue)")
////                withAnimation {
//                    self.columns.selectedColumnIndex = newValue
//                    self.selectedImageTexts = self.columns.selectedImageTexts
////                }
//                self.showColumnTextBoxes()
//            }
//        )
//    }
//    
//    func columnSelectionHandler() {
//        Haptics.feedback(style: .soft)
//        withAnimation {
//            self.showingColumnPickerUI = false
//        }
//        
//        columnSelectionHandlerTask = Task.detached { [weak self] in
//            guard let self else { return }
//            guard !Task.isCancelled else { return }
//            await MainActor.run { [weak self] in
//                self?.waitingForZoomToEndToShowCroppedImages = true
//            }
//            
//            guard !Task.isCancelled else { return }
//            await self.zoomToTextsToCrop()
//
//            try await sleepTask(0.5, tolerance: 0.1)
//            await self.handleZoomEndINeeded()
//        }
//    }
//}
