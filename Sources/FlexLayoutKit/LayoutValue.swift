import CoreGraphics

public struct Size: Equatable, CustomStringConvertible {
    public let width: Double
    public let height: Double

    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }

    public init(cgSize: CGSize) {
        self.init(width: Double(cgSize.width), height: Double(cgSize.height))
    }

    public var ceiled: Size {
        Size(width: ceil(width), height: ceil(height))
    }

    public var floored: Size {
        Size(width: floor(width), height: floor(height))
    }

    public var rounded: Size {
        Size(width: round(width), height: round(height))
    }

    var isZero: Bool {
        width == 0 && height == 0
    }

    // MARK: - CustomStringConvertible
    public var description: String {
        "Size(\(width), \(height))"
    }

    public static var zero: Size {
        Size(width: 0, height: 0)
    }

    public static func ==(lhs: Size, rhs: Size) -> Bool {
        isDoubleEqual(lhs.width, to: rhs.width) && isDoubleEqual(lhs.height, to: rhs.height)
    }
}

public struct Point: Equatable {
    public let x: Double
    public let y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public init(cgPoint: CGPoint) {
        self.init(x: Double(cgPoint.x), y: Double(cgPoint.y))
    }

    public var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
    }

    public static var zero: Point {
        Point(x: 0, y: 0)
    }

    public static func ==(lhs: Point, rhs: Point) -> Bool {
        isDoubleEqual(lhs.x, to: rhs.x) && isDoubleEqual(lhs.y, to: rhs.y)
    }
}

@frozen
public struct Rect: Equatable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    @inlinable
    @inline(__always)
    public var size: Size {
        Size(width: width, height: height)
    }

    @inlinable
    @inline(__always)
    public var cgSize: CGSize {
        CGSize(width: width, height: height)
    }

    @inlinable
    @inline(__always)
    public var cgRect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }

    @inline(__always)
    var valid: Rect {
        Rect(x: x.isNaN ? 0 : x, y: y.isNaN ? 0 : y,
            width: width.isNaN ? 0 : width, height: height.isNaN ? 0 : height)
    }

    @inlinable
    @inline(__always)
    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    @inlinable
    @inline(__always)
    public init(origin: Point, size: Size) {
        self.init(x: origin.x, y: origin.y, width: size.width, height: size.height)
    }

    @inlinable
    @inline(__always)
    public var minX: Double {
        x
    }

    @inlinable
    @inline(__always)
    public var midX: Double {
        x + width / 2
    }

    @inlinable
    @inline(__always)
    public var maxX: Double {
        x + width
    }

    @inlinable
    @inline(__always)
    public var minY: Double {
        y
    }

    @inlinable
    @inline(__always)
    public var midY: Double {
        y + width / 2
    }

    @inlinable
    @inline(__always)
    public var maxY: Double {
        y + width
    }

    public func contains(point: Point) -> Bool {
        guard width > 0 && height > 0 else {
            return false
        }
        let px = point.x
        let py = point.y
        let maxX = x + width
        let maxY = y + height
        return x <= px && px <= maxX && y <= py && py <= maxY
    }

    public func contains(point: CGPoint) -> Bool {
        guard width > 0 && height > 0 else {
            return false
        }
        let px = Double(point.x)
        let py = Double(point.y)
        let maxX = x + width
        let maxY = y + height
        return x <= px && px <= maxX && y <= py && py <= maxY
    }

    @inlinable
    public func setSize(_ value: Size) -> Rect {
        Rect(x: x, y: y, width: value.width, height: value.height)
    }

    @inlinable
    public func setSize(width: Double, height: Double) -> Rect {
        Rect(x: x, y: y, width: width, height: height)
    }

    @inlinable
    public func setOrigin(_ value: Point) -> Rect {
        Rect(x: value.x, y: value.y, width: width, height: height)
    }

    @inlinable
    public func setOrigin(x: Double, y: Double) -> Rect {
        Rect(x: x, y: y, width: width, height: height)
    }

    @inlinable
    public func setWidth(_ value: Double) -> Rect {
        Rect(x: x, y: y, width: value, height: height)
    }

    @inlinable
    public func setHeight(_ value: Double) -> Rect {
        Rect(x: x, y: y, width: width, height: value)
    }

    @inlinable
    public func setX(_ value: Double) -> Rect {
        Rect(x: value, y: y, width: width, height: height)
    }

    @inlinable
    public func setY(_ value: Double) -> Rect {
        Rect(x: x, y: value, width: width, height: height)
    }

    public static let zero = Rect(x: 0.0, y: 0.0, width: 0.0, height: 0.0)

    public static func ==(lhs: Rect, rhs: Rect) -> Bool {
        isDoubleEqual(lhs.x, to: rhs.x) && isDoubleEqual(lhs.y, to: rhs.y) &&
            isDoubleEqual(lhs.width, to: rhs.width) && isDoubleEqual(lhs.height, to: rhs.height)
    }
}
