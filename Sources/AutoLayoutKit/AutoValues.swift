#if canImport(UIKit)

import UIKit

/// A auto attribute type.
public protocol AutoAttribute {
    /// A convenient property for cast to `NSLayoutConstraint.Attribute`.
    var attribute: NSLayoutConstraint.Attribute { get }
}

/// The sides of the object’s alignment rectangle.
@frozen
public enum AutoEdge: Int, AutoAttribute {
    /// The left side of the object’s alignment rectangle.
    case left = 1
    /// The right side of the object’s alignment rectangle.
    case right = 2
    /// The top of the object’s alignment rectangle.
    case top = 3
    /// The bottom of the object’s alignment rectangle.
    case bottom = 4
    /// The leading edge of the object’s alignment rectangle.
    case leading = 5
    /// The trailing edge of the object’s alignment rectangle.
    case trailing = 6
    /// The object’s left margin. For `UIView` objects, the margins are defined by their `layoutMargins` property.
    case leftMargin = 13
    /// The object’s right margin. For `UIView` objects, the margins are defined by their `layoutMargins` property.
    case rightMargin = 14
    /// The object’s top margin. For `UIView` objects, the margins are defined by their `layoutMargins` property.
    case topMargin = 15
    /// The object’s bottom margin. For `UIView` objects, the margins are defined by their `layoutMargins` property.
    case bottomMargin = 16
    /// The object’s leading margin. For `UIView` objects, the margins are defined by their `layoutMargins` property.
    case leadingMargin = 17
    /// The object’s trailing margin. For `UIView` objects, the margins are defined by their `layoutMargins` property.
    case trailingMargin = 18

    @inlinable
    public var attribute: NSLayoutConstraint.Attribute {
        // `rawValue` 必须保持一致
        NSLayoutConstraint.Attribute(rawValue: rawValue)!
    }

    // The bottom, right, and trailing insets (and relations, if an inequality) are inverted to become offsets
    @inlinable
    var shouldInvert: Bool {
        switch self {
        case .left, .leading, .top, .leftMargin, .leadingMargin, .topMargin:
            return false
        case .right, .bottom, .trailing, .rightMargin, .bottomMargin, .trailingMargin:
            return true
        }
    }
}

/// The dimensions of the object’s alignment rectangle.
@frozen
public enum AutoDimension: Int, AutoAttribute {
    /// The width of the object’s alignment rectangle.
    case width = 7
    /// The height of the object’s alignment rectangle.
    case height = 8

    @inlinable
    public var attribute: NSLayoutConstraint.Attribute {
        // `rawValue` 必须保持一致
        NSLayoutConstraint.Attribute(rawValue: rawValue)!
    }
}

/// The axes of the object’s alignment rectangle.
@frozen
public enum AutoAxis: Int, AutoAttribute {
    /// The center along the x-axis of the object’s alignment rectangle.
    case centerX = 9
    /// The center along the y-axis of the object’s alignment rectangle.
    case centerY = 10
    /// The object’s baseline. For objects with more than one line of text,
    /// this is the baseline for the bottommost line of text.
    case lastBaseline = 11
    /// The object’s baseline. For objects with more than one line of text,
    /// this is the baseline for the topmost line of text.
    case firstBaseline = 12
    /// The center along the x-axis between the object’s left and right margin.
    /// For `UIView` objects, the margins are defined by their `layoutMargins` property.
    case centerXMargin = 19
    /// The center along the y-axis between the object’s top and bottom margin.
    /// For `UIView` objects, the margins are defined by their `layoutMargins` property.
    case centerYMargin = 20

    @inlinable
    public var attribute: NSLayoutConstraint.Attribute {
        // `rawValue` 必须保持一致
        NSLayoutConstraint.Attribute(rawValue: rawValue)!
    }
}

#endif // canImport(UIKit)
