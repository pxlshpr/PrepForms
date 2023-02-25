import SwiftUI

struct K {

    /// ** Hardcoded **
    static let largeDeviceWidthCutoff: CGFloat = 850.0
    static let keyboardHeight: CGFloat = UIScreen.main.bounds.height < largeDeviceWidthCutoff
    ? 291
    : 301

    static let topBarHeight: CGFloat = 59

    static let suggestionsBarHeight: CGFloat = 40

    static let topButtonHeight: CGFloat = 50.0
    static let topButtonWidth: CGFloat = 70.0
    
    static let bottomSafeAreaPadding: CGFloat = 34.0

    static let topButtonCornerRadius: CGFloat = 12.0

    static let topButtonsVerticalPadding: CGFloat = 10.0
    static let topButtonsHorizontalPadding: CGFloat = 10.0

    static let topButtonPaddedHeight = topButtonHeight + (topButtonsVerticalPadding * 2.0)
    static let textFieldHorizontalPadding: CGFloat = 25

    static let attributesLayerHeight = keyboardHeight + topButtonPaddedHeight + suggestionsBarHeight
    
    struct Cell {
        static let checkBoxButtonWidth: CGFloat = 45.0
    }
    
    struct SegmentedButton {
        static let paddingHorizontal: CGFloat = 40.0
    }
    
    struct Pipeline {
        static let tolerance: Double = 0.005
        static let minimumClassifySeconds: Double = 1.0
        static let appearanceTransitionDelay: Double = 0.2
    }
    
    struct ColorHex {
        static let keyboardLight_legacy = "CDD0D6"
        static let keyboardDark_legacy = "303030"
        static let keyboardLight = "CFD3D9"
        static let keyboardDark = "383838"
        static let searchTextFieldDark = "535355"
        static let searchTextFieldLight = "FFFFFF"
    }
    
    static let dietNamePresets = ["Bulking", "Cutting", "Keto", "Maintenance"]
    
    static let mealPresets = [
        "Breakfast",
        "Lunch",
        "Dinner",
        "Pre-workout Meal",
        "Intra-workout Snack",
        "Post-workout Meal",
        "Snack",
        "Dinner Out",
        "Supper",
        "Midnight Snack",
        "Dessert"
    ]
    
    struct FormStyle {
        struct Padding {
            static let horizontal: CGFloat = 17
            static let vertical: CGFloat = 15
        }
    }
    
    struct Animations {
        static let bounce: Animation = .interactiveSpring(
            response: 0.35,
            dampingFraction: 0.66,
            blendDuration: 0.35
        )
    }
    
    struct Collapse {
        static let leftPadding: CGFloat = 64.0
//        static let imageTopPadding: CGFloat = 400.0
        static let imageTopPadding: CGFloat = 600.0
        static let nutrientsTopPadding: CGFloat = 436.0
    }
}
