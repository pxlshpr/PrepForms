import SwiftUI
import SwiftUISugar

//MARK: - Notifications


//MARK: - Extensions
extension CGSize {
    func isWider(than other: CGSize) -> Bool {
        widthToHeightRatio > other.widthToHeightRatio
    }
    func isTaller(than other: CGSize) -> Bool {
        widthToHeightRatio < other.widthToHeightRatio
    }
}

extension CGRect {
    var horizontallyPaddedBoundingBox: CGRect {
        let padding = (self.width / 2.0)
        return CGRect(
            x: max(0.0, self.origin.x - (padding / 2.0)),
            y: self.origin.y,
            width: min(self.width + padding, 1.0),
            height: self.size.height
        )
    }
}

extension CGFloat {
    func rounded(toPlaces places: Int) -> CGFloat {
        Double(self).rounded(toPlaces: places)
    }
}
