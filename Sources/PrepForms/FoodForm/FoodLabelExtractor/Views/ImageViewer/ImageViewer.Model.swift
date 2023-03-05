import SwiftUI

public extension ImageViewer {
    class Model: ObservableObject {
        
        static let shared = Model()
        
//        var lastContentOffset: CGPoint? = nil
//        var lastZoomScale: CGFloat? = nil

        @Published var id: UUID
        @Published public var image: UIImage?
        
        /// Text boxes meant to be highlighted are placed here. Ideally with no tap handlers so that changes are animated (they'll move to the new positions)
        @Published public var textBoxes: [TextBox] = []
        
        /// Text boxes intended for users to select are placed here.
        @Published public var selectableTextBoxes: [TextBox] = []

        //TODO: Revisit these
        @Published public var zoomBox: ZoomBox? = nil
        @Published public var cutoutTextBoxes: [TextBox] = []
        @Published public var showingBoxes: Bool = false
        @Published public var showingCutouts: Bool = false
        @Published public var isShimmering: Bool = false
        @Published public var isFocused: Bool = true
        @Published public var textPickerHasAppeared: Bool = true

        public init(image: UIImage? = nil) {
            self.id = UUID()
            self.image = image
        }
    }
}

extension ImageViewer.Model {
    
    func reset() {
        self.id = UUID()
        self.image = nil
        self.textBoxes = []
        self.selectableTextBoxes = []
        self.zoomBox = nil
        self.cutoutTextBoxes = []
        self.showingBoxes = false
        self.showingCutouts = false
        self.isShimmering = false
        self.isFocused = true
        self.textPickerHasAppeared = true
    }
    
    var imageOverlayOpacity: CGFloat {
        (showingBoxes && isFocused) ? 0.7 : 1
    }
    
    var shouldShowTextBoxes: Bool {
        textPickerHasAppeared
        && showingBoxes
        && cutoutTextBoxes.isEmpty
    }
    
    var textBoxesOpacity: CGFloat {
        guard shouldShowTextBoxes else { return 0 }
        if isShimmering || isFocused { return 1 }
        return 0.3
    }
    
    var shouldShowCutoutTextBoxes: Bool {
        textPickerHasAppeared
        && showingBoxes
        && showingCutouts
    }
    
    var cutoutTextBoxesOpacity: CGFloat {
        shouldShowCutoutTextBoxes ? 1 : 0
    }
}
