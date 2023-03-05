//import SwiftUI
//import FoodLabelCamera
//import FoodLabelScanner
//import SwiftHaptics
//import ZoomableScrollView
//import SwiftSugar
//import Shimmer
//
//extension Scanner {
//    
//    func croppedImage(
//        _ image: UIImage,
//        rect: CGRect,
//        stackedAngle: Angle,
//        wiggleAngles: (Angle, Angle, Angle, Angle)
//    ) -> some View {
//        var x: CGFloat {
//            model.stackedOnTop ? UIScreen.main.bounds.midX : rect.midX
//        }
//        
//        var y: CGFloat {
//            model.stackedOnTop ? 150 : rect.midY
//        }
//        
//        var angle: Angle {
//            if model.stackedOnTop {
//                return stackedAngle
//            } else if model.animatingFirstWiggleOfCroppedImages {
//                return wiggleAngles.0
//            } else if model.animatingSecondWiggleOfCroppedImages {
//                return wiggleAngles.1
//            } else if model.animatingThirdWiggleOfCroppedImages {
//                return wiggleAngles.2
//            } else if model.animatingFourthWiggleOfCroppedImages {
//                return wiggleAngles.3
//            } else {
//                return .degrees(0)
//            }
//        }
//
//        var scale: CGFloat {
//            if model.stackedOnTop {
//                return 2
//            } else if model.animatingFirstWiggleOfCroppedImages {
//                return 1.1
//            } else if model.animatingSecondWiggleOfCroppedImages {
//                return 1.15
//            } else if model.animatingThirdWiggleOfCroppedImages {
//                return 1.2
//            } else if model.animatingFourthWiggleOfCroppedImages {
//                return 1.25
//            } else if model.animatingLiftingUpOfCroppedImages {
//                return 1.05
//            } else {
//                return 1.0
////                return 1.03
//            }
//        }
//        
//        var shadow: CGFloat {
//            if model.stackedOnTop {
//                return 3
//            } else if model.animatingFirstWiggleOfCroppedImages {
//                return 7
//            } else if model.animatingSecondWiggleOfCroppedImages {
//                return 8
//            } else if model.animatingThirdWiggleOfCroppedImages {
//                return 9
//            } else if model.animatingFourthWiggleOfCroppedImages {
//                return 10
//            } else if model.animatingLiftingUpOfCroppedImages {
//                return 6
//            } else {
//                return 5
//            }
//        }
//
//        return Image(uiImage: image)
//            .resizable()
//            .scaledToFit()
//            .frame(width: rect.width, height: rect.height)
//            .rotationEffect(angle, anchor: .center)
//            .scaleEffect(scale, anchor: .center)
//            .position(x: x, y: y)
//            .shadow(radius: shadow, x: 0, y: shadow)
//    }
//}
