#if canImport(UIKit)

import UIKit

public struct AutoViews {
    let views: [UIView]
    
    public init(views: [UIView]) {
        self.views = views
    }
    
    @discardableResult
    public func horizontal(left: CGFloat = 0, right: CGFloat = 0, space: CGFloat = 0) -> [NSLayoutConstraint] {
        if views.count < 2, let first = views.first {
            return first.autoMake { maker in
                maker.left(inset: left)
                maker.right(inset: right)
            }
        }
        var lastView: UIView?
        let max = views.index(views.endIndex, offsetBy: -1)
        return views.flatMapIndexed { (view: UIView, index: Int) -> [NSLayoutConstraint] in
            if let last = lastView { // Second, third views...
                defer {
                    lastView = view
                }
                if index == max { // Last view
                    return view.autoMake { maker in
                        maker.right(inset: right)
                        maker.left(to: last, edge: .right, offset: space)
                        maker.width(match: last)
                    }
                } else {
                    return view.autoMake { maker in
                        maker.left(to: last, edge: .right, offset: space)
                        maker.width(match: last)
                    }
                }
            } else { // First view
                lastView = view
                return view.autoMake { maker in
                    maker.left(inset: left)
                }
            }
        }
    }

    @discardableResult
    public func horizontal(leading: CGFloat = 0, trailing: CGFloat = 0,
        space: CGFloat = 0) -> [NSLayoutConstraint] {
        if views.count < 2, let first = views.first {
            return first.autoMake { maker in
                maker.leading(inset: leading)
                maker.trailing(inset: trailing)
            }
        }
        var lastView: UIView?
        let max = views.index(views.endIndex, offsetBy: -1)
        return views.flatMapIndexed { (view: UIView, index: Int) -> [NSLayoutConstraint] in
            if let last = lastView { // Second, third views...
                lastView = view
                if index == max { // Last view
                    return view.autoMake { maker in
                        maker.trailing(inset: trailing)
                        maker.leading(to: last, edge: .trailing, offset: space)
                        maker.width(match: last)
                    }
                } else {
                    return view.autoMake { maker in
                        maker.leading(to: last, edge: .trailing, offset: space)
                        maker.width(match: last)
                    }
                }
            } else { // First view
                lastView = view
                return view.autoMake { maker in
                    maker.leading(inset: leading)
                }
            }
        }
    }

    @discardableResult
    public func vertical(top: CGFloat = 0, bottom: CGFloat = 0, space: CGFloat = 0) -> [NSLayoutConstraint] {
        if views.count < 2, let first = views.first {
            return first.autoMake { maker in
                maker.top(inset: top)
                maker.bottom(inset: bottom)
            }
        }
        var lastView: UIView?
        let max = views.index(views.endIndex, offsetBy: -1)
        return views.flatMapIndexed { (view: UIView, index: Int) -> [NSLayoutConstraint] in
            if let last = lastView { // Second, third views...
                lastView = view
                if index == max { // Last view
                    return view.autoMake { maker in
                        maker.bottom(inset: bottom)
                        maker.top(to: last, edge: .bottom, offset: space)
                        maker.height(match: last)
                    }
                } else {
                    return view.autoMake { maker in
                        maker.top(to: last, edge: .bottom, offset: space)
                        maker.height(match: last)
                    }
                }
            } else { // First view
                lastView = view
                return view.autoMake { maker in
                    maker.top(inset: top)
                }
            }
        }
    }
}

#endif // canImport(UIKit)
