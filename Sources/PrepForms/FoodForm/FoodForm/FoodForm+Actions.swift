import SwiftUI
import SwiftHaptics
import FoodLabelScanner
import PhotosUI
import VisionSugar
import MFPScraper
import PrepDataTypes

extension FoodForm {

    func appeared() {
        
        guard !model.didAppear else {
            return
        }
        
//        if model.startWithCamera {
//            showExtractorViewWithCamera()
//        }
        
        sources.didScanAllPickedImages = didScanAllPickedImages
        
        /// This used to ensure that the (conditional) display of the wizard is restricted
        /// to only the first invocation of this, as moving to the background and returning causes
        if model.shouldShowWizard {
            withAnimation(WizardAnimation) {
                model.formDisabled = true
                model.showingWizard = true
                model.shouldShowWizard = false
            }
        } else {
            model.showingWizard = false
            model.showingWizardOverlay = false
            model.formDisabled = false
        }
        
        if let existingFood {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                prefillExistingFood(existingFood)
            }
        }
        
        model.didAppear = true
    }
    
    func autoFillColumn(_ selectedColumn: Int, from scanResult: ScanResult?) {
        guard let scanResult else {
            /// We shouldn't come here without a `ScanResult`
            return
        }
        extract(column: selectedColumn, from: [scanResult], shouldOverwrite: true)
    }

    func prefill(_ food: MFPProcessedFood) {
        fields.prefill(food)
    }
    
    func handleScannedBarcodes(_ barcodes: [RecognizedBarcode], on image: UIImage) {
        let imageModel = ImageModel(barcodeImage: image, recognizedBarcodes: barcodes)
        var didAddABarcode = false
        for barcode in barcodes {
            let field = Field(fieldValue:
                    .barcode(FieldValue.BarcodeValue(
                        payloadString: barcode.string,
                        symbology: barcode.symbology,
                        fill: .barcodeScanned(
                            ScannedFillInfo(
                                recognizedBarcode: barcode,
                                imageId: imageModel.id)
                        )
                    ))
            )
            didAddABarcode = fields.add(barcodeField: field)
        }
        if didAddABarcode {
            sources.addImageModel(imageModel)
            sources.updateImageSetStatusToScanned()
        }
    }
    
    func handleTypedOutBarcode(_ payload: String) {
        let barcodeValue = FieldValue.BarcodeValue(payload: payload, fill: .userInput)
        let field = Field(fieldValue: .barcode(barcodeValue))
        withAnimation {
            let didAdd = fields.add(barcodeField: field)
            if didAdd {
                Haptics.successFeedback()
            } else {
                Haptics.errorFeedback()
            }
        }
    }
    
    func deleteBarcodes(at offsets: IndexSet) {
        let indices = Array(offsets)
        for i in indices {
            let field = fields.barcodes[i]
            guard let payload = field.barcodeValue?.payloadString else {
                continue
            }
            sources.removeBarcodePayload(payload)
        }
        fields.barcodes.remove(atOffsets: offsets)
    }

    func didDismissColumnPicker() {
        sources.removeUnprocessedImageModels()
    }
    
    func extract(column: Int, from results: [ScanResult], shouldOverwrite: Bool) {
    }
    
//    func handleSourcesAction(_ action: SourcesAction) {
//        switch action {
//        case .removeLink:
//            showingConfirmRemoveLinkMenu = true
//        case .addLink:
//            break
//        case .showPhotosMenu:
//            showingPhotosMenu = true
//        case .removeImage(index: let index):
//            resetFillForFieldsUsingImage(at: index)
//            sources.removeImage(at: index)
//        }
//    }
    
    /// Change all `.scanned` and `.selection` autofills that depend on this to `.userInput`
    //TODO: Move this to a Fields
    func resetFillForFieldsUsingImage(at index: Int) {
//        guard index < imageModels.count else {
//            return
//        }
//
//        let id = imageModels[index].id
//
//        /// Selectively reset fills for fields that are using this image
//        for fieldModel in allFieldModels {
//            fieldModel.registerDiscardScanIfUsingImage(withId: id)
//        }
//
//        /// Now remove the saved scanned field values that are also using this image
//        scannedFieldValues = scannedFieldValues.filter {
//            !$0.fill.usesImage(with: id)
//        }
    }

    func dismissWithHaptics() {
        Haptics.feedback(style: .soft)
        dismiss()
    }

    //MARK: - Wizard Actions
    func tappedWizardButton(_ button: WizardButton) {
        Haptics.feedback(style: .soft)
        switch button {
        case .dismiss:
            dismiss()
            return
        case .background, .startWithEmptyFood:
            break
        case .camera:
            showExtractorViewWithCamera()
        case .choosePhotos:
            showingPhotosPicker = true
        }
        
        dismissWizard()
    }
    
    func dismissWizard() {
        withAnimation(WizardAnimation) {
            model.showingWizard = false
        }
        withAnimation(.easeOut(duration: 0.1)) {
            model.showingWizardOverlay = false
        }
        model.formDisabled = false
    }
}

import PrepCoreDataStack

extension FoodForm {
    func prefillExistingFood(_ food: Food) {
        
        guard !didPrefillFoodFields else {
            return
        }
        
        Task.detached(priority: .background) {
            
            await MainActor.run {
                fields.fillWithExistingFood(food)
                fields.updateFormState()
                didPrefillFoodFields = true
            }
            
            Task.detached(priority: .background) {
                await self.prefillForm(foodId: food.id)
            }
        }
    }
    
    func prefillForm(foodId: UUID) async {
        
        guard let formData = await getFormData(foodId: foodId) else { return }
        let imageModels = await getImageModels(for: foodId, from: formData.images)
            
        await MainActor.run {
            prefill(with: formData, imageModels: imageModels)
        }
    }
    
    func getFormData(foodId: UUID) async -> FoodFormFieldsAndSources? {
        
        func getLocalData() throws -> Data? {
            do {
                let jsonUrl = try jsonUrl(for: foodId)
                return try Data(contentsOf: jsonUrl)
            } catch {
                return nil
            }
        }
        
        func getRemoteData() async throws -> Data {
            let baseUrl = "https://pxlshpr.app/prep/Uploads/jsons/"
            let urlString = "\(baseUrl)\(directoryPath(for: foodId.uuidString))/\(foodId.uuidString).json"
            let url = URL(string: urlString)!
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        }
        
        do {
            let data: Data
            let localData = try getLocalData()
            if let localData {
                data = localData
            } else {
                let remoteData = try await getRemoteData()
                data = remoteData
            }
            return try JSONDecoder().decode(
                FoodFormFieldsAndSources.self,
                from: data
            )
            
        } catch {
            print("Error getting FormData for \(foodId): \(error)")
            return nil
        }
    }
    
    func getImageModels(for foodId: UUID, from foodImages: [FoodImage]) async -> [ImageModel] {
        var imageModels: [ImageModel] = []
        do {
            for foodImage in foodImages {
                //TODO: try get them locally first
                let imageURL = imageURL(imageId: foodImage.id)
                let (data, _) = try await URLSession.shared.data(from: imageURL)
                guard let image = UIImage(data: data) else {
                    print("⬇️ Couldn't create image from data")
                    continue
                }
                print("⬇️ Got back an image of size: \(image.size)")
                
                if let scanResult = foodImage.scanResult {
                    imageModels.append(.init(
                        image: image,
                        scanResult: scanResult
                    ))
                } else {
                    imageModels.append(.init(
                        image: image,
                        id: foodImage.id
                    ))
                }
            }
        } catch {
            print("Error while getting imageModels for \(foodId): \(error)")
        }
        return imageModels
    }
    
    func prefill(with formData: FoodFormFieldsAndSources, imageModels: [ImageModel]) {
        sources.imageModels = imageModels
        //TODO: Do this first, and only do the local copy if we don't get the json data successfully
        
        /// Now set the Fills and crop the images
        fields.amount = .init(fieldValue: formData.amount)
        if let serving = formData.serving {
            fields.serving = .init(fieldValue: serving)
        }
        fields.energy = .init(fieldValue: formData.energy)
        fields.carb = .init(fieldValue: formData.carb)
        fields.fat = .init(fieldValue: formData.fat)
        fields.protein = .init(fieldValue: formData.protein)
        if let density = formData.density {
            fields.density = .init(fieldValue: density)
        }
        
        let sizeFields = formData.sizes.map { Field(fieldValue: $0) }
        fields.standardSizes = sizeFields.filter { !$0.isVolumePrefixedSize }
        fields.volumePrefixedSizes = sizeFields.filter { $0.isVolumePrefixedSize }
        
        fields.barcodes = formData.barcodes.map { Field(fieldValue: $0) }
        
        let microFields = formData.micronutrients.map { Field(fieldValue: $0) }
        fields.microsFats = microFields.filter({ $0.nutrientType?.group == .fats })
        fields.microsFibers = microFields.filter({ $0.nutrientType?.group == .fibers })
        fields.microsSugars = microFields.filter({ $0.nutrientType?.group == .sugars })
        fields.microsMinerals = microFields.filter({ $0.nutrientType?.group == .minerals })
        fields.microsVitamins = microFields.filter({ $0.nutrientType?.group == .vitamins })
        fields.microsMisc = microFields.filter({ $0.nutrientType?.group == .misc })
        

        fields.amount.resetAndCropImage()
        fields.energy.resetAndCropImage()
        fields.carb.resetAndCropImage()
        fields.fat.resetAndCropImage()
        fields.protein.resetAndCropImage()
        fields.serving.resetAndCropImage()
        fields.density.resetAndCropImage()
        fields.standardSizes.forEach { $0.resetAndCropImage() }
        fields.volumePrefixedSizes.forEach { $0.resetAndCropImage() }
        fields.barcodes.forEach { $0.resetAndCropImage() }
        fields.microsFats.forEach { $0.resetAndCropImage() }
        fields.microsFibers.forEach { $0.resetAndCropImage() }
        fields.microsSugars.forEach { $0.resetAndCropImage() }
        fields.microsMinerals.forEach { $0.resetAndCropImage() }
        fields.microsVitamins.forEach { $0.resetAndCropImage() }
        fields.microsMisc.forEach { $0.resetAndCropImage() }
        
        if let link = formData.link {
            sources.linkInfo = .init(link)
        }
        
        //TODO: Handle should publish
        
        withAnimation {
            didPrefillFoodSources = true
        }
    }
}

func jsonURL(foodId: UUID) -> URL {
    let string = "https://pxlshpr.app/prep/Uploads/json/\(directoryPath(for: foodId.uuidString))/\(foodId.uuidString).json"
    return URL(string: string)!
}

func imageURL(imageId: UUID) -> URL {
    let string = "https://pxlshpr.app/prep/Uploads/images/\(directoryPath(for: imageId.uuidString))/\(imageId.uuidString).jpg"
    return URL(string: string)!
}

func directoryPath(for id: String) -> String {
    let suffix = id.suffix(6)
    guard suffix.count == 6 else { return "" }
    let folder1 = suffix.prefix(3)
    let folder2 = suffix.suffix(3)
    return "\(folder1)/\(folder2)"
}
