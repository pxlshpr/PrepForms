import Foundation

enum ExtractorState: String {
    case loadingImage
    case detecting
    case classifying
    case awaitingColumnSelection
    case awaitingConfirmation
    case allConfirmed
    case showingKeyboard
    case dismissing
    
    var shouldShowTextBoxes: Bool {
        switch self {
        case .classifying, .awaitingColumnSelection, .awaitingConfirmation, .allConfirmed, .showingKeyboard:
            return true
        default:
            return false
        }
    }
    
    var isLoading: Bool {
        switch self {
        case .loadingImage, .detecting, .classifying:
            return true
        default:
            return false
        }
    }
    
    var loadingDescription: String? {
        switch self {
        case .loadingImage:
            return "Loading Image"
        case .detecting:
            return "Detecting Texts"
        case .classifying:
            return "Classifying Texts"
        default:
            return nil
        }
    }
    
    var showsDivider: Bool {
        switch self {
        case .awaitingConfirmation, .allConfirmed:
            return true
        default:
            return false
        }
    }
    
    var showsEditButton: Bool {
        switch self {
        case .awaitingConfirmation, .allConfirmed:
            return true
        default:
            return false
        }
    }
}
