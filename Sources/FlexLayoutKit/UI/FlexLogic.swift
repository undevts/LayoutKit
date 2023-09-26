#if canImport(UIKit)
import UIKit

// Shared logic between `FlexView` and `FlexHolder`
struct FlexLogic {

    // MARK: Layout flex container.

    @inline(__always)
    static func intrinsicSize(of layout: FlexLayout) -> CGSize {
        layout.calculate()
        return CGSize(width: layout.box.width, height: layout.box.height)
    }

    @inline(__always)
    static func doLayout(for layout: FlexLayout, to view: UIView, width: CGFloat, height: CGFloat) {
        layout.calculate(width: Double(width), height: Double(height))
        applyLayout(of: layout, to: view, left: Double(view.frame.minX), top: Double(view.frame.minY))
    }

    @inline(__always)
    static func doLayout(for layout: FlexLayout, to view: UIView, children: [FlexChildItem],
        width: CGFloat, height: CGFloat) {
        layout.calculate(width: Double(width), height: Double(height))
        applyLayout(of: layout, to: view, children: children, left: Double(view.frame.minX), top: Double(view.frame.minY))
    }

    @inline(__always)
    static func doLayout<View>(for layout: FlexLayout, to view: View, width: CGFloat, height: CGFloat)
        where View: FlexContainerView {
        layout.calculate(width: Double(width), height: Double(height))
        applyLayout(of: layout, to: view, left: Double(view.frame.minX), top: Double(view.frame.minY))
    }

    @inline(__always)
    static func calculateLayout(of layout: FlexLayout, width: CGFloat, height: CGFloat) -> CGSize {
        layout.calculate(width: Double(width), height: Double(height))
        return CGSize(width: layout.box.width, height: layout.box.height)
    }

    @inline(__always)
    static func applyLayout(of layout: FlexLayout, to view: UIView, left: Double, top: Double,
        includeSelf: Bool = true) {
        precondition(pthread_main_np() == 1)
        if includeSelf {
            let frame = layout.frame(left: left, top: top)
            view.frame = frame.cgRect
        }
        if let container = view as? FlexViewContainer {
            for child in container.flexViews {
                applyLayout(of: child.layout, to: child.view, left: 0, top: 0)
            }
        } else if !layout.children.isEmpty {
            for child in view.subviews {
                if let layout = child._flexLayout {
                    applyLayout(of: layout, to: child, children: [], left: 0, top: 0)
                }
            }
        }
    }

    @inline(__always)
    static func applyLayout(of layout: FlexLayout, to view: UIView, children: [FlexChildItem],
        left: Double, top: Double) {
        precondition(pthread_main_np() == 1)
        let frame = layout.frame(left: left, top: top)
        view.frame = frame.cgRect
        for child in children {
            applyLayout(of: child.layout, to: child.view, left: 0, top: 0)
        }
    }

    @inline(__always)
    static func applyLayout<View>(of layout: FlexLayout, to view: View, left: Double, top: Double)
        where View: FlexContainerView {
        precondition(pthread_main_np() == 1)
        let frame = layout.frame(left: left, top: top)
        view.frame = frame.cgRect
        for child in view.flexViews {
            applyLayout(of: child.layout, to: child.view, left: 0, top: 0)
        }
    }

    // MARK: Add items to flex container.

    @inline(__always)
    static func addFlexSubview(_ view: UIView, _ layout: FlexLayout, of parent: UIView, flexLayout: FlexLayout) {
        parent.addSubview(view)
        view._flexLayout = layout
        flexLayout.append(layout)
    }

    @inline(__always)
    static func insertFlexSubview(_ view: UIView, _ layout: FlexLayout, of parent: UIView, flexLayout: FlexLayout,
        at index: Int) {
        parent.insertSubview(view, at: index)
        view._flexLayout = layout
        flexLayout.insert(layout, at: index)
    }

    @inline(__always)
    static func insertFlexSubview(_ view: UIView, _ layout: FlexLayout, of parent: UIView, flexLayout: FlexLayout,
        above siblingSubview: UIView) {
        parent.insertSubview(view, aboveSubview: siblingSubview)
        view._flexLayout = layout
        if let flex = siblingSubview._flexLayout,
           var index = flexLayout.children.firstIndex(of: flex) {
            index += 1
            if index < flexLayout.children.count {
                flexLayout.insert(layout, at: index)
            } else {
                flexLayout.append(layout)
            }
        } else {
            flexLayout.append(layout)
        }
    }

    @inline(__always)
    static func insertFlexSubview(_ view: UIView, _ layout: FlexLayout, of parent: UIView, flexLayout: FlexLayout,
        below siblingSubview: UIView) {
        parent.insertSubview(view, belowSubview: siblingSubview)
        view._flexLayout = layout
        if let flex = siblingSubview._flexLayout, let index = flexLayout.children.firstIndex(of: flex) {
            flexLayout.insert(layout, at: index)
        } else {
            flexLayout.append(layout)
        }
    }

    @inline(__always)
    static func removeFlexSubview(_ view: UIView, of parent: UIView) {
        guard view.superview == parent else {
            return
        }
        // assert(view._flexLayout != nil)
        view.removeFromSuperview()
        view._flexLayout?.removeFromParent()
    }

    @inline(__always)
    static func addFlexSubview(_ view: UIView, _ layout: FlexLayout, of parent: UIView, flexLayout: FlexLayout,
        children: inout [FlexChildItem]) {
        addFlexSubview(view, layout, of: parent, flexLayout: flexLayout)
        children.append(FlexChildItem(view: view, layout: layout))
    }

    @inline(__always)
    static func insertFlexSubview(_ view: UIView, _ layout: FlexLayout, of parent: UIView, flexLayout: FlexLayout,
        children: inout [FlexChildItem], at index: Int) {
        insertFlexSubview(view, layout, of: parent, flexLayout: flexLayout, at: index)
        children.append(FlexChildItem(view: view, layout: layout))
    }

    @inline(__always)
    static func insertFlexSubview(_ view: UIView, _ layout: FlexLayout, of parent: UIView, flexLayout: FlexLayout,
        children: inout [FlexChildItem], above siblingSubview: UIView) {
        insertFlexSubview(view, layout, of: parent, flexLayout: flexLayout, above: siblingSubview)
        children.append(FlexChildItem(view: view, layout: layout))
    }

    @inline(__always)
    static func insertFlexSubview(_ view: UIView, _ layout: FlexLayout, of parent: UIView, flexLayout: FlexLayout,
        children: inout [FlexChildItem], below siblingSubview: UIView) {
        insertFlexSubview(view, layout, of: parent, flexLayout: flexLayout, below: siblingSubview)
        children.append(FlexChildItem(view: view, layout: layout))
    }

    @inline(__always)
    static func removeFlexSubview(_ view: UIView, of parent: UIView, children: inout [FlexChildItem]) {
        guard view.superview == parent else {
            return
        }
        // assert(view._flexLayout != nil)
        view.removeFromSuperview()
        let index = children.firstIndex { child in
            child == view
        }
#if DEBUG
        assert(index != nil)
#endif
        if let index = index {
            children.remove(at: index)
                .layout
                .removeFromParent()
        }
    }
}
#endif // canImport(UIKit)
