import SwiftUI

public struct TextBox {
    let id: UUID
    var boundingBox: CGRect
    var color: Color
    var opacity: CGFloat
    var type: TextBoxType
    var tapHandler: (() -> ())?
    
    public init(
        id: UUID = UUID(),
        type: TextBoxType = .undefined,
        boundingBox: CGRect,
        color: Color,
        opacity: CGFloat = 0.3,
        tapHandler: (() -> ())? = nil)
    {
        self.id = id
        self.type = type
        self.boundingBox = boundingBox
        self.color = color
        self.opacity = opacity
        self.tapHandler = tapHandler
    }
}

extension TextBox: Equatable {
    public static func ==(lhs: TextBox, rhs: TextBox) -> Bool {
        lhs.id == rhs.id
        && lhs.boundingBox == rhs.boundingBox
        && lhs.color == rhs.color
        && lhs.opacity == rhs.opacity
        && lhs.type == rhs.type
        /// Note: we're not checking `tapHandler`
    }
}
