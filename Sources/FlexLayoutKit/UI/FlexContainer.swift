#if canImport(UIKit)
import UIKit

public protocol FlexContainer {
    var flexLayout: FlexLayout { get }
}

extension FlexContainer {
    @inlinable
    @discardableResult
    public func flexStyle(_ style: (_ style: FlexLayout) -> Void) -> Self {
        style(flexLayout)
        return self
    }

    public func flexStyle(of view: UIView, _ style: (_ style: FlexLayout) -> Void) {
        if let container = view as? FlexContainer {
            style(container.flexLayout)
            return
        }
        precondition(view._flexLayout != nil)
        if let layout = view._flexLayout {
            style(layout)
        }
    }
}

#endif // canImport(UIKit)
