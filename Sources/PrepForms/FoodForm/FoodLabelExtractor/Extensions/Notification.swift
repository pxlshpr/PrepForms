import Foundation

extension Notification.Name {
    public static var zoomZoomableScrollView: Notification.Name { return .init("zoomZoomableScrollView") }
    public static var zoomScrollViewViewportChanged: Notification.Name { return .init("zoomScrollViewViewportChanged") }
    
    public static var scannerDidPresentKeyboard: Notification.Name { return .init("scannerDidPresentKeyboard") }
    public static var scannerDidDismissKeyboard: Notification.Name { return .init("scannerDidDismissKeyboard") }
    public static var scannerDidSetImage: Notification.Name { return .init("scannerDidSetImage") }
    
    public static var scannerDidChangeAttribute: Notification.Name { return .init("scannerDidChangeAttribute" )}
    
    public static var didEnterForeground: Notification.Name { return .init("didEnterForeground") }
    
    public static var homeViewDidBecomeInactive: Notification.Name { return .init("homeViewDidBecomeInactive") }

}

extension Notification {
    public struct ZoomableScrollViewKeys {
        public static let contentOffset = "contentOffset"
        public static let contentSize = "contentSize"
        public static let zoomScale = "zoomScale"
        public static let zoomBox = "zoomBox"
        public static let imageSize = "imageSize"
    }
    
    public struct ScannerKeys {
        public static let nextAttribute = "nextAttribute"
    }
}
