import CoreGraphics

/// ``FlexView`` 的布局选项，在 `layoutSubviews` 时使用。
@frozen
public struct FlexLayoutOptions: OptionSet {
    public let rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    @inlinable
    @inline(__always)
    public func resolve(by size: CGSize) -> (Double, Double) {
        let width = contains(.keepWidth) ? size.width : .nan
        let height = contains(.keepHeight) ? size.height : .nan
        return (width, height)
    }

    @inlinable
    @inline(__always)
    public func resolve(by rect: CGRect) -> (Double, Double) {
        let width = contains(.keepWidth) ? rect.width : .nan
        let height = contains(.keepHeight) ? rect.height : .nan
        return (width, height)
    }

    /// 确保宽度不变。
    public static let keepWidth = FlexLayoutOptions(rawValue: 1 << 0)
    /// 确保高度不变。
    public static let keepHeight = FlexLayoutOptions(rawValue: 1 << 1)
    /// 跳过自动布局。
    public static let skip = FlexLayoutOptions(rawValue: 0x80) // 128，最高位为 1

    /// 宽度和高度都自适应（可变）。
    public static var flexAll: FlexLayoutOptions {
        []
    }

    /// 确保宽度和高度都保持不变。
    public static var keepAll: FlexLayoutOptions {
        [.keepWidth, .keepHeight]
    }
}
