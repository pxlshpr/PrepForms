import SwiftUI
import SwiftSugar
import SwiftHaptics
import FoodLabelScanner
import VisionSugar
import PrepDataTypes

extension Extractor {

    func handleCapturedImage(_ image: UIImage) {
        self.image = image
        
        /// Place the image where we last saw it in the camera view finder
        withAnimation(.interactiveSpring()) {
            transitionState = .setup
            showingCamera = false
        }

        /// Now animate it downwards to where it will bein the extractor
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//            withAnimation(.easeInOut(duration: 0.7)) {
            withAnimation {
                self.transitionState = .startTransition
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.transitionState = .endTransition
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//                    withAnimation {
                        self.transitionState = .tearDown
//                    }
                }
            }
        }
    }

    
    func detectTexts() {
        guard let image else { return }
        setState(to: .detecting)

        scanTask = Task.detached(priority: .high) { [weak self] in
            
            guard let self else { return }
            
            Haptics.selectionFeedback()
            
            guard !Task.isCancelled else { return }
            //TODO: Bring back camera
//            if await self.isCamera {
//                await MainActor.run { [weak self] in
//                    withAnimation {
//                        self?.hideCamera = true
//                    }
//                }
//            } else {
                /// Ensure the sliding up animation is complete first
                try await sleepTask(K.Pipeline.appearanceTransitionDelay, tolerance: K.Pipeline.tolerance)
//            }
            
            /// Now capture recognized texts
            /// - captures all the RecognizedTexts
            guard !Task.isCancelled else { return }
            let textSet = try await image.recognizedTextSet(for: .accurate, includeBarcodes: true)
            await MainActor.run { [weak self] in
                withAnimation {
                    self?.textSet = textSet
                }
            }
            
            guard !Task.isCancelled else { return }
            let textBoxes = await self.textBoxesForAllRecognizedTexts
            
            Haptics.selectionFeedback()

            guard !Task.isCancelled else { return }
            await MainActor.run {  [weak self] in
                guard let self else { return }
                self.setState(to: .classifying)
                withAnimation {
                    self.textBoxes = textBoxes
                }
            }

            /// Ensure the shimmer effect displays for a minimum duration
            try await sleepTask(K.Pipeline.minimumClassifySeconds, tolerance: K.Pipeline.tolerance)
            
            guard !Task.isCancelled else { return }
            
            try await self.classify()
        }
    }
    
    func classify() async throws {
        
        guard let textSet else { return }

        classifyTask = Task.detached(priority: .high) { [weak self] in
            guard let self else { return }
            let scanResult = textSet.scanResult

            guard !Task.isCancelled else { return }
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.scanResult = scanResult
//                self.showingBlackBackground = false
            }
            
            guard !Task.isCancelled else { return }

            cprint("✂️ About to call cropTextBoxes()")
            //TODO: Performance improvements
            /// [ ] ~~Do this after the column is picked or if there's 1 column, straight away~~
            /// [ ] ~~Only cut out the text boxes we will be using (not everything)~~
            /// [ ] ~~As user interacts with extractor~~
            ///     [ ] ~~Add any more cropped images that user selects if it doesn't already exist (don't remove any in case they select them again)~~
//            await self.cropTextBoxes()
            cprint("✂️ Returned from cropTextBoxes()")

            if scanResult.columnCount == 2 {
                try await self.showColumnPicker()
            } else {
                try await self.extractNutrients()
            }
        }
    }

    func extractNutrients() async throws {
        guard let scanResult else { return }
        let extractedNutrients = scanResult.extractedNutrientsForColumn(
            extractedColumns.selectedColumnIndex,
            includeSingleColumnValues: true,
            ignoring: attributesToIgnore
        )

//        guard let firstAttribute = extractedNutrients.first?.attribute else {
        guard let _ = extractedNutrients.first?.attribute else {
            //TODO: Handle no attributes being read
            return
        }
        
        Haptics.feedback(style: .soft)
        setState(to: .awaitingConfirmation)

        withAnimation {
            self.extractedNutrients = extractedNutrients
        }
        cropTextBoxes()
        
//        currentAttribute = firstAttribute
        selectableTextBoxes = []
        textBoxes = []
        showTextBoxesForCurrentAttribute()

        
        await zoomToNutrients()
    }
    
    func showColumnPicker() async throws {
        guard let scanResult else { return }

        setState(to: .awaitingColumnSelection)

        Haptics.feedback(style: .soft)
//        withAnimation {
//            showingColumnPicker = true
//            showingColumnPickerUI = true
//        }

        extractedColumns = scanResult.extractedColumns(ignoring: attributesToIgnore)
        showColumnTextBoxes()
//        selectedImageTexts = columns.selectedImageTexts

        await zoomToNutrients()
    }
    
    func cropTextBoxes() {
        guard let image else { return }

        cropTask = Task.detached(priority: .medium) { [weak self] in
            guard let self else { return }
            
            guard !Task.isCancelled else { return }
            await MainActor.run { [weak self] in
                self?.croppingStatus = .started
            }
            
//            try await sleepTask(0.5, tolerance: 0.01)

            var start = CFAbsoluteTimeGetCurrent()
            
            let allTexts = await self.allTexts
            let textsToCrop = await self.textsToCrop
            cprint("✂️ Cropping \(allTexts.count) texts when we only need \(textsToCrop.count)")
            
            let sizeForCropping = await self.sizeForCropping(
                for: textsToCrop,
                in: image.size
            )
            
            cprint("✂️ Resizing image: \(image.size)")
            if let sizeForCropping {
                await MainActor.run { [weak self] in
                    self?.resizedImageForCropping = resizeImage(image: image, targetSize: sizeForCropping)
                }
            }
            let imageForCropping = await self.resizedImageForCropping ?? image
            
            cprint("✂️ Resizing took \(CFAbsoluteTimeGetCurrent()-start)s")
            start = CFAbsoluteTimeGetCurrent()
            
            cprint("✂️ Starting cropping image of size: \(imageForCropping.size)")
            
            var croppedImages: [RecognizedText : UIImage] = [:]
            for text in textsToCrop {
                guard !Task.isCancelled else { return }
                guard let croppedImage = await imageForCropping.cropped(
                    boundingBox: text.boundingBox
                ) else {
                    cprint("Couldn't get image for box: \(text)")
                    continue
                }
                cprint("✂️ Cropped: \(text.string) size: \(croppedImage.size)")
                croppedImages[text] = croppedImage
            }

            let duration = CFAbsoluteTimeGetCurrent()-start
            guard !Task.isCancelled else { return }
            await MainActor.run { [weak self, croppedImages] in
                cprint("✂️ Cropping completed in \(duration)s, setting dict and status")
                self?.allCroppedImages = croppedImages
                self?.croppingStatus = .complete
            }
            
            if await self.dismissState == .waitingForCroppedImages {
                cprint("✂️ Was waitingToShowCroppedImages, so showing now")
                await self.showCroppedImages()
            }
        }
    }
    
    func addCroppedImage(for text: RecognizedText) {
        guard let image = self.resizedImageForCropping ?? self.image else { return }
        
        cropTask = Task.detached(priority: .low) { [weak self] in
            let start = CFAbsoluteTimeGetCurrent()
            cprint("✂️ Starting cropping image of size: \(image.size)")
            guard let croppedImage = await image.cropped(boundingBox: text.boundingBox) else {
                cprint("Couldn't get image for box: \(text)")
                return
            }
            await MainActor.run { [weak self] in
                self?.allCroppedImages[text] = croppedImage
            }
            cprint("✂️ Cropped: \(text.string) size: \(croppedImage.size), took: \(CFAbsoluteTimeGetCurrent()-start)s")
        }
    }
    
    func tappedDone() {
        withAnimation {
            dismissState = .startedDoneDismissal
        }
//        extractor.startCollapseTask()
        /// If the cropped images are available, start with the transition, otherwise set the state to wait for them to finish
        if croppingStatus == .complete {
            showCroppedImages()
        } else {
            dismissState = .waitingForCroppedImages
        }
    }
    
    func showCroppedImages() {
        showCroppedImagesTask = Task.detached(priority: .high) { [weak self] in

            let start = CFAbsoluteTimeGetCurrent()
            cprint("✂️ Showing cropped images")

            guard let self else { return }
            guard !Task.isCancelled else { return }

            var localCroppedImages: [(UIImage, CGRect, UUID, Angle, (Angle, Angle, Angle, Angle))] = []
            
            for (text, cropped) in await self.allCroppedImages {
                guard !Task.isCancelled else { return }
                guard await self.textsToCrop.contains(where: { $0.id == text.id }) else {
                    cprint("✂️ Not including: \(text.string) since it's not in textsToCrop")
                    continue
                }
                
                cprint("✂️ Getting rect for: \(text.string), timestamp: \(CFAbsoluteTimeGetCurrent()-start)s")
                let correctedRect = await self.rectForText(text)
                cprint("✂️ ... got rect, timestamp: \(CFAbsoluteTimeGetCurrent()-start)s")

                let randomWiggleAngles = await self.randomWiggleAngles
                
                if !localCroppedImages.contains(where: { $0.2 == text.id }) {
                    localCroppedImages.append((
                        cropped,
                        correctedRect,
                        text.id,
                        Angle.degrees(CGFloat.random(in: -20...20)),
                        randomWiggleAngles
                    ))
                }

//                await MainActor.run { [weak self] in
//                    guard let self else { return }
//                    cprint("✂️ ... appending image to croppedImages, timestamp: \(CFAbsoluteTimeGetCurrent()-start)s")
//                    let randomWiggleAngles = self.randomWiggleAngles
//
//                    if !self.croppedImages.contains(where: { $0.2 == text.id }) {
//                        self.croppedImages.append((
//                            cropped,
//                            correctedRect,
//                            text.id,
//                            Angle.degrees(CGFloat.random(in: -20...20)),
//                            randomWiggleAngles
//                        ))
//                    }
//                    cprint("✂️ ... appended image to croppedImages, timestamp: \(CFAbsoluteTimeGetCurrent()-start)s")
//                }
            }
            
            await MainActor.run { [weak self, localCroppedImages] in
                guard let self else { return }
                cprint("✂️ ... setting croppedImages, timestamp: \(CFAbsoluteTimeGetCurrent()-start)s")
                
                withAnimation {
                    self.croppedImages = localCroppedImages
                }
                
                cprint("✂️ ... set croppedImages, timestamp: \(CFAbsoluteTimeGetCurrent()-start)s")
            }

            try await sleepTask(1.0, tolerance: 0.01)

            guard !Task.isCancelled else { return }
            Haptics.selectionFeedback()
            
            guard !Task.isCancelled else { return }
            await MainActor.run { [weak self] in
                guard let self else { return }
                withAnimation {
                    self.textBoxes = []
                    self.dismissState = .showCroppedImages
                    self.cutoutTextBoxes = self.getCutoutTextBoxes
                }
            }
            
            try await sleepTask(0.1, tolerance: 0.01)

            guard !Task.isCancelled else { return }
            
            cprint("✂️ Completed showCroppedImage, took: \(CFAbsoluteTimeGetCurrent()-start)s")
            await self.stackCroppedImagesOnTop()
        }
    }
    
    func stackCroppedImagesOnTop() {
        stackingCroppedImagesOnTopTask = Task.detached(priority: .high) { [weak self] in
            
            guard let self else { return }
            guard !Task.isCancelled else { return }

            await MainActor.run { [weak self] in
                guard let self else { return }
                withAnimation {
//                    self.showingCutouts = true
                    self.dismissState = .liftingUp
                }
            }
            
            let Bounce: Animation = .interactiveSpring(response: 0.35, dampingFraction: 0.66, blendDuration: 0.35)

            try await sleepTask(Double.random(in: 0.05...0.15), tolerance: 0.01)

            guard !Task.isCancelled else { return }
            await MainActor.run { [weak self] in
                guard let self else { return }
                Haptics.selectionFeedback()
                withAnimation(Bounce) {
                    self.dismissState = .firstWiggle
                }
            }

            try await sleepTask(Double.random(in: 0.05...0.15), tolerance: 0.01)

            guard !Task.isCancelled else { return }
            await MainActor.run { [weak self] in
                guard let self else { return }
                Haptics.selectionFeedback()
                withAnimation(Bounce) {
                    self.dismissState = .secondWiggle
                }
            }

            try await sleepTask(Double.random(in: 0.05...0.15), tolerance: 0.01)

            guard !Task.isCancelled else { return }
            await MainActor.run { [weak self] in
                guard let self else { return }
                Haptics.selectionFeedback()
                withAnimation(Bounce) {
                    self.dismissState = .thirdWiggle
                }
            }

            try await sleepTask(Double.random(in: 0.05...0.15), tolerance: 0.01)

            guard !Task.isCancelled else { return }
            await MainActor.run { [weak self] in
                guard let self else { return }
                Haptics.selectionFeedback()
                withAnimation(Bounce) {
                    self.dismissState = .fourthWiggle
                }
            }

            try await sleepTask(Double.random(in: 0.3...0.5), tolerance: 0.01)

            guard !Task.isCancelled else { return }
            await MainActor.run { [weak self] in
                guard let self else { return }
                Haptics.feedback(style: .soft)
                withAnimation(Bounce) {
                    self.dismissState = .stackedOnTop
                }
            }

            try await sleepTask(0.8, tolerance: 0.01)

            guard !Task.isCancelled else { return }
            try await self.collapse()
        }
    }
    
    func startCollapseTask() {
        //TODO: Rename this task
        showCroppedImagesTask = Task.detached(priority: .high) { [weak self] in
            guard !Task.isCancelled else { return }
            try await self?.collapse()
        }
    }
    
    @MainActor
    func collapse() async throws {
        
        //TODO: Simply slide down the image and the Nutrition Label filled and ready
        
        guard !Task.isCancelled else { return }

        withAnimation {
            dismissState = .shrinkingImage
        }

        try await sleepTask(0.2, tolerance: 0.01)

        guard !Task.isCancelled else { return }
        withAnimation {
            dismissState = .shrinkingCroppedImages
        }

        try await sleepTask(0.4, tolerance: 0.01)

        guard !Task.isCancelled else { return }
        guard let extractorOutput else {
            didDismiss?(nil)
            return
        }
        didDismiss?(extractorOutput)
    }
}
