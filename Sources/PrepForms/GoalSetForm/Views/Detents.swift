import SwiftUI
import SwiftHaptics

enum TDEEFormDetentHeight {
    case empty
    case expanded
    case expanded2
    case collapsed
}

func resetTDEEFormDetents() {
    detentHeightPrimary = .collapsed
    detentHeightSecondary = .collapsed
}

var detentHeightPrimary: TDEEFormDetentHeight = .empty
var detentHeightSecondary: TDEEFormDetentHeight = .empty

struct PrimaryDetent: CustomPresentationDetent {
    static func height(in context: Context) -> CGFloat? {
        switch detentHeightPrimary {
        case .empty:
            return 270
        case .collapsed:
            return context.maxDetentValue * 0.5
        case .expanded:
            return context.maxDetentValue
        case .expanded2:
            return context.maxDetentValue * 0.99999
        }
    }
}

struct SecondaryDetent: CustomPresentationDetent {
    static func height(in context: Context) -> CGFloat? {
        switch detentHeightSecondary {
        case .empty:
            return 270
        case .collapsed:
            return context.maxDetentValue * 0.5
        case .expanded:
            return context.maxDetentValue
        case .expanded2:
            return context.maxDetentValue * 0.99999
        }
    }
}

extension TDEEForm {
    func transitionToEditState() {
        Haptics.successFeedback()
        withAnimation {
            model.isEditing = true
            model.presentationDetent = .large
        }
    }
}

//MARK: - Experimental Legacy Detent Transitions

extension TDEEForm {
    func toggleEditState_experimental_legacy() {
        if model.isEditing {
            transitionToCollapsedState_experimental_legacy()
        } else {
            transitionToEditState_experimental_legacy()
        }
    }


    func transitionToCollapsedState_experimental_legacy() {
        Haptics.successFeedback()
        
        model.detents = [.custom(PrimaryDetent.self), .custom(SecondaryDetent.self)]
        
        let onPrimaryDetent = model.presentationDetent == .custom(PrimaryDetent.self)
        /// We could be on either detent here (expanded or expanded2—which the differences between aren't noticeable)
        if onPrimaryDetent {
            detentHeightSecondary = model.shouldShowSummary ? .collapsed : .empty
        } else {
            detentHeightPrimary = model.shouldShowSummary ? .collapsed : .empty
        }
        withAnimation {
            model.isEditing = false
            
            /// Always go to the opposite one
            if onPrimaryDetent {
                model.presentationDetent = .custom(SecondaryDetent.self)
            } else {
                model.presentationDetent = .custom(PrimaryDetent.self)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if onPrimaryDetent {
                detentHeightSecondary = model.shouldShowSummary ? .collapsed : .empty
                model.detents = [.custom(SecondaryDetent.self)]
            } else {
                detentHeightPrimary = model.shouldShowSummary ? .collapsed : .empty
                model.detents = [.custom(PrimaryDetent.self)]
            }
        }
    }
    
    func transitionToEditState_experimental_legacy() {
        Haptics.feedback(style: .rigid)

        model.detents = [.custom(PrimaryDetent.self), .custom(SecondaryDetent.self)]
        
        let onSecondaryDetent = model.presentationDetent == .custom(SecondaryDetent.self)
        if onSecondaryDetent {
            detentHeightPrimary = .expanded
        } else {
            detentHeightSecondary = .expanded
        }
        withAnimation {
            model.isEditing = true
            if onSecondaryDetent {
                model.presentationDetent = .custom(PrimaryDetent.self)
            } else {
                model.presentationDetent = .custom(SecondaryDetent.self)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if onSecondaryDetent {
                detentHeightSecondary = .expanded2
                model.detents = [.custom(PrimaryDetent.self)]
            } else {
                detentHeightPrimary = .expanded2
                model.detents = [.custom(SecondaryDetent.self)]
            }
        }
    }
}
