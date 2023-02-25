import UIKit
import VisionSugar

extension UIImage {
    func cropped(boundingBox: CGRect) async -> UIImage? {
        let cropRect = boundingBox.rectForSize(size)
        let image = fixOrientationIfNeeded()
        return cropImage(imageToCrop: image, toRect: cropRect)
    }
    
    func cropImage(imageToCrop: UIImage, toRect rect: CGRect) -> UIImage? {
        guard let imageRef = imageToCrop.cgImage?.cropping(to: rect) else {
            return nil
        }
        return UIImage(cgImage: imageRef)
    }
}
