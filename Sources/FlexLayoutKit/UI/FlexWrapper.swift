#if canImport(UIKit)
import UIKit

@frozen
public struct FlexWrapper: FlexViewContainerBase {
    public let view: UIView
    public let flexLayout: FlexLayout

    @usableFromInline
    init(view: UIView) {
        self.view = view
        flexLayout = FlexLayout()
        view._flexLayout = flexLayout
    }

    public func addFlexSubview(_ view: UIView, _ layout: FlexLayout) {
        FlexLogic.addFlexSubview(view, layout, of: self.view, flexLayout: flexLayout)
    }

    public func insertFlexSubview(_ view: UIView, _ layout: FlexLayout, at index: Int) {
        FlexLogic.insertFlexSubview(view, layout, of: self.view, flexLayout: flexLayout,
            at: index)
    }

    public func insertFlexSubview(_ view: UIView, _ layout: FlexLayout, above siblingSubview: UIView) {
        FlexLogic.insertFlexSubview(view, layout, of: self.view, flexLayout: flexLayout,
            above: siblingSubview)
    }

    public func insertFlexSubview(_ view: UIView, _ layout: FlexLayout, below siblingSubview: UIView) {
        FlexLogic.insertFlexSubview(view, layout, of: self.view, flexLayout: flexLayout,
            below: siblingSubview)
    }

    public func removeFlexSubview(_ view: UIView) {
        FlexLogic.removeFlexSubview(view, of: self.view)
    }
}
#endif // canImport(UIKit)
