import Darwin.C
import CoreSwift

#if SWIFT_PACKAGE
import FlexLayoutCore
#endif

public struct FlexBox {
    // gCurrentGenerationCount
    static var totalGeneration: UInt32 = 0

    public internal(set) var position: LayoutPosition = LayoutPosition.zero

    // dimensions
    public internal(set) var width: Double = Double.nan
    public internal(set) var height: Double = Double.nan

    public internal(set) var margin: LayoutInsets = LayoutInsets.zero
    public internal(set) var border: LayoutInsets = LayoutInsets.zero
    public internal(set) var padding: LayoutInsets = LayoutInsets.zero

    private var storage = FlexLayoutStorage()

    // Instead of recomputing the entire layout every single time, we cache some
    // information to break early when nothing changed.
    var generation: UInt32 = 0 // generationCount
    var computedFlexBasis: Double = Double.nan

    // measuredDimensions
    public internal(set) var measuredWidth: Double = Double.nan
    public internal(set) var measuredHeight: Double = Double.nan

    var lastParentDirection: Direction?
    var cachedLayout: LayoutCache? // performLayout == true
    var cachedMeasurements: [LayoutCache] = [] // performLayout == false

    mutating func invalidate() {
        self = FlexBox()
    }

    // YGNodeIsLayoutDimDefined
    @inline(__always)
    func isLayoutDimensionDefined(for direction: FlexDirection) -> Bool {
        measuredDimension(for: direction) >= 0.0
    }

    mutating func setLeadingPosition(for direction: FlexDirection, size: Double) {
        switch direction {
        case .column:
            position.top = size
        case .columnReverse:
            position.bottom = size
        case .row:
            position.left = size
        case .rowReverse:
            position.right = size
        }
    }

    mutating func setTrailingPosition(for direction: FlexDirection, size: Double) {
        switch direction {
        case .column:
            position.bottom = size
        case .columnReverse:
            position.top = size
        case .row:
            position.right = size
        case .rowReverse:
            position.left = size
        }
    }

    // YGRoundToPixelGrid
    mutating func roundPosition(scale: Double, left absoluteLeft: Double, top absoluteTop: Double,
        textLayout: Bool) -> (Double, Double) {
        let nodeLeft = left
        let nodeTop = top
        let nodeWidth = width
        let nodeHeight = height

        let absoluteLeft = absoluteLeft + nodeLeft
        let absoluteTop = absoluteTop + nodeTop
        let absoluteRight = absoluteLeft + nodeWidth
        let absoluteBottom = absoluteTop + nodeHeight

        position.left = FlexBox.round(nodeLeft, scale: scale, ceil: false, floor: textLayout)
        position.top = FlexBox.round(nodeTop, scale: scale, ceil: false, floor: textLayout)

        let fractionalWidth = !(fmod(nodeWidth * scale, 1.0).isApproximatelyEqual(to: 0)) &&
            !(fmod(nodeWidth * scale, 1.0).isApproximatelyEqual(to: 1.0))
        let fractionalHeight = !(fmod(nodeHeight * scale, 1.0).isApproximatelyEqual(to: 0)) &&
            !(fmod(nodeHeight * scale, 1.0).isApproximatelyEqual(to: 1.0))

        width = FlexBox.round(absoluteRight, scale: scale, ceil: (textLayout && fractionalWidth),
            floor: (textLayout && !fractionalWidth)) -
            FlexBox.round(absoluteLeft, scale: scale, ceil: false, floor: textLayout)
        height = FlexBox.round(absoluteBottom, scale: scale, ceil: (textLayout && fractionalHeight),
            floor: (textLayout && !fractionalHeight)) -
            FlexBox.round(absoluteTop, scale: scale, ceil: false, floor: textLayout)
        return (absoluteLeft, absoluteTop)
    }

    func measuredDimension(for direction: FlexDirection) -> Double {
        direction.isRow ? measuredWidth : measuredHeight
    }

    mutating func setMeasuredDimension(for direction: FlexDirection, size: Double) {
        if direction.isRow {
            measuredWidth = size
        } else {
            measuredHeight = size
        }
    }

    // YGRoundValueToPixelGrid
    static func round(_ value: Double, scale: Double, ceil: Bool, floor: Bool) -> Double {
        var value = value * scale
        // We want to calculate `fractial` such that `floor(scaledValue) = scaledValue - fractial`.
        var remainder = value.remainder(dividingBy: 1.0) // aka: fractial
        if remainder < 0.0 {
            // This branch is for handling negative numbers for `value`.
            //
            // Regarding `floor` and `ceil`. Note that for a number x, `floor(x) <= x <=
            // ceil(x)` even for negative numbers. Here are a couple of examples:
            //   - x =  2.2: floor( 2.2) =  2, ceil( 2.2) =  3
            //   - x = -2.2: floor(-2.2) = -3, ceil(-2.2) = -2
            //
            // Regarding `fmodf`. For fractional negative numbers, `fmodf` returns a
            // negative number. For example, `fmodf(-2.2) = -0.2`. However, we want
            // `fractial` to be the number such that subtracting it from `value` will
            // give us `floor(value)`. In the case of negative numbers, adding 1 to
            // `fmodf(value)` gives us this. Let's continue the example from above:
            //   - fractial = fmodf(-2.2) = -0.2
            //   - Add 1 to the fraction: fractial2 = fractial + 1 = -0.2 + 1 = 0.8
            //   - Finding the `floor`: -2.2 - fractial2 = -2.2 - 0.8 = -3
            remainder += 1.0
        }
        if isDoubleEqual(remainder, to: 0.0) {
            // First we check if the value is already rounded
            value = value - remainder
        } else if isDoubleEqual(remainder, to: 1.0) || ceil {
            // Next we check if we need to use forced rounding
            value = value - remainder + 1.0
        } else if floor {
            value = value - remainder
        } else {
            // Finally, we just round the value
            value = value - remainder +
                ((!remainder.isNaN && (remainder > 0.5 || isDoubleEqual(remainder, to: 0.5))) ? 1.0 : 0.0)
        }
        return (scale.isNaN || scale.isNaN) ? Double.nan : value / scale
    }
}

extension FlexBox {
    @inline(__always)
    public var top: Double {
        position.top
    }

    @inline(__always)
    public var bottom: Double {
        position.bottom
    }

    @inline(__always)
    public var left: Double {
        position.left
    }

    @inline(__always)
    public var right: Double {
        position.right
    }

    var direction: Direction {
        get {
            Direction(rawValue: storage.direction)!
        }
        set {
            storage.direction = newValue.rawValue
        }
    }

    var hasOverflow: Bool {
        get {
            storage.hasOverflow
        }
        set {
            storage.hasOverflow = newValue
        }
    }
}
