import Foundation

enum ExtractorCaptureTransitionState {
    case notStarted
    case setup
    case startTransition
    case endTransition
    case tearDown
    
    var isTransitioning: Bool {
        switch self {
        case .setup, .startTransition, .endTransition:
            return true
        default:
            return false
        }
    }
    
    var showFullScreenImage: Bool {
        switch self {
        case .startTransition, .tearDown, .endTransition:
            return false
        default:
            return true
        }
    }
}
