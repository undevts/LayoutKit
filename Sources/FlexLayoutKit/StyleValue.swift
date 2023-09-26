import CoreGraphics // For CGFloat

/// A value representing various size unit.
@frozen
public enum StyleValue: Equatable, CustomStringConvertible {
    /// Defines the size unit as an absolute value.
    case length(Double)
    /// Defines the size unit as an percentage value.
    case percentage(Double)
    /// The flexbox will calculate and select a proper value.
    case auto

    @inlinable
    public init(from value: Double) {
        self = value.isNaN ? StyleValue.auto : StyleValue.length(value)
    }

    @_transparent
    var valid: Bool {
        switch self {
        case let .length(value), let .percentage(value):
            return !value.isNaN
        default:
            return true
        }
    }

    /// A short cut for `.percentage(100)`.
    @inlinable
    @inline(__always)
    public static var match: StyleValue {
        StyleValue.percentage(100)
    }

    /// A short cut for `.length(0.0)`.
    @inlinable
    @inline(__always)
    public static var zero: StyleValue {
        StyleValue.length(0.0)
    }

    // YGResolveValue
    @inlinable
    public func resolve(by value: Double) -> Double {
        switch self {
        case .auto:
            return Double.nan
        case let .length(l):
            return l
        case let .percentage(p):
            return p * value * 0.01
        }
    }

    func isDefined(size: Double) -> Bool {
        switch self {
        case .auto:
            return false
        case let .length(value):
            return !value.isNaN && value >= 0.0
        case let .percentage(value):
            return !value.isNaN && !size.isNaN && value >= 0.0
        }
    }

    static func makeLength(_ value: Double?) -> StyleValue? {
        guard let v = value else {
            return nil
        }
        return StyleValue.length(v)
    }

    // MARK: Equatable
    public static func ==(lhs: StyleValue, rhs: StyleValue) -> Bool {
        switch (lhs, rhs) {
        case (.auto, .auto):
            return true
        case (let .length(a), let .length(b)), (let .percentage(a), let .percentage(b)):
            return isDoubleEqual(a, to: b)
        default:
            return false
        }
    }

    public static func +(lhs: StyleValue, rhs: StyleValue) -> StyleValue {
        switch (lhs, rhs) {
        case (.auto, .auto):
            return .auto
        case (let .length(a), let .length(b)):
            return .length(a + b)
        case (let .percentage(a), let .percentage(b)):
            return .percentage(a + b)
        default: // error
            return .length(0)
        }
    }

    public static func -(lhs: StyleValue, rhs: StyleValue) -> StyleValue {
        switch (lhs, rhs) {
        case (.auto, .auto):
            return .auto
        case (let .length(a), let .length(b)):
            return .length(a - b)
        case (let .percentage(a), let .percentage(b)):
            return .percentage(a - b)
        default: // error
            return .length(0)
        }
    }

    // MARK: CustomStringConvertible
    public var description: String {
        switch self {
        case .auto:
            return "auto"
        case let .length(l):
            return "\(l)p" // point
        case let .percentage(p):
            return "\(p)%"
        }
    }
}
