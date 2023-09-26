#if canImport(UIKit)
import UIKit

public struct FlexChildItem: Hashable {
    public let view: UIView
    public let layout: FlexLayout

    public init(view: UIView, layout: FlexLayout) {
        self.view = view
        self.layout = layout
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(view)
    }

    public static func ==(lhs: FlexChildItem, rhs: FlexChildItem) -> Bool {
        lhs.view == rhs.view
    }

    public static func ==(lhs: FlexChildItem, rhs: UIView) -> Bool {
        lhs.view == rhs
    }

    public static func ==(lhs: UIView, rhs: FlexChildItem) -> Bool {
        lhs == rhs.view
    }
}
#endif // canImport(UIKit)
