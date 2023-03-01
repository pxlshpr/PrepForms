import SwiftUI

extension FoodForm {
    public class ViewModel: ObservableObject {
        public static let shared = ViewModel()

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

        public func reset(startWithCamera: Bool = false) {
            shouldShowWizard = !startWithCamera
            showingWizardOverlay = true
            showingWizard = true
            formDisabled = false
            didAppear = false
            
            self.startWithCamera = startWithCamera
            showingSaveButton = startWithCamera
            showingExtractorView = startWithCamera

            if startWithCamera {
                Task {
                    await Extractor.shared.setup(forCamera: true)
                }
            }
        }
    }
}
