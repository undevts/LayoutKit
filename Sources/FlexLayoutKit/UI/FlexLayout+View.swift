#if canImport(UIKit)
import UIKit
import FlexLayoutCore

extension UIView {
    @usableFromInline
    var _flexLayout: FlexLayout? {
        get {
            self.associatedObject(key: &FLEX_LAYOUT_KEY)
        }
        set {
            self.setAssociatedObject(key: &FLEX_LAYOUT_KEY, object: newValue)
        }
    }

    public func markDirty() {
        _flexLayout?.markDirty()
    }

    public func removeFromFlexView() {
        if let parent = superview as? FlexViewContainer {
            parent.removeFlexSubview(self)
        } else {
            removeFromSuperview()
        }
    }
}

#endif
