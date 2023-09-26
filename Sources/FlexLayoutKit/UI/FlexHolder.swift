#if canImport(UIKit)
import UIKit

/// 用于把一个 `UIView` 包装成 Flex 容器，比较适合用于自定义的 `UITableViewCell` 和 `UICollectionViewCell`。
public final class FlexHolder: FlexViewContainer {
    public let view: UIView
    public let flexLayout: FlexLayout
    public private(set) var flexViews: [FlexChildItem] = []

    public init(view: UIView, flexLayout: FlexLayout? = nil) {
        self.view = view
        self.flexLayout = flexLayout ?? FlexLayout()
        view._flexLayout = flexLayout
    }

    public var intrinsicContentSize: CGSize {
        FlexLogic.intrinsicSize(of: flexLayout)
    }

    public func layoutSubviews() {
        if flexLayout.parent != nil { // Layout 由 parent 进行
            return
        }
        FlexLogic.doLayout(for: flexLayout, to: view, children: flexViews,
            width: view.frame.width, height: view.frame.height)
    }

    public func addFlexSubview(_ view: UIView, _ layout: FlexLayout) {
        FlexLogic.addFlexSubview(view, layout, of: self.view, flexLayout: flexLayout,
            children: &flexViews)
    }

    public func insertFlexSubview(_ view: UIView, _ layout: FlexLayout, at index: Int) {
        FlexLogic.insertFlexSubview(view, layout, of: self.view, flexLayout: flexLayout,
            children: &flexViews, at: index)
    }

    public func insertFlexSubview(_ view: UIView, _ layout: FlexLayout, above siblingSubview: UIView) {
        FlexLogic.insertFlexSubview(view, layout, of: self.view, flexLayout: flexLayout,
            children: &flexViews, above: siblingSubview)
    }

    public func insertFlexSubview(_ view: UIView, _ layout: FlexLayout, below siblingSubview: UIView) {
        FlexLogic.insertFlexSubview(view, layout, of: self.view, flexLayout: flexLayout,
            children: &flexViews, below: siblingSubview)
    }

    public func removeFlexSubview(_ view: UIView) {
        FlexLogic.removeFlexSubview(view, of: self.view, children: &flexViews)
    }

    public final func applyLayout(includeSelf: Bool = true, keepOrigin: Bool = true) {
        if keepOrigin {
            FlexLogic.applyLayout(of: flexLayout, to: view, left: Double(view.frame.minX),
                top: Double(view.frame.minY), includeSelf: includeSelf)
        } else {
            FlexLogic.applyLayout(of: flexLayout, to: view, left: 0.0, top: 0.0,
                includeSelf: includeSelf)
        }
    }

    public final func applyLayout(includeSelf: Bool = true, left: CGFloat, top: CGFloat) {
        FlexLogic.applyLayout(of: flexLayout, to: view, left: Double(left), top: Double(top),
            includeSelf: includeSelf)
    }

    public final func layout(options: FlexLayoutOptions) {
        let width = options.contains(.keepWidth) ? view.frame.width : .nan
        let height = options.contains(.keepWidth) ? view.frame.height : .nan
        FlexLogic.doLayout(for: flexLayout, to: view, width: width, height: height)
    }

    public final func layout(width: CGFloat = .nan, height: CGFloat = .nan) {
        FlexLogic.doLayout(for: flexLayout, to: view, width: width, height: height)
    }

    public final func calculateLayout(options: FlexLayoutOptions) -> CGSize {
        let width = options.contains(.keepWidth) ? view.frame.width : .nan
        let height = options.contains(.keepWidth) ? view.frame.height : .nan
        return FlexLogic.calculateLayout(of: flexLayout, width: width, height: height)
    }

    public final func calculateLayout(width: CGFloat = .nan, height: CGFloat = .nan) -> CGSize {
        FlexLogic.calculateLayout(of: flexLayout, width: width, height: height)
    }
}
#endif // canImport(UIKit)
