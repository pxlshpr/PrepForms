import SwiftUI

extension ExtractorView {
    
    @ViewBuilder
    var croppedImagesLayer: some View {
        if extractor.dismissState.shouldShowCroppedImages {
            ZStack {
                Color.clear
                //                Color.blue.opacity(0.3)
                ForEach(extractor.croppedImages.indices, id: \.self) { i in
                    croppedImage(
                        extractor.croppedImages[i].0,
                        rect: extractor.croppedImages[i].1,
                        stackedAngle: extractor.croppedImages[i].3,
                        wiggleAngles: extractor.croppedImages[i].4
                    )
                }
            }
            .padding(.top, K.topBarHeight)
            .edgesIgnoringSafeArea(.all)
            .transition(.opacity)
            .scaleEffect(extractor.croppedImagesScale)
            .padding(.top, extractor.croppedImagesPaddingTop)
            .padding(.trailing, extractor.croppedImagesPaddingTrailing)
//            .scaleEffect(extractor.dismissState == .shrinkingCroppedImages ? 0 : 1)
//            .padding(.top, extractor.dismissState == .shrinkingCroppedImages ? 0 : 0)
//            .padding(.trailing, extractor.dismissState == .shrinkingCroppedImages ? 300 : 0)
        }
    }
    
    func croppedImage(
        _ image: UIImage,
        rect: CGRect,
        stackedAngle: Angle,
        wiggleAngles: (Angle, Angle, Angle, Angle)
    ) -> some View {
        var x: CGFloat {
            extractor.dismissState.shouldStackCropImages ? UIScreen.main.bounds.midX : rect.midX
        }
        
        var yCorrection: CGFloat {
#if targetEnvironment(simulator)
            /// This correction only needs to applied on larger devices in the simulator for some reason
            UIScreen.main.bounds.height < K.largeDeviceWidthCutoff
            ? K.topBarHeight
            : 0
#else
            K.topBarHeight
#endif
        }
        
        var y: CGFloat {
            extractor.dismissState.shouldStackCropImages
            //            ? 150 - K.topBarHeight
            ? 150 - K.topBarHeight - yCorrection
            : rect.midY - yCorrection
        }
        
        var angle: Angle {
            if extractor.dismissState.shouldStackCropImages {
                return stackedAngle
            } else if extractor.dismissState == .firstWiggle {
                return wiggleAngles.0
            } else if extractor.dismissState == .secondWiggle {
                return wiggleAngles.1
            } else if extractor.dismissState == .thirdWiggle {
                return wiggleAngles.2
            } else if extractor.dismissState == .fourthWiggle {
                return wiggleAngles.3
            } else {
                return .degrees(0)
            }
        }
        
        var scale: CGFloat {
            if extractor.dismissState.shouldStackCropImages {
                return 2
            } else if extractor.dismissState == .firstWiggle {
                return 1.1
            } else if extractor.dismissState == .secondWiggle {
                return 1.15
            } else if extractor.dismissState == .thirdWiggle {
                return 1.2
            } else if extractor.dismissState == .fourthWiggle {
                return 1.25
            } else if extractor.dismissState == .liftingUp {
                return 1.05
            } else {
                return 1.0
                //                return 1.03
            }
        }
        
        var shadow: CGFloat {
            if extractor.dismissState.shouldStackCropImages {
                return 3
            } else if extractor.dismissState == .firstWiggle {
                return 7
            } else if extractor.dismissState == .secondWiggle {
                return 8
            } else if extractor.dismissState == .thirdWiggle {
                return 9
            } else if extractor.dismissState == .fourthWiggle {
                return 10
            } else if extractor.dismissState == .liftingUp {
                return 6
            } else {
                return 5
            }
        }
        
        return Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(width: rect.width, height: rect.height)
            .rotationEffect(angle, anchor: .center)
            .scaleEffect(scale, anchor: .center)
            .position(x: x, y: y)
            .shadow(radius: shadow, x: 0, y: shadow)
    }
}
