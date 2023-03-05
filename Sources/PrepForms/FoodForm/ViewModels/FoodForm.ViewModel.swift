import SwiftUI

extension FoodForm {
    public class Model: ObservableObject {
        public static let shared = Model()

        @Published var shouldShowWizard: Bool = true
        @Published var showingWizardOverlay: Bool  = true
        @Published var showingWizard: Bool  = true
        @Published var formDisabled = false

        @Published var showingSaveButton: Bool = false
        @Published var showingExtractorView: Bool = false
    //        @Published var showingLabelScanner: Bool = false
    //        @Published var animateLabelScannerUp: Bool = false

        var didAppear = false
        var startWithCamera = false

        public func reset(startWithCamera: Bool = false, isEditing: Bool = false) {
            didAppear = false
            
            if isEditing {
                shouldShowWizard = false
                showingWizardOverlay = false
                showingWizard = false
            } else {
                shouldShowWizard = !startWithCamera
                showingWizardOverlay = true
                showingWizard = true
            }
            formDisabled = false

            self.startWithCamera = startWithCamera
            showingSaveButton = startWithCamera
            showingExtractorView = startWithCamera
            ImageViewer.Model.shared.reset()

            if startWithCamera {
                Task {
                    await Extractor.shared.setup(forCamera: true)
                }
            }
        }
    }
}
