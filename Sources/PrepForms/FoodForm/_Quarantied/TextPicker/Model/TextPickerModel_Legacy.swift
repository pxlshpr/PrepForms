//import SwiftUI
//import ZoomableScrollView
//import SwiftUIPager
//
//class TextPickerModel: ObservableObject {
//    
//    @Published var showingMenu = false
//    @Published var showingAutoFillConfirmation = false
//    @Published var imageModels: [ImageModel]
//    @Published var showingBoxes: Bool
//    @Published var selectedImageTexts: [ImageText]
//    @Published var zoomBoxes: [ZBox?]
//    @Published var page: Page
//    
//    @Published var currentIndex: Int = 0
//    @Published var hasAppeared: Bool = false
//    @Published var shouldDismiss: Bool = false
//    
//    let initialImageIndex: Int
//    @Published var mode: TextPickerMode
//    @Published var selectedColumn: Int
//    
//    init(imageModels: [ImageModel], mode: TextPickerMode){
//        self.imageModels = imageModels
//        self.mode = mode
//        self.selectedImageTexts = mode.selectedImageTexts
//        showingBoxes = true /// !mode.isImageViewer
//        zoomBoxes = Array(repeating: nil, count: imageModels.count)
//        
//        initialImageIndex = mode.initialImageIndex(from: imageModels)
//        page = .withIndex(initialImageIndex)
//        currentIndex = initialImageIndex
//        selectedColumn = mode.selectedColumnIndex ?? 1
//    }
//}
