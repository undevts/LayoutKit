#if canImport(UIKit)
import UIKit
import CoreSwift

public typealias FlexContainerView = FlexViewContainer & UIView

public protocol FlexViewContainerBase: FlexContainer {
    func addFlexSubview(_ view: UIView, _ layout: FlexLayout)

    func insertFlexSubview(_ view: UIView, _ layout: FlexLayout, at index: Int)

    func insertFlexSubview(_ view: UIView, _ layout: FlexLayout, above siblingSubview: UIView)

    func insertFlexSubview(_ view: UIView, _ layout: FlexLayout, below siblingSubview: UIView)

    func removeFlexSubview(_ view: UIView)

    @discardableResult
    func addRow(children: (FlexView) -> Void) -> FlexView

    @discardableResult
    func addRow(style: (_ style: FlexLayout) -> Void, children: (FlexView) -> Void) -> FlexView

    @discardableResult
    func addColumn(children: (FlexView) -> Void) -> FlexView

    @discardableResult
    func addColumn(style: (_ style: FlexLayout) -> Void, children: (FlexView) -> Void) -> FlexView

    func addItem(_ view: FlexContainerView)

    @discardableResult
    func addItem<View>(_ view: View, style: (_ style: FlexLayout) -> Void) -> View where View: UIView

    @discardableResult
    func addItem<View>(_ view: View, style: (_ style: FlexLayout) -> Void,
        children: (View) -> Void) -> View where View: UIView
}

public protocol FlexViewContainer: FlexViewContainerBase {
    // for applyLayout
    var flexViews: [FlexChildItem] { get }

    func applyLayout(includeSelf: Bool, keepOrigin: Bool)
    func applyLayout(includeSelf: Bool, left: CGFloat, top: CGFloat)
    func layout(options: FlexLayoutOptions)
    func layout(width: CGFloat, height: CGFloat)
    func calculateLayout(options: FlexLayoutOptions) -> CGSize
    func calculateLayout(width: CGFloat, height: CGFloat) -> CGSize
}

extension FlexViewContainerBase {
    @inlinable
    @discardableResult
    public func addRow(children: (FlexView) -> Void) -> FlexView {
        let child = FlexView(frame: .zero)
        child.flexLayout.flexDirection(.row)
        return addItem(child, style: Function.nothing, children: children)
    }

    @inlinable
    @discardableResult
    public func addRow(style: (_ style: FlexLayout) -> Void, children: (FlexView) -> Void) -> FlexView {
        let child = FlexView(frame: .zero)
        child.flexLayout.flexDirection(.row)
        return addItem(child, style: style, children: children)
    }

    @inlinable
    @discardableResult
    public func addColumn(children: (FlexView) -> Void) -> FlexView {
        let child = FlexView(frame: .zero)
        child.flexLayout.flexDirection(.column)
        return addItem(child, style: Function.nothing, children: children)
    }

    @inlinable
    @discardableResult
    public func addColumn(style: (_ style: FlexLayout) -> Void, children: (FlexView) -> Void) -> FlexView {
        let child = FlexView(frame: .zero)
        child.flexLayout.flexDirection(.column)
        return addItem(child, style: style, children: children)
    }

    @inlinable
    public func addItem(_ view: FlexContainerView) {
        addFlexSubview(view, view.flexLayout)
    }

    @inlinable
    @discardableResult
    public func addItem<View>(_ view: View, style: (_ style: FlexLayout) -> Void) -> View where View: UIView {
        let layout = resolveFlexLayout(view: view)
        addFlexSubview(view, layout)
        style(layout)
        return view
    }

    @inlinable
    @discardableResult
    public func addItem<View>(_ view: View, style: (_ style: FlexLayout) -> Void,
        children: (_ view: View) -> Void) -> View where View: UIView {
        let layout = resolveFlexLayout(view: view)
        addFlexSubview(view, layout)
        style(layout)
        children(view)
        return view
    }

    @inlinable
    public func addItem(wrapped view: UIView, style: (_ style: FlexLayout) -> Void,
        children: (_ wrapper: FlexWrapper) -> Void) {
        let wrapper = FlexWrapper(view: view)
        addFlexSubview(view, wrapper.flexLayout)
        style(wrapper.flexLayout)
        children(wrapper)
    }
}

@inlinable
@inline(__always)
func resolveFlexLayout(view: UIView) -> FlexLayout {
    if let container = view as? FlexContainer {
        return container.flexLayout
    } else if let old = view._flexLayout {
        return old
    } else {
        let layout = FlexLayout()
        view._flexLayout = layout
        return layout
    }
}

#endif // canImport(UIKit)
