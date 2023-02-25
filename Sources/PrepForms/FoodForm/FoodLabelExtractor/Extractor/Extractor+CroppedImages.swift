import SwiftUI
import VisionSugar
import SwiftHaptics
import SwiftSugar
import PrepDataTypes

extension Extractor {
    
    var getCutoutTextBoxes: [TextBox] {
        textsToCrop.map {
            TextBox(
                id: $0.id,
                boundingBox: $0.boundingBox,
                color: .accentColor,
                opacity: 0.8,
                tapHandler: {}
            )
        }
    }
    
    var randomWiggleAngles: (Angle, Angle, Angle, Angle) {
        let left1 = Angle.degrees(CGFloat.random(in: (-8)...(-2)))
        let right1 = Angle.degrees(CGFloat.random(in: 2...8))
        let left2 = Angle.degrees(CGFloat.random(in: (-8)...(-2)))
        let right2 = Angle.degrees(CGFloat.random(in: 2...8))
        let leftFirst = Bool.random()
        if leftFirst {
            return (left1, right1, left2, right2)
        } else {
            return (right1, left1, right2, left2)
        }
    }
}

extension Extractor {
    
    func rectForText(_ text: RecognizedText) -> CGRect {
        if let lastContentSize, let lastContentOffset {
            cprint("    📐 Have contentSize and contentOffset, so calculating")
            return getRectForText(text, contentSize: lastContentSize, contentOffset: lastContentOffset)
        }
        cprint("    📐 DON'T Have contentSize and contentOffset, doing it manually")

        //TODO: Try and always have lastContentSize and lastContentOffset and calculate using those
        let boundingBox = text.boundingBox
        guard let image else { return .zero }

        let screen = UIScreen.main.bounds

        let correctedRect: CGRect
//        if self.isUsingCamera {
//            let scaledWidth: CGFloat = (image.size.width * screen.height) / image.size.height
//            let scaledSize = CGSize(width: scaledWidth, height: screen.height)
//            let rectForSize = boundingBox.rectForSize(scaledSize)
//
//            correctedRect = CGRect(
//                x: rectForSize.origin.x - ((scaledWidth - screen.width) / 2.0),
//                y: rectForSize.origin.y,
//                width: rectForSize.size.width,
//                height: rectForSize.size.height
//            )
//
//            cprint("🌱 box.boundingBox: \(boundingBox)")
//            cprint("🌱 scaledSize: \(scaledSize)")
//            cprint("🌱 rectForSize: \(rectForSize)")
//            cprint("🌱 correctedRect: \(correctedRect)")
//            cprint("🌱 image.boundingBoxForScreenFill: \(image.boundingBoxForScreenFill)")
//        } else {

            let rectForSize: CGRect
            let x: CGFloat
            let y: CGFloat

            if image.size.widthToHeightRatio > screen.size.widthToHeightRatio {
                /// This means we have empty strips at the top, and image gets width set to screen width
                let scaledHeight = (image.size.height * screen.width) / image.size.width
                let scaledSize = CGSize(width: screen.width, height: scaledHeight)
                rectForSize = boundingBox.rectForSize(scaledSize)
                x = rectForSize.origin.x
                y = rectForSize.origin.y + ((screen.height - scaledHeight) / 2.0)

                cprint("🌱 scaledSize: \(scaledSize)")
            } else {
                let scaledWidth = (image.size.width * screen.height) / image.size.height
                let scaledSize = CGSize(width: scaledWidth, height: screen.height)
                rectForSize = boundingBox.rectForSize(scaledSize)
                x = rectForSize.origin.x + ((screen.width - scaledWidth) / 2.0)
                y = rectForSize.origin.y
            }

            correctedRect = CGRect(
                x: x,
                y: y,
                width: rectForSize.size.width,
                height: rectForSize.size.height
            )

            cprint("🌱 rectForSize: \(rectForSize)")
            cprint("🌱 correctedRect: \(correctedRect), screenHeight: \(screen.height)")
//        }
        return correctedRect
    }
    
    func getRectForText(_ text: RecognizedText, contentSize: CGSize, contentOffset: CGPoint) -> CGRect {
        /// Get the bounding box in terms of the (scaled) image dimensions
        let rect = text.boundingBox.rectForSize(contentSize)

        cprint("    📐 Getting rectForSize for: \(text.string) \(rect)")

        /// Now offset it by the scrollview's current offset to get it's current position
        return CGRect(
            x: rect.origin.x - contentOffset.x,
            y: rect.origin.y - contentOffset.y,
            width: rect.size.width,
            height: rect.size.height
        )
    }
}
