#if canImport(UIKit)
import UIKit
#endif

#if canImport(Cocoa)
import Cocoa
#endif

#if SWIFT_PACKAGE
import FlexLayoutCore
#endif

extension FlexStyleStorage {
    static func ==(lhs: FlexStyleStorage, rhs: FlexStyleStorage) -> Bool {
        lhs.direction == rhs.direction
            && lhs.flexDirection == rhs.flexDirection
            && lhs.justifyContent == rhs.justifyContent
            && lhs.alignContent == rhs.alignContent
            && lhs.alignItems == rhs.alignItems
            && lhs.alignSelf == rhs.alignSelf
            && lhs.positionType == rhs.positionType
            && lhs.flexWrap == rhs.flexWrap
            && lhs.overflow == rhs.overflow
            && lhs.display == rhs.display
    }
}

public struct FlexStyle: Equatable {
    private var storage: FlexStyleStorage
    public internal(set) var flex: Flex = .none
    public internal(set) var position = Position.auto

    public internal(set) var margin = StyleInsets.zero
    public internal(set) var padding = StyleInsets.zero
    public internal(set) var border = StyleInsets.zero
    // dimensions
    public internal(set) var width = StyleValue.auto
    public internal(set) var height = StyleValue.auto
    // minDimensions
    public internal(set) var minWidth = StyleValue.length(0.0)
    public internal(set) var minHeight = StyleValue.length(0.0)
    // maxDimensions, Optional<T> => `CompactValue::isUndefined`
    public internal(set) var maxWidth: StyleValue?
    public internal(set) var maxHeight: StyleValue?
    public internal(set) var aspectRatio = Double.nan
#if canImport(UIKit)
    public static var scale = Double(UIScreen.main.scale)
#elseif canImport(Cocoa)
    public static var scale = Double(NSScreen.main?.backingScaleFactor ?? 1)
#else
    public static var scale: Double = 1.0
#endif

    public init() {
        storage = FlexStyleStorage()
    }

    public static func ==(lhs: FlexStyle, rhs: FlexStyle) -> Bool {
        lhs.storage == rhs.storage &&
            lhs.flex == rhs.flex
            && lhs.position == rhs.position
            && lhs.margin == rhs.margin
            && lhs.padding == rhs.padding
            && lhs.border == rhs.border
            && lhs.width == rhs.width
            && lhs.height == rhs.height
            && lhs.minWidth == rhs.minWidth
            && lhs.minHeight == rhs.minHeight
            && lhs.maxWidth == rhs.maxWidth
            && lhs.maxHeight == rhs.maxHeight
            && isDoubleEqual(lhs.aspectRatio, to: rhs.aspectRatio)
    }
}

extension FlexStyle {
    public internal(set) var direction: Direction {
        get {
            Direction(rawValue: storage.direction)!
        }
        set {
            storage.direction = newValue.rawValue
        }
    }

    public internal(set) var flexDirection: FlexDirection {
        get {
            FlexDirection(rawValue: storage.flexDirection)!
        }
        set {
            storage.flexDirection = newValue.rawValue
        }
    }

    public internal(set) var justifyContent: JustifyContent {
        get {
            JustifyContent(rawValue: storage.justifyContent)!
        }
        set {
            storage.justifyContent = newValue.rawValue
        }
    }

    public internal(set) var alignContent: AlignContent {
        get {
            AlignContent(rawValue: storage.alignContent)!
        }
        set {
            storage.alignContent = newValue.rawValue
        }
    }

    public internal(set) var alignItems: AlignItems {
        get {
            AlignItems(rawValue: storage.alignItems)!
        }
        set {
            storage.alignItems = newValue.rawValue
        }
    }

    public internal(set) var alignSelf: AlignSelf {
        get {
            AlignSelf(rawValue: storage.alignSelf)!
        }
        set {
            storage.alignSelf = newValue.rawValue
        }
    }

    public internal(set) var flexWrap: FlexWrap {
        get {
            FlexWrap(rawValue: storage.flexWrap)!
        }
        set {
            storage.flexWrap = newValue.rawValue
        }
    }

    public internal(set) var overflow: Overflow {
        get {
            Overflow(rawValue: storage.overflow)!
        }
        set {
            storage.overflow = newValue.rawValue
        }
    }

    public internal(set) var display: Display {
        get {
            Display(rawValue: storage.display)!
        }
        set {
            storage.display = newValue.rawValue
        }
    }

    public internal(set) var positionType: PositionType {
        get {
            PositionType(rawValue: storage.positionType)!
        }
        set {
            storage.positionType = newValue.rawValue
        }
    }

    public internal(set) var flexGrow: Double {
        get {
            flex.grow
        }
        set {
            flex.grow = newValue
        }
    }
    public internal(set) var flexShrink: Double {
        get {
            flex.shrink
        }
        set {
            flex.shrink = newValue
        }
    }
    public internal(set) var flexBasis: FlexBasis {
        get {
            flex.basis
        }
        set {
            flex.basis = newValue
        }
    }

    @inline(__always)
    var computedMaxWidth: StyleValue {
        maxWidth ?? StyleValue.auto
    }
    @inline(__always)
    var computedMaxHeight: StyleValue {
        maxHeight ?? StyleValue.auto
    }

    @inline(__always)
    var absoluteLayout: Bool {
        positionType == PositionType.absolute
    }
    @inline(__always)
    var relativeLayout: Bool {
        positionType == PositionType.relative
    }

    @inline(__always)
    var wrapped: Bool {
        flexWrap != FlexWrap.nowrap
    }

    @inline(__always)
    var hidden: Bool {
        display == Display.none
    }
}

extension FlexStyle {
    // YGResolveFlexDirection
    @inlinable
    func resolveFlexDirection(by direction: Direction) -> FlexDirection {
        flexDirection.resolve(by: direction)
    }

    // YGNodeIsLeadingPosDefined
    @inlinable
    func isLeadingPositionDefined(for direction: FlexDirection) -> Bool {
        position.leading(direction: direction) != StyleValue.auto
    }

    // YGNodeIsTrailingPosDefined
    @inlinable
    func isTrailingPositionDefined(for direction: FlexDirection) -> Bool {
        position.trailing(direction: direction) != StyleValue.auto
    }

    // YGNodeLeadingPosition
    @inlinable
    func leadingPosition(for direction: FlexDirection, size: Double) -> Double {
        let value = position.leading(direction: direction)
        return value == StyleValue.auto ? 0.0 : value.resolve(by: size)
    }

    // YGNodeTrailingPosition
    @inlinable
    func trailingPosition(for direction: FlexDirection, size: Double) -> Double {
        let value = position.trailing(direction: direction)
        return value == StyleValue.auto ? 0.0 : value.resolve(by: size)
    }

    // If both left and right are defined, then use left. Otherwise, return +left or
    // -right depending on which is defined.
    // YGNodeRelativePosition
    @inlinable
    func relativePosition(for direction: FlexDirection, size: Double) -> Double {
        if isLeadingPositionDefined(for: direction) {
            return leadingPosition(for: direction, size: size)
        }
        let trailing = trailingPosition(for: direction, size: size)
        return trailing.isNaN ? trailing : -1.0 * trailing
    }

    // YGNode::getLeadingMargin
    @inlinable
    func leadingMargin(for direction: FlexDirection, width: Double) -> Double {
        let value = margin.leading(direction: direction)
        let result = value.resolve(by: width)
        return result.isNaN ? 0 : result
    }

    // YGNode::getTrailingMargin
    @inlinable
    func trailingMargin(for direction: FlexDirection, width: Double) -> Double {
        let value = margin.trailing(direction: direction)
        let result = value.resolve(by: width)
        return result.isNaN ? 0 : result
    }

    // YGNode::getLeadingPadding
    @inlinable
    func leadingPadding(for direction: FlexDirection, width: Double) -> Double {
        let value = padding.leading(direction: direction)
        let result = value.resolve(by: width)
        return result > 0 ? result : 0
    }

    // YGNode::getTrailingPadding
    @inlinable
    func trailingPadding(for direction: FlexDirection, width: Double) -> Double {
        let value = padding.trailing(direction: direction)
        let result = value.resolve(by: width)
        return result > 0 ? result : 0
    }

    // YGNode::getLeadingBorder
    @inlinable
    func leadingBorder(for direction: FlexDirection) -> Double {
        let value = border.leading(direction: direction)
        let result = value.resolve(by: 0)
        return result > 0 ? result : 0
    }

    // YGNode::getTrailingBorder
    @inlinable
    func trailingBorder(for direction: FlexDirection) -> Double {
        let value = border.trailing(direction: direction)
        let result = value.resolve(by: 0)
        return result > 0 ? result : 0
    }

    // YGNodePaddingAndBorderForAxis
    @inline(__always)
    func totalInnerSize(for direction: FlexDirection, width: Double) -> Double {
        totalLeadingSize(for: direction, width: width) + totalTrailingSize(for: direction, width: width)
    }

    // YGNode::getLeadingPaddingAndBorder
    @inline(__always)
    func totalLeadingSize(for direction: FlexDirection, width: Double) -> Double {
        leadingPadding(for: direction, width: width) + leadingBorder(for: direction)
    }

    // YGNode::getTrailingPaddingAndBorder
    @inline(__always)
    func totalTrailingSize(for direction: FlexDirection, width: Double) -> Double {
        trailingPadding(for: direction, width: width) + trailingBorder(for: direction)
    }

    // YGNode::getMarginForAxis
    @inline(__always)
    func totalOuterSize(for direction: FlexDirection, width: Double) -> Double {
        leadingMargin(for: direction, width: width) + trailingMargin(for: direction, width: width)
    }

    @inline(__always)
    func totalPadding(for direction: FlexDirection, width: Double) -> Double {
        leadingPadding(for: direction, width: width) + trailingPadding(for: direction, width: width)
    }

    @inline(__always)
    func totalBorder(for direction: FlexDirection) -> Double {
        leadingBorder(for: direction) + trailingBorder(for: direction)
    }

    // YGNodeBoundAxisWithinMinAndMax
    func bound(for direction: FlexDirection, value: Double, size: Double) -> Double {
        let min: Double
        let max: Double
        if direction.isColumn {
            min = minHeight.resolve(by: size)
            max = computedMaxHeight.resolve(by: size)
        } else {
            min = minWidth.resolve(by: size)
            max = computedMaxWidth.resolve(by: size)
        }
        var bound = value
        if max >= 0.0 && bound > max {
            bound = max
        }
        if min >= 0.0 && bound < min {
            bound = min
        }
        return bound
    }

    // YGNodeBoundAxis(node, axis, value, axisSize, widthSize)
    // TODO: Rename method and parameters
    func bound(axis direction: FlexDirection, value: Double, axisSize: Double, width: Double) -> Double {
        max(bound(for: direction, value: value, size: axisSize), totalInnerSize(for: direction, width: width))
    }

    // YGConstrainMaxSizeForMode(axis, parentAxisSize, parentWidth, mode, size)
    // TODO: Rename method and parameters
    func constrainMaxSize(axis: FlexDirection, parentAxisSize: Double, parentWidth: Double, mode: MeasureMode,
        size: Double) -> (MeasureMode, Double) {
        let maxSize = maxDimension(by: axis).resolve(by: parentAxisSize) + totalOuterSize(for: axis, width: parentWidth)
        switch mode {
        case .exactly, .atMost:
            let s: Double = (maxSize.isNaN || size < maxSize) ? size : maxSize
            return (mode, s)
        case .undefined:
            if maxSize.isNaN {
                return (mode, size)
            } else {
                return (MeasureMode.atMost, maxSize)
            }
        }
    }

    // YGNode::resolveDirection
    @inlinable
    func resolveDirection(by direction: Direction) -> Direction {
        if self.direction == Direction.inherit {
            return direction != Direction.inherit ? direction : .ltr
        } else {
            return self.direction
        }
    }

    @inline(__always)
    func dimension(by direction: FlexDirection) -> StyleValue {
        direction.isRow ? width : height
    }

    @inline(__always)
    func minDimension(by direction: FlexDirection) -> StyleValue {
        direction.isRow ? minWidth : minHeight
    }

    @inline(__always)
    func maxDimension(by direction: FlexDirection) -> StyleValue {
        direction.isRow ? computedMaxWidth : computedMaxHeight
    }
}
