#if canImport(UIKit)
import UIKit

open class FlexView: UIView, FlexViewContainer {
    public let flexLayout = FlexLayout()
    public private(set) var flexViews: [FlexChildItem] = []

    private var _layoutOptions: FlexLayoutOptions?

    /// `layoutSubviews` 时使用的布局参数。默认值是 ``FlexLayoutOptions.keepWidth``。
    public var layoutOptions: FlexLayoutOptions {
        get {
            resolveLayoutOptions()
        }
        set {
            _layoutOptions = newValue
        }
    }

    open override var intrinsicContentSize: CGSize {
#if DEBUG
        let size = FlexLogic.intrinsicSize(of: flexLayout)
//        print(#fileID, #function, size, self)
        return size
#else
        FlexLogic.intrinsicSize(of: flexLayout)
#endif
    }

    open override func sizeToFit() {
        FlexLogic.doLayout(for: flexLayout, to: self, width: .nan, height: .nan)
    }

    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        let width = size.width < 1.0 ? CGFloat.nan : size.width
        let height = size.height < 1.0 ? CGFloat.nan : size.height
        return FlexLogic.calculateLayout(of: flexLayout, width: width, height: height)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        if flexLayout.parent != nil { // Layout 由 parent 进行
            return
        }
        let options = resolveLayoutOptions()
        if options.contains(.skip) {
            // 跳过自动布局
            return
        }
        let (width, height) = options.resolve(by: frame)
#if DEBUG
        let old = frame
        FlexLogic.doLayout(for: flexLayout, to: self, width: width, height: height)
        let current = frame
//        print(#fileID, #function, old, current, self)
//        flexLayout.debugPrint()
        assert(old == current || old != current) // Disable warning
#else
        FlexLogic.doLayout(for: flexLayout, to: self, width: width, height: height)
#endif
    }

    @inline(__always)
    private func resolveLayoutOptions() -> FlexLayoutOptions {
        _layoutOptions ?? .keepWidth
    }

    public final func addFlexSubview(_ view: UIView, _ layout: FlexLayout) {
        FlexLogic.addFlexSubview(view, layout, of: self, flexLayout: flexLayout,
            children: &flexViews)
    }

    public final func insertFlexSubview(_ view: UIView, _ layout: FlexLayout, at index: Int) {
        FlexLogic.insertFlexSubview(view, layout, of: self, flexLayout: flexLayout, children: &flexViews, at: index)
    }

    public final func insertFlexSubview(_ view: UIView, _ layout: FlexLayout, above siblingSubview: UIView) {
        FlexLogic.insertFlexSubview(view, layout, of: self, flexLayout: flexLayout,
            children: &flexViews, above: siblingSubview)
    }

    public final func insertFlexSubview(_ view: UIView, _ layout: FlexLayout, below siblingSubview: UIView) {
        FlexLogic.insertFlexSubview(view, layout, of: self, flexLayout: flexLayout,
            children: &flexViews, below: siblingSubview)
    }

    public final func removeFlexSubview(_ view: UIView) {
        FlexLogic.removeFlexSubview(view, of: self, children: &flexViews)
    }

    public final func applyLayout(includeSelf: Bool = true, keepOrigin: Bool = true) {
        if keepOrigin {
            FlexLogic.applyLayout(of: flexLayout, to: self, left: Double(frame.minX),
                top: Double(frame.minY), includeSelf: includeSelf)
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
