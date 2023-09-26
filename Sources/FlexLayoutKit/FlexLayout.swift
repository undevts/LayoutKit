import CoreSwift

#if SWIFT_PACKAGE
import FlexLayoutCore
#endif

public typealias FlexMeasureMethod = (_ layout: FlexLayout, _ width: Double, _ widthMode: MeasureMode,
    _  height: Double, _ heightMode: MeasureMode) -> Size
public typealias FlexBaselineMethod = (_ layout: FlexLayout, _ width: Double, _  height: Double) -> Double
public typealias FlexPrintMethod = (_ layout: FlexLayout) -> Void

public final class FlexLayout: Hashable {
    public let configuration: FlexConfiguration
    public private(set) weak var parent: FlexLayout?
    public private(set) var children: [FlexLayout] = []
    public internal(set) var style: FlexStyle = FlexStyle()
    public internal(set) var box: FlexBox = FlexBox()

    var storage = FlexNodeStorage()
    var _measure: FlexMeasureMethod?
    var _baseline: FlexBaselineMethod?
    var lineIndex = 0

    // resolvedDimensions
    var resolvedWidth: StyleValue = StyleValue.auto
    var resolvedHeight: StyleValue = StyleValue.auto

    public init(configuration: FlexConfiguration = FlexConfiguration.default) {
        self.configuration = configuration
    }

//    deinit { // TODO: remove self
//        parent?._remove(self)
//        parent = nil
//    }

    // YGNodeMarkDirty
    public func markDirty() {
        // Only a layout with measure function should manually mark self dirty
        assert(hasMeasureMethod,
            "Only leaf nodes with custom measure functions should manually mark themselves as dirty")
        _markDirty()
    }

    // markDirtyAndPropogate
    func _markDirty() {
        if isDirty {
            return
        }
        isDirty = true
        box.computedFlexBasis = Double.nan
        parent?._markDirty()
    }

    public func invalidate() {
        box.invalidate()
    }

    public func copyStyle(from other: FlexLayout) {
        if style != other.style {
            style = other.style
            _markDirty()
        }
    }

    func copy(from other: FlexLayout) {
        children = other.children
        storage = other.storage
        _measure = other._measure
        _baseline = other._baseline
        style = other.style
        box = other.box
        lineIndex = other.lineIndex
        resolvedWidth = other.resolvedWidth
        resolvedHeight = other.resolvedHeight
    }

    // YGNodeClone
    public func copy() -> FlexLayout {
        let layout = FlexLayout(configuration: configuration)
        layout.copy(from: self)
        layout.parent = nil
        return layout
    }

    public func copyChildrenIfNeeded() {
        forEachChildAfterCloning()
    }

    // iterChildrenAfterCloningIfNeeded
    func forEachChildAfterCloning(_ method: ((FlexLayout) -> Void)? = nil) {
        children = children.map { item in
            if item.parent === self {
                method?(item)
                return item
            } else {
                let child = item.copy()
                child.parent = self
                method?(child)
                return child
            }

        }
    }

    public func frame(left: Double, top: Double) -> Rect {
        Rect(x: left + box.left, y: top + box.top, width: box.width, height: box.height)
    }

    // MARK: - Managing Child layouts
    public func append(_ child: FlexLayout) {
        assert(child.parent == nil, "Child already has a owner, it must be removed first.")
        children.append(child)
        child.parent = self
        _markDirty()
    }

    // YGNodeInsertChild
    public func insert(_ child: FlexLayout, at index: Int) {
        assert(child.parent == nil, "Child already has a owner, it must be removed first.")
        children.insert(child, at: index)
        child.parent = self
        _markDirty()
    }

    public func replace<C>(_ subrange: Range<Int>, with newNodes: C) where C.Element == FlexLayout, C: Collection {
        guard subrange.lowerBound > -1 && subrange.upperBound <= children.count else {
            return
        }
        let old: ArraySlice<FlexLayout> = children[subrange]
        old.forEach { layout in
            layout.invalidate()
            layout.parent = nil
        }
        children.replaceSubrange(subrange, with: newNodes)
        newNodes.forEach { new in
            new.parent = self
        }
        _markDirty()
    }

    public func replace(at index: Int, with node: FlexLayout) {
        guard let old = children.at(index) else {
            return
        }
        children.replace(at: index, with: node)
        old.invalidate()
        old.parent = nil
        node.parent = self
        _markDirty()
    }

    public func replaceAll<C>(_ newNodes: C) where C.Element == FlexLayout, C: Collection {
        replace(0..<children.count, with: newNodes)
    }

    // YGNodeRemoveChild
    public func remove(_ child: FlexLayout) {
        guard !children.isEmpty else {
            // This is an empty set. Nothing to remove.
            return
        }
        // Children may be shared between parents, which is indicated by not having an owner.
        // We only want to reset the child completely if it is owned exclusively by one node.
        let parent = child.parent
        if _remove(child) {
            if self == parent {
                child.box.invalidate()
                child.parent = nil
            }
            _markDirty()
        }
    }

    // YGNode::removeChild
    @discardableResult
    func _remove(_ child: FlexLayout) -> Bool {
        children.removeFirst(of: child) != nil
    }

    // YGNodeRemoveAllChildren
    public func removeAll() {
        guard !children.isEmpty else {
            return
        }
        if let first = children.first, first.parent == self {
            // If the first child has this node as its parent, we assume that this child set is unique.
            for child in children {
                child.box.invalidate()
                child.parent = nil
            }
        }
        // Otherwise, we are not the owner of the child set. We don't have to do anything to clear it.
        children.removeAll()
        _markDirty()
    }

    public func removeFromParent() {
        parent?.remove(self)
    }

    public func child(at index: Int) -> FlexLayout? {
        guard index > -1 && index < children.count else {
            return nil
        }
        return children[index]
    }

    @discardableResult
    public func append(to layout: FlexLayout) -> Self {
        layout.append(self)
        return self
    }

    // YGNodeCalculateLayout, YGNodeCalculateLayoutWithContext
    public func calculate(width: Double = .nan, height: Double = .nan, direction: Direction = .ltr) {
        FlexBox.totalGeneration += 1
        resolveDimensions()
        let (_width, widthMode) = layoutMode(size: width, resolvedSize: resolvedWidth,
            maxSize: style.computedMaxWidth, direction: .row)
        let (_height, heightMode) = layoutMode(size: height, resolvedSize: resolvedHeight,
            maxSize: style.computedMaxHeight, direction: .column)
        let success = layoutInternal(width: _width, height: _height, widthMode: widthMode, heightMode: heightMode,
            parentWidth: width, parentHeight: height, direction: direction, layout: true, reason: .initial)
        if success {
            setPosition(for: style.direction, main: width, cross: height, width: width)
            roundPosition(scale: FlexStyle.scale, absoluteLeft: 0, absoluteTop: 0)
        }
    }

    // YGBaseline
    func baseline() -> Double {
        if hasBaselineMethod {
            return baseline(width: box.measuredWidth, height: box.measuredHeight)
        }
        var baselineChild: FlexLayout?
        for child: FlexLayout in children {
            if child.lineIndex > 0 {
                break
            }
            if child.style.absoluteLayout {
                continue
            }
            if computedAlignItem(child: child) == AlignItems.baseline || child.isReferenceBaseline {
                baselineChild = child
                break
            }
            if baselineChild == nil {
                baselineChild = child
            }
        }
        if let child = baselineChild {
            return child.baseline() + child.box.position.top
        } else {
            return box.measuredHeight
        }
    }

    @inline(__always)
    func computedDimension(by direction: FlexDirection) -> StyleValue {
        direction.isRow ? resolvedWidth : resolvedHeight
    }

    // YGNodeIsStyleDimDefined
    @inline(__always)
    func isDimensionDefined(for direction: FlexDirection, size: Double) -> Bool {
        computedDimension(by: direction)
            .isDefined(size: size)
    }

    // MARK: Equatable
    @inlinable
    public static func ==(lhs: FlexLayout, rhs: FlexLayout) -> Bool {
        lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        let value = withUnsafePointer(to: self) { pointer in
            Int(bitPattern: pointer)
        }
        hasher.combine(value)
    }
}

extension FlexLayout {
    public var hasNewLayout: Bool {
        get {
            storage.hasNewLayout
        }
        set {
            storage.hasNewLayout = newValue
        }
    }

    public var layoutType: LayoutType {
        get {
            LayoutType(rawValue: storage.nodeType)!
        }
        set {
            storage.nodeType = newValue.rawValue
        }
    }

    var isReferenceBaseline: Bool {
        get {
            storage.isReferenceBaseline
        }
        set {
            storage.isReferenceBaseline = newValue
        }
    }

    var isDirty: Bool {
        get {
            storage.isDirty
        }
        set {
            storage.isDirty = newValue
        }
    }

    // YGNode::resolveFlexGrow
    var computedFlexGrow: Double {
        // Root nodes flexGrow should always be 0
        (parent == nil || style.flex.grow.isNaN) ? 0.0 : style.flex.grow
    }

    // YGNode::resolveFlexShrink
    var computedFlexShrink: Double {
        // Root nodes flexShrink should always be 0
        (parent == nil || style.flex.shrink.isNaN) ? 0.0 : style.flex.shrink
    }

    // YGNode::isNodeFlexible
    var flexible: Bool {
        style.positionType != .absolute && (computedFlexGrow != 0.0 || computedFlexShrink != 0.0)
    }

    // YGIsBaselineLayout
    var isBaselineLayout: Bool {
        if style.flexDirection.isColumn {
            return false
        }
        if style.alignItems == AlignItems.baseline {
            return true
        }
        for child in children {
            if !child.style.absoluteLayout && child.style.alignSelf == AlignSelf.baseline {
                return true
            }
        }
        return false
    }

    @inline(__always)
    var hasMeasureMethod: Bool {
        _measure != nil
    }

    @inline(__always)
    var hasBaselineMethod: Bool {
        _baseline != nil
    }

    // YGNode::measure
    func measure(width: Double, widthMode: MeasureMode, height: Double, heightMode: MeasureMode) -> Size {
// #if DEBUG
//        if let method = _measure {
//            let size = method(self, width, widthMode, height, heightMode)
//            print(#fileID, #function, self, size)
//            return size
//        }
//        return Size.zero
// #else
        _measure?(self, width, widthMode, height, heightMode) ?? Size.zero
// #endif
    }

    // YGNode::baseline
    func baseline(width: Double, height: Double) -> Double {
        _baseline?(self, width, height) ?? 0.0
    }
}
