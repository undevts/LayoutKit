import CoreGraphics
import Darwin.C

#if canImport(UIKit)
import UIKit
#endif

@frozen
public struct LayoutInsets {
    public static let zero = LayoutInsets(0)

    public var top: Double
    public var bottom: Double
    public var left: Double
    public var right: Double

    public init(_ value: Double) {
        top = value
        bottom = value
        left = value
        right = value
    }

    public init(top: Double, left: Double, bottom: Double, right: Double) {
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
    }

    @inline(__always)
    mutating func setAll(by direction: Direction, top: Double, leading: Double, bottom: Double, trailing: Double) {
        if direction == .ltr {
            left = leading
            right = trailing
        } else {
            right = leading
            left = trailing
        }
        self.top = top
        self.bottom = bottom
    }
}

public typealias Position = StyleInsets

@frozen
public enum Direction: UInt8, CaseIterable {
    case inherit // default
    case ltr
    case rtl
}

@frozen
public enum Display: UInt8, CaseIterable {
    case flex // default
    case none
}

@frozen
public enum PositionType: UInt8, CaseIterable {
    case `static` // default
    case relative
    case absolute
}

@frozen
public enum Overflow: UInt8, CaseIterable {
    case visible // default
    case hidden
    case scroll

    var scrolled: Bool {
        self == Overflow.scroll
    }
}

@frozen
public enum FlexDirection: UInt8, CaseIterable {
    case column // default
    case columnReverse
    case row
    case rowReverse

    @inline(__always)
    var isRow: Bool {
        self == FlexDirection.row || self == FlexDirection.rowReverse
    }

    @inline(__always)
    var isColumn: Bool {
        self == FlexDirection.column || self == FlexDirection.columnReverse
    }

    @inline(__always)
    var isReversed: Bool {
        self == FlexDirection.rowReverse || self == FlexDirection.columnReverse
    }

    // YGResolveFlexDirection
    @usableFromInline
    func resolve(by direction: Direction) -> FlexDirection {
        if direction == Direction.rtl {
            if self == .row {
                return .rowReverse
            } else if self == .rowReverse {
                return .row
            }
        }
        return self
    }

    func cross(by direction: Direction) -> FlexDirection {
        isColumn ? FlexDirection.row.resolve(by: direction) : .column
    }
}

@frozen
public enum FlexWrap: UInt8, CaseIterable {
    case nowrap // default
    case wrap
    case wrapReverse
}

// No support with FlexBasis.Content
public typealias FlexBasis = StyleValue

/// Sets how a flex item will grow or shrink to fit the space available in its flex container.
///
/// - SeeAlso: [MDN flex](https://developer.mozilla.org/en-US/docs/Web/CSS/flex)
@frozen
public struct Flex: Equatable, ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral {
    /// The item is sized according to its `width` and `height` properties. It is fully
    /// inflexible: it neither shrinks nor grows in relation to the flex container.
    /// This is equivalent to setting `Flex(grow: 0, shrink: 0, basis: .auto)`.
    public static let none: Flex = Flex(grow: 0, shrink: 0, basis: .auto)

    /// The item is sized according to its width and height properties. It shrinks to its
    // minimum size to fit the container, but does not grow to absorb any extra free space
    /// in the flex container. This is equivalent to setting `Flex(grow: 0, shrink: 1, basis: .auto)`.
    public static let `default`: Flex = Flex(grow: 0, shrink: 1, basis: .auto)

    /// The item is sized according to its width and height properties, but grows to absorb any
    /// extra free space in the flex container, and shrinks to its minimum size to fit the container.
    /// This is equivalent to setting `Flex(grow: 1, shrink: 1, basis: .auto)`.
    public static let auto: Flex = Flex(grow: 1, shrink: 1, basis: .auto)

    /// Sets the flex grow factor of a flex item's main size.
    public var grow: Double
    public var shrink: Double
    public var basis: FlexBasis

    public init(grow: Double, shrink: Double = 1, basis: FlexBasis = .auto) {
        self.grow = grow
        self.shrink = shrink
        self.basis = basis
    }

    // ExpressibleByFloatLiteral
    public init(floatLiteral value: Double) {
        if value < 0 {
            // TODO: https://www.w3.org/TR/css-flexbox-1/#flex-common
            // web => default/none; yoga => -value
            self.init(grow: 0, shrink: -value, basis: .auto)
            // self.init(grow: 0, shrink: 0, basis: .auto) // none
        } else {
            self.init(grow: value, shrink: 1, basis: .length(0))
        }
    }

    // ExpressibleByIntegerLiteral
    public init(integerLiteral value: Int) {
        self.init(floatLiteral: Double(value))
    }

    public static func ==(lhs: Flex, rhs: Flex) -> Bool {
        isDoubleEqual(lhs.grow, to: rhs.grow) &&
            isDoubleEqual(lhs.shrink, to: rhs.shrink) &&
            lhs.basis == rhs.basis
    }
}

@frozen
public enum JustifyContent: UInt8, CaseIterable {
    case start // default
    case end
    case center
    case spaceBetween
    case spaceAround
    case spaceEvenly
}

@frozen
public enum AlignItems: UInt8, CaseIterable {
    case stretch // default
    case start
    case end
    case center
    case baseline
}

@frozen
public enum AlignSelf: UInt8, CaseIterable {
    case auto // default
    case start
    case end
    case center
    case baseline
    case stretch

    var alignItems: AlignItems? {
        switch self {
        case .auto:
            return nil
        case .start:
            return .start
        case .end:
            return .end
        case .center:
            return .center
        case .baseline:
            return .baseline
        case .stretch:
            return .stretch
        }
    }
}

@frozen
public enum AlignContent: UInt8, CaseIterable {
    case start // default
    case end
    case center
    case spaceBetween
    case spaceAround
    case stretch
}

@frozen
public enum LayoutType: UInt8, CaseIterable {
    case `default`
    case text
}

@frozen
public enum MeasureMode {
    case undefined
    case exactly
    case atMost

    @inline(__always)
    public var isExactly: Bool {
        self == MeasureMode.exactly
    }

    @inline(__always)
    public var isUndefined: Bool {
        self == MeasureMode.undefined
    }

    @inline(__always)
    public var isAtMost: Bool {
        self == MeasureMode.atMost
    }

    @inline(__always)
    public func resolve<T>(_ value: T) -> T where T: FloatingPoint {
        isUndefined ? T.greatestFiniteMagnitude : value
    }
}

@frozen
public struct LayoutPosition {
    public static let zero = LayoutPosition(top: 0, left: 0, bottom: 0, right: 0)

    public var top: Double
    public var left: Double
    public var bottom: Double
    public var right: Double

    subscript(direction: FlexDirection) -> Double {
        get {
            switch direction {
            case .column:
                return top
            case .row:
                return left
            case .rowReverse:
                return right
            case .columnReverse:
                return bottom
            }
        }
        set {
            switch direction {
            case .column:
                top = newValue
            case .row:
                left = newValue
            case .rowReverse:
                right = newValue
            case .columnReverse:
                bottom = newValue
            }
        }
    }

    func leading(direction: FlexDirection) -> Double {
        switch direction {
        case .column:
            return top
        case .row:
            return left
        case .rowReverse:
            return right
        case .columnReverse:
            return bottom
        }
    }

    mutating func setLeading(direction: FlexDirection, size: Double) {
        switch direction {
        case .column:
            top = size
        case .row:
            left = size
        case .rowReverse:
            right = size
        case .columnReverse:
            bottom = size
        }
    }

    func trailing(direction: FlexDirection) -> Double {
        switch direction {
        case .column:
            return bottom
        case .row:
            return right
        case .rowReverse:
            return left
        case .columnReverse:
            return top
        }
    }

    mutating func setTrailing(direction: FlexDirection, size: Double) {
        switch direction {
        case .column:
            bottom = size
        case .row:
            right = size
        case .rowReverse:
            left = size
        case .columnReverse:
            top = size
        }
    }
}

struct LayoutCache { // YGCachedMeasurement
    let width: Double // availableWidth
    let height: Double // availableHeight
    let computedWidth: Double
    let computedHeight: Double
    let widthMode: MeasureMode // widthMeasureMode
    let heightMode: MeasureMode // heightMeasureMode

    func isEqual(width: Double, height: Double, widthMode: MeasureMode, heightMode: MeasureMode) -> Bool {
        isDoubleEqual(self.width, to: width) && isDoubleEqual(self.height, to: height) &&
            self.widthMode == widthMode && self.heightMode == heightMode
    }

    func validate(width: Double, height: Double, widthMode: MeasureMode, heightMode: MeasureMode,
        marginRow: Double, marginColumn: Double, scale: Double) -> Bool {
        if computedWidth < 0 || computedHeight < 0 {
            return false
        }
        let rounded = scale != 0
        let _width = rounded ? FlexBox.round(width, scale: scale, ceil: false, floor: false) : width
        let _height = rounded ? FlexBox.round(height, scale: scale, ceil: false, floor: false) : height
        let lastWidth = rounded ? FlexBox.round(self.width, scale: scale, ceil: false, floor: false) : self.width
        let lastHeight = rounded ? FlexBox.round(self.height, scale: scale, ceil: false, floor: false) : self.height

        let sameWidth = self.widthMode == widthMode && isDoubleEqual(_width, to: lastWidth)
        let sameWidth2 = LayoutCache.validateSize(mode: widthMode, size: width - marginRow,
            lastMode: self.widthMode, lastSize: self.width, computedSize: computedWidth)
        let sameHeight = self.heightMode == heightMode && isDoubleEqual(_height, to: lastHeight)
        let sameHeight2 = LayoutCache.validateSize(mode: heightMode, size: height - marginColumn,
            lastMode: self.heightMode, lastSize: self.height, computedSize: computedHeight)
        return (sameWidth || sameWidth2) && (sameHeight || sameHeight2)
    }

    static func validateSize(mode: MeasureMode, size: Double, lastMode: MeasureMode,
        lastSize: Double, computedSize: Double) -> Bool {
        switch mode {
        case .exactly:
            return isDoubleEqual(size, to: computedSize)
        case .atMost:
            switch lastMode {
            case .undefined:
                return (size >= computedSize || isDoubleEqual(size, to: computedSize))
            case .atMost:
                return (lastSize > size && (computedSize <= size || isDoubleEqual(size, to: computedSize)))
            case .exactly:
                return false
            }
        case .undefined:
            return false
        }
    }
}
