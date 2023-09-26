#if canImport(UIKit)
import UIKit // UIEdgeInsets
#endif

/// The inset distances for the sides of a rectangle.
@frozen
public struct StyleInsets: Equatable, CustomStringConvertible {
    public static let zero: StyleInsets = StyleInsets(.length(0.0))
    public static let auto: StyleInsets = StyleInsets(.auto)

    public var top: StyleValue
    public var bottom: StyleValue
    public var left: StyleValue
    public var right: StyleValue
    public var leading: StyleValue?
    public var trailing: StyleValue?

    public init(_ value: StyleValue) {
        top = value
        bottom = value
        left = value
        right = value
        leading = nil
        trailing = nil
    }

    @inlinable
    public init(from value: Double) {
        self.init(StyleValue(from: value))
    }

    @available(*, deprecated, message: "Use `init(horizontal:vertical:)` instead.")
    public init(vertical: StyleValue, horizontal: StyleValue) {
        top = vertical
        bottom = vertical
        left = horizontal
        right = horizontal
        leading = nil
        trailing = nil
    }

    public init(horizontal: StyleValue, vertical: StyleValue) {
        top = vertical
        bottom = vertical
        left = horizontal
        right = horizontal
        leading = nil
        trailing = nil
    }

    public init(top: StyleValue, left: StyleValue, bottom: StyleValue, right: StyleValue) {
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
        leading = nil
        trailing = nil
    }

    @available(*, deprecated, message: "Use `init(top:leading:bottom:trailing:)` instead.")
    public init(top: StyleValue, bottom: StyleValue, leading: StyleValue?, trailing: StyleValue?) {
        self.top = top
        self.bottom = bottom
        self.leading = leading
        self.trailing = trailing
        left = StyleValue.zero
        right = StyleValue.zero
    }

    public init(top: StyleValue, leading: StyleValue?, bottom: StyleValue, trailing: StyleValue?) {
        self.top = top
        self.bottom = bottom
        self.leading = leading
        self.trailing = trailing
        left = StyleValue.zero
        right = StyleValue.zero
    }

    public init(top: StyleValue, bottom: StyleValue, left: StyleValue, right: StyleValue,
        leading: StyleValue?, trailing: StyleValue?) {
        self.top = top
        self.bottom = bottom
        self.left = left
        self.right = right
        self.leading = leading
        self.trailing = trailing
    }

    public init(_ value: StyleValue?, edges: Edge) {
        if edges.contains(.top) {
            top = value ?? StyleValue.zero
        } else {
            top = StyleValue.zero
        }
        if edges.contains(.left) {
            left = value ?? StyleValue.zero
        } else {
            left = StyleValue.zero
        }
        if edges.contains(.bottom) {
            bottom = value ?? StyleValue.zero
        } else {
            bottom = StyleValue.zero
        }
        if edges.contains(.right) {
            right = value ?? StyleValue.zero
        } else {
            right = StyleValue.zero
        }
        if edges.contains(.leading) {
            leading = value
        } else {
            leading = StyleValue.zero
        }
        if edges.contains(.trailing) {
            trailing = value
        } else {
            trailing = StyleValue.zero
        }
    }

    // MARK: CustomStringConvertible
    public var description: String {
        let _leading = leading?.description ?? "leading=nil"
        let _trailing = trailing?.description ?? "trailing=nil"
        return "StyleInsets(top=\(top),left=\(left),bottom=\(bottom),right=\(right),\(_leading),\(_trailing)"
    }

    // YGNode::getLeadingMargin
    public func leading(direction: FlexDirection) -> StyleValue {
        switch direction {
        case .row:
            return leading ?? left
        case .rowReverse:
            return leading ?? right
        case .column:
            return top
        case .columnReverse:
            return bottom
        }
    }

    // YGNode::getTrailingMargin
    public func trailing(direction: FlexDirection) -> StyleValue {
        switch direction {
        case .row:
            return trailing ?? right
        case .rowReverse:
            return trailing ?? left
        case .column:
            return bottom
        case .columnReverse:
            return top
        }
    }

    public func total(direction: FlexDirection) -> StyleValue {
        switch direction {
        case .row:
            return (leading ?? left) + (trailing ?? right)
        case .rowReverse:
            return (leading ?? right) + (trailing ?? left)
        case .column, .columnReverse:
            return top + bottom
        }
    }

    public mutating func update(_ value: StyleValue?, edges: Edge) {
        if edges.contains(.top) {
            top = value ?? StyleValue.zero
        }
        if edges.contains(.left) {
            left = value ?? StyleValue.zero
        }
        if edges.contains(.bottom) {
            bottom = value ?? StyleValue.zero
        }
        if edges.contains(.right) {
            right = value ?? StyleValue.zero
        }
        if edges.contains(.leading) {
            leading = value
        }
        if edges.contains(.trailing) {
            trailing = value
        }
    }

    public func copy(_ value: StyleValue?, edges: Edge) -> StyleInsets {
        var result = self
        if edges.contains(.top) {
            result.top = value ?? StyleValue.zero
        }
        if edges.contains(.left) {
            result.left = value ?? StyleValue.zero
        }
        if edges.contains(.bottom) {
            result.bottom = value ?? StyleValue.zero
        }
        if edges.contains(.right) {
            result.right = value ?? StyleValue.zero
        }
        if edges.contains(.leading) {
            result.leading = value
        }
        if edges.contains(.trailing) {
            result.trailing = value
        }
        return result
    }

    public static func ==(lhs: StyleInsets, rhs: StyleInsets) -> Bool {
        lhs.left == rhs.left && lhs.right == rhs.right &&
            lhs.top == rhs.top && lhs.bottom == rhs.bottom &&
            lhs.leading == rhs.leading && lhs.trailing == rhs.trailing
    }
}

extension StyleInsets {
    @frozen
    public struct Edge: OptionSet {
        public let rawValue: UInt8

        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }

        public init(_ value: UInt8) {
            rawValue = value
        }

        public static let top = Edge(rawValue: 1 << 0)
        public static let left = Edge(rawValue: 1 << 1)
        public static let bottom = Edge(rawValue: 1 << 2)
        public static let right = Edge(rawValue: 1 << 3)
        public static let leading = Edge(rawValue: 1 << 4)
        public static let trailing = Edge(rawValue: 1 << 5)
        public static let vertical: Edge = [.top, .bottom]
        // TODO: semantic or absolute
        public static let horizontal: Edge = [.left, .right]
        public static let all: Edge = [.top, .left, .bottom, .right]
    }
}

#if canImport(UIKit)
extension StyleInsets {
    public func edgeInsets(style: FlexStyle, size: Size) -> UIEdgeInsets {
        let direction = style.direction == Direction.ltr ? FlexDirection.row : FlexDirection.rowReverse
        let top = self.top.resolve(by: size.height)
        let bottom = self.bottom.resolve(by: size.height)
        let left = self.leading(direction: direction)
            .resolve(by: size.width)
        let right = self.trailing(direction: direction)
            .resolve(by: size.width)
        return UIEdgeInsets(top: CGFloat(top), left: CGFloat(left),
            bottom: CGFloat(bottom), right: CGFloat(right))
    }
}
#endif // canImport(UIKit)
