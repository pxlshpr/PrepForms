import Foundation

enum PresentationState {
    case offScreen
    case onScreen
}

enum DismissTransitionState {
    
    case notStarted
    case startedDoneDismissal
    case waitingForCroppedImages
    
    case showCroppedImages
    case firstWiggle
    case secondWiggle
    case thirdWiggle
    case fourthWiggle
    case liftingUp
    case stackedOnTop
    
    case shrinkingImage
    case shrinkingCroppedImages

    var shouldShrinkImage: Bool {
        switch self {
        case .shrinkingImage, .shrinkingCroppedImages:
            return true
        default:
            return false
        }
    }
    
    var shouldStackCropImages: Bool {
        switch self {
        case .stackedOnTop, .shrinkingImage, .shrinkingCroppedImages:
            return true
        default:
            return false
        }
    }
    
    var shouldShowCroppedImages: Bool {
        switch self {
        case .notStarted, .waitingForCroppedImages:
            return false
        default:
            return true
        }
    }
    
    var shouldHideUI: Bool {
        switch self {
        case .notStarted:
            return false
        default:
            return true
        }
    }
}
