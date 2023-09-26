#if canImport(UIKit)
import UIKit

open class FlexScrollView: UIScrollView, FlexViewContainer {
    public let flexLayout = FlexLayout()
    public let rootView = FlexView(frame: .zero)

    private var _layoutOptions: FlexLayoutOptions?

    /// `layoutSubviews` 时使用的布局参数。默认值是 ``FlexLayoutOptions.keepAll``。
    public var layoutOptions: FlexLayoutOptions {
        get {
            resolveLayoutOptions()
        }
        set {
            _layoutOptions = newValue
        }
    }

    public var flexViews: [FlexChildItem] {
        [FlexChildItem(view: rootView, layout: rootView.flexLayout)]
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        addSubview(rootView)
        flexLayout.overflow(.scroll)
        flexLayout.append(rootView.flexLayout)
    }

    open override var intrinsicContentSize: CGSize {
        FlexLogic.intrinsicSize(of: flexLayout)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        let options = resolveLayoutOptions()
        if options.contains(.skip) {
            // 跳过自动布局
            return
        }
        if flexLayout.parent != nil { // Layout 由 parent 进行
            contentSize = rootView.flexLayout.frame(left: 0, top: 0)
                .cgSize
            return
        }
        let (width, height) = options.resolve(by: frame)
        FlexLogic.doLayout(for: flexLayout, to: self, width: width, height: height)
        contentSize = rootView.flexLayout.frame(left: 0, top: 0)
            .cgSize
    }

    @inline(__always)
    private func resolveLayoutOptions() -> FlexLayoutOptions {
        _layoutOptions ?? .keepAll
    }

    public final func addFlexSubview(_ view: UIView, _ layout: FlexLayout) {
        rootView.addFlexSubview(view, layout)
    }

    public final func insertFlexSubview(_ view: UIView, _ layout: FlexLayout, at index: Int) {
        rootView.insertFlexSubview(view, layout, at: index)
    }

    public final func insertFlexSubview(_ view: UIView, _ layout: FlexLayout, above siblingSubview: UIView) {
        rootView.insertFlexSubview(view, layout, above: siblingSubview)
    }

    public final func insertFlexSubview(_ view: UIView, _ layout: FlexLayout, below siblingSubview: UIView) {
        rootView.insertFlexSubview(view, layout, below: siblingSubview)
    }

    public final func removeFlexSubview(_ view: UIView) {
        rootView.removeFlexSubview(view)
    }

    @inlinable
    @discardableResult
    public func addRow(children: (FlexView) -> Void) -> FlexView {
        rootView.addRow(children: children)
    }

    @inlinable
    @discardableResult
    public func addRow(style: (_ style: FlexLayout) -> Void, children: (FlexView) -> Void) -> FlexView {
        rootView.addRow(style: style, children: children)
    }

    @inlinable
    @discardableResult
    public func addColumn(children: (FlexView) -> Void) -> FlexView {
        rootView.addColumn(children: children)
    }

    @inlinable
    @discardableResult
    public func addColumn(style: (_ style: FlexLayout) -> Void, children: (FlexView) -> Void) -> FlexView {
        rootView.addColumn(style: style, children: children)
    }

    @inlinable
    public func addItem(_ view: FlexContainerView) {
        rootView.addItem(view)
    }

    @inlinable
    @discardableResult
    public func addItem<View>(_ view: View, style: (_ style: FlexLayout) -> Void) -> View where View: UIView {
        rootView.addItem(view, style: style)
    }

    @inlinable
    @discardableResult
    public func addItem<View>(_ view: View, style: (_ style: FlexLayout) -> Void, children: (View) -> Void) -> View
        where View: UIView {
        rootView.addItem(view, style: style, children: children)
    }

    public final func applyLayout(includeSelf: Bool = true, keepOrigin: Bool = true) {
        if keepOrigin {
            FlexLogic.applyLayout(of: flexLayout, to: self, left: Double(frame.minX), top: Double(frame.minY),
                includeSelf: includeSelf)
        } else {
            FlexLogic.applyLayout(of: flexLayout, to: self, left: 0.0, top: 0.0,
                includeSelf: includeSelf)
        }
    }

    public final func applyLayout(includeSelf: Bool = true, left: CGFloat, top: CGFloat) {
        FlexLogic.applyLayout(of: flexLayout, to: self, left: Double(left), top: Double(top),
            includeSelf: includeSelf)
    }

    public final func layout(options: FlexLayoutOptions) {
        let (width, height) = options.resolve(by: frame)
        FlexLogic.doLayout(for: flexLayout, to: self, width: width, height: height)
    }

    public final func layout(width: CGFloat = .nan, height: CGFloat = .nan) {
        FlexLogic.doLayout(for: flexLayout, to: self, width: width, height: height)
    }

    public final func calculateLayout(options: FlexLayoutOptions) -> CGSize {
        let (width, height) = options.resolve(by: frame)
        return FlexLogic.calculateLayout(of: flexLayout, width: width, height: height)
    }

    public final func calculateLayout(width: CGFloat = .nan, height: CGFloat = .nan) -> CGSize {
        FlexLogic.calculateLayout(of: flexLayout, width: width, height: height)
    }
}
#endif // canImport(UIKit)
