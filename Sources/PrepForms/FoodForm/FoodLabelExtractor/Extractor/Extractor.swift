import SwiftUI
import VisionSugar
import FoodLabelScanner
import PrepDataTypes
import SwiftHaptics

@MainActor
public class Extractor: ObservableObject {

    static let shared = Extractor()
    
    var isUsingCamera: Bool
    var attributesToIgnore: [Attribute] = []

    @Published var state: ExtractorState = .loadingImage
    @Published var transitionState: ExtractorCaptureTransitionState = .notStarted
    @Published var dismissState: DismissTransitionState = .notStarted
    @Published var presentationState: PresentationState = .offScreen
    var croppingStatus: CroppingStatus = .idle

    var lastContentOffset: CGPoint? = nil
    var lastContentSize: CGSize? = nil
    var lastZoomScale: CGFloat? = nil

    var allCroppedImages: [RecognizedText : UIImage] = [:]
    @Published var croppedImages: [(UIImage, CGRect, UUID, Angle, (Angle, Angle, Angle, Angle))] = []

    @Published public var image: UIImage? = nil
    /// Lower-res image for cropping to imrove perf
    var resizedImageForCropping: UIImage?

    @Published var textSet: RecognizedTextSet? = nil
    
    @Published var textBoxes: [TextBox] = []
    @Published var selectableTextBoxes: [TextBox] = []
    @Published var cutoutTextBoxes: [TextBox] = []

    @Published var scanResult: ScanResult? = nil
    @Published var extractedNutrients: [ExtractedNutrient] = [] {
        didSet {
            /// Filter out case where we reset the extractor for reuse
            /// (otherwise this sets the extractor state incorrectly to `.allConfirmed`)
            guard !extractedNutrients.isEmpty else { return }
            
            /// If we've deleted a nutrient
            if oldValue.count > extractedNutrients.count {
                handleDeletedNutrient(oldValue: oldValue)
            }
        }
    }

//    @Published var showingBoxes = false
    @Published var showingCamera = false
    @Published var showingBackground: Bool = true
    @Published var extractedColumns: ExtractedColumns = ExtractedColumns()

    @Published var currentAttribute: Attribute? = nil {
        didSet {
            pickedAttributeUnit = currentUnit
            textFieldAmountString = currentAmountString
        }
    }
    @Published var pickedAttributeUnit: FoodLabelUnit = .g {
        didSet {
            if currentNutrientIsConfirmed, pickedAttributeUnit != currentNutrient?.value?.unit {
                toggleAttributeConfirmationForCurrentAttribute()
            }
            currentNutrient?.value?.unit = pickedAttributeUnit
        }
    }
    
    @Published var internalTextfieldDouble: Double? = nil {
        didSet {
            if currentNutrientIsConfirmed, internalTextfieldDouble != currentNutrient?.value?.amount {
                toggleAttributeConfirmationForCurrentAttribute()
            }
            removeTextForCurrentAttributeIfDifferentValue()

            if let internalTextfieldDouble {
                currentNutrient?.value?.amount = internalTextfieldDouble
            } else {
                currentNutrient?.value = nil
            }
        }
    }
    @Published var internalTextfieldString: String = ""

//    var didDismiss: ((ExtractorOutput?) -> Void)? = nil
    
    /// This flag is used to keep the association with the value's `RecognizedText` when its changed
    /// by tapping a suggestion.
    var ignoreNextValueChange: Bool = false
    
    //MARK: Tasks
    var scanTask: Task<(), Error>? = nil
    var classifyTask: Task<(), Error>? = nil
    var cropTask: Task<(), Error>? = nil
    var cropTappedTextTask: Task<(), Error>? = nil
    var showCroppedImagesTask: Task<(), Error>? = nil
    var stackingCroppedImagesOnTopTask: Task<(), Error>? = nil

    //MARK: Init
    public init(isUsingCamera: Bool = false) {
        self.isUsingCamera = isUsingCamera
        
        NotificationCenter.default.addObserver(self,
            selector: #selector(imageViewerViewportChanged),
            name: .zoomScrollViewViewportChanged,
            object: nil
        )
    }
}

extension Extractor {
    public func setup(
        forCamera: Bool = false,
        attributesToIgnore: [Attribute] = []
//        didDismiss: @escaping ((ExtractorOutput?) -> Void)
    ) {
        ImageViewer.Model.shared.reset()
        isUsingCamera = forCamera
        self.attributesToIgnore = attributesToIgnore

        state = .loadingImage
        transitionState = .notStarted
        dismissState = .notStarted
        presentationState = .offScreen
        croppingStatus = .idle
        
        lastContentOffset = nil
        lastContentSize = nil
        lastZoomScale = nil
        
        allCroppedImages = [:]
        croppedImages = []

        image = nil
        
        textSet = nil

        textBoxes = []
        selectableTextBoxes = []
        cutoutTextBoxes = []

        scanResult = nil
        
        extractedNutrients = []

        showingCamera = forCamera
        showingBackground = true
        extractedColumns = ExtractedColumns()
        
        currentAttribute = nil
        pickedAttributeUnit = .g
        internalTextfieldDouble = nil
        internalTextfieldString = ""
        
//        self.didDismiss = didDismiss

        ignoreNextValueChange = false
        
        cancelAllTasks()
        scanTask = nil
        classifyTask = nil
        cropTask = nil
        cropTappedTextTask = nil
        showCroppedImagesTask = nil
        stackingCroppedImagesOnTopTask = nil
    }
    
    public func cancelAllTasks() {
        scanTask?.cancel()
        classifyTask?.cancel()
        cropTask?.cancel()
        cropTappedTextTask?.cancel()
        showCroppedImagesTask?.cancel()
        stackingCroppedImagesOnTopTask?.cancel()
    }
}

extension Extractor {
    func begin() {
        self.detectTexts()
    }
}

extension Extractor {
    
    @objc func imageViewerViewportChanged(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let contentOffset = userInfo[Notification.ZoomableScrollViewKeys.contentOffset] as? CGPoint,
              let contentSize = userInfo[Notification.ZoomableScrollViewKeys.contentSize] as? CGSize,
              let zoomScale = userInfo[Notification.ZoomableScrollViewKeys.zoomScale] as? CGFloat
        else { return }
        
        lastContentOffset = contentOffset
        lastContentSize = contentSize
        lastZoomScale = zoomScale
    }

    func setSuggestedValue(_ value: FoodLabelValue) {
        ignoreNextValueChange = true
        textFieldAmountString = value.amount.cleanWithoutRounding
    }
    
    func removeConfirmationStatusForCurrentAttribute() {
        guard currentNutrientIsConfirmed,
              internalTextfieldDouble != currentNutrient?.value?.amount
        else { return }
        
        toggleAttributeConfirmationForCurrentAttribute()
    }
    
    func removeTextForCurrentAttributeIfDifferentValue() {
        guard !ignoreNextValueChange else {
            ignoreNextValueChange = false
            return
        }
        
        guard internalTextfieldDouble != currentNutrient?.value?.amount else {
            return
        }
        withAnimation {
            currentNutrient?.valueText = nil
            showTextBoxesForCurrentAttribute()
        }
    }
    
    func removeTextForCurrentAttributeIfDifferentUnit() {
        guard pickedAttributeUnit != currentNutrient?.value?.unit else {
            return
        }
        withAnimation {
            currentNutrient?.valueText = nil
            showTextBoxesForCurrentAttribute()
        }
    }

    func handleDeletedNutrient(oldValue: [ExtractedNutrient]) {
        
        Haptics.warningFeedback()
        /// get the index of the deleted attribute
        var deletedIndex: Int? = nil
        for index in oldValue.indices {
            if !extractedNutrients.contains(where: { $0.attribute == oldValue[index].attribute }) {
                deletedIndex = index
            }
        }
        guard let deletedIndex else { return }

        let shouldUnsetCurrentAttributeUponCompletion: Bool
        if self.currentAttribute == oldValue[deletedIndex].attribute {
            self.currentAttribute = nil
            shouldUnsetCurrentAttributeUponCompletion = true
        } else {
            shouldUnsetCurrentAttributeUponCompletion = false
        }
        checkIfAllNutrientsAreConfirmed(unsettingCurrentAttribute: shouldUnsetCurrentAttributeUponCompletion)
    }
}
