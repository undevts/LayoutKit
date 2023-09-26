#if canImport(UIKit)

import UIKit

extension UIView {
    /// Adds a view to the end of the receiver’s list of subviews
    /// and configures the constraints for the view.
    ///
    /// This method establishes a strong reference to view
    ///  and sets its next responder to the receiver, which is its new superview.
    ///
    /// Views can have only one superview. If `view` already has a superview and that view is not the receiver,
    /// this method removes the previous superview before making the receiver its new superview.
    ///
    /// - Parameters:
    ///   - view: The view to be added. After being added,
    ///   this view appears on top of any other subviews.
    ///   - make: The scope within which you can build up the constraints which you wish to apply to the view.
    /// - Returns: Newly created constraints.
    @discardableResult
    public func addSubview(_  view: UIView, make: (_ maker: AutoMaker) -> Void) -> [NSLayoutConstraint] {
        self.addSubview(view)
        let maker = AutoMaker(for: view)
        make(maker)
        return maker.install()
    }

    /// Inserts a subview at the specified index and configures the constraints for the view.
    ///
    /// This method establishes a strong reference to `view` and sets its next responder to the receiver,
    /// which is its new superview.
    ///
    /// Views can have only one superview. If `view` already has a superview and that view is not the receiver,
    /// this method removes the previous superview before making the receiver its new superview.
    ///
    /// - Parameters:
    ///   - view: The view to insert.
    ///   - index: The index in the array of the `subviews` property at which to insert the view.
    ///   Subview indices start at `0` and cannot be greater than the number of subviews.
    ///   - make: The scope within which you can build up the constraints which you wish to apply to the view.
    /// - Returns: Newly created constraints.
    @discardableResult
    public func insertSubview(_  view: UIView, at index: Int,
        make: (_ maker: AutoMaker) -> Void) -> [NSLayoutConstraint] {
        self.insertSubview(view, at: index)
        let maker = AutoMaker(for: view)
        make(maker)
        return maker.install()
    }

    /// Inserts a view above another view in the view hierarchy.
    ///
    /// - Parameters:
    ///   - view: The view to insert.
    ///   It’s removed from its superview if it’s not a sibling of `siblingSubview`.
    ///   - other: The sibling view that will be behind the inserted view.
    ///   - make: The scope within which you can build up the constraints which you wish to apply to the view.
    /// - Returns: Newly created constraints.
    @discardableResult
    public func insertSubview(_  view: UIView, above other: UIView,
        make: (_ maker: AutoMaker) -> Void) -> [NSLayoutConstraint] {
        self.insertSubview(view, aboveSubview: other)
        let maker = AutoMaker(for: view)
        make(maker)
        return maker.install()
    }

    /// Inserts a view below another view in the view hierarchy.
    ///
    /// - Parameters:
    ///   - view: The view to insert below another view.
    ///   It’s removed from its superview if it’s not a sibling of `siblingSubview`.
    ///   - other: The sibling view that will be above the inserted view.
    ///   - make: The scope within which you can build up the constraints which you wish to apply to the view.
    /// - Returns: Newly created constraints.
    @discardableResult
    public func insertSubview(_  view: UIView, below other: UIView,
        make: (_ maker: AutoMaker) -> Void) -> [NSLayoutConstraint] {
        self.insertSubview(view, belowSubview: other)
        let maker = AutoMaker(for: view)
        make(maker)
        return maker.install()
    }

    /// Adds constraints in the view.
    ///
    /// - Parameter make: The scope within which you can build up the constraints which you wish to apply to the view.
    /// - Returns: Newly created constraints.
    @discardableResult
    public func autoMake(_ make: (_ maker: AutoMaker) -> Void) -> [NSLayoutConstraint] {
        let maker = AutoMaker(for: self)
        make(maker)
        return maker.install()
    }

    /// Updates constraints in the view.
    ///
    /// - Parameter make: The scope within which you can build up the constraints which you wish to apply to the view.
    /// - Returns: Newly created constraints.
    @discardableResult
    @available(*, deprecated, renamed:"autoUpdate(in:_:)")
    public func autoUpdate(_ make: (_ maker: AutoMaker) -> Void) -> [NSLayoutConstraint] {
        autoUpdate(constraints: [], make)
    }

    /// Updates constraints in the view.
    ///
    /// - Parameters:
    ///  - constraints: The list constraints that should be updated.
    ///  - make: The scope within which you can build up the constraints which you wish to apply to the view.
    /// - Returns: Newly created constraints.
    @objc(autoUpdateWithConstraints:make:)
    @discardableResult
    @available(*, deprecated, renamed:"autoUpdate(in:_:)")
    public func autoUpdate(constraints: [NSLayoutConstraint],
        _ make: (_ maker: AutoMaker) -> Void) -> [NSLayoutConstraint] {
        let maker = AutoMaker(for: self, mode: .update, existed: constraints)
        make(maker)
        return maker.install()
    }

    /// Updates constraints in the view.
    ///
    /// - Parameters:
    ///   - constraints: The list constraints that should be updated.
    ///   - make: The scope within which you can build up the constraints which you wish to apply to the view.
    public func autoUpdate(in constraints: inout [NSLayoutConstraint], _ make: (_ maker: AutoMaker) -> Void) {
        let maker = AutoMaker(for: self, mode: .update, existed: constraints)
        make(maker)
        constraints = maker.install()
    }

    /// 专门给 Objective-C 调用的方法，请不要直接使用。
    @objc(_autoUpdateWithConstraints:make:)
    public func _autoUpdate(constraints: [NSLayoutConstraint],
        _ make: (_ maker: AutoMaker) -> Void) -> [NSLayoutConstraint] {
        let maker = AutoMaker(for: self, mode: .update, existed: constraints)
        make(maker)
        return maker.install()
    }

    /// Removes all old constraints and adds new constraints in the view.
    ///
    /// - Parameters:
    ///   - constraints: The list constraints that should be removed.
    ///   - make: The scope within which you can build up the constraints
    //    which you wish to apply to the view.
    /// - Returns: Newly created constraints.
    @objc(autoRemakeWithConstraints:make:)
    @discardableResult
    public func autoRemake(constraints: [NSLayoutConstraint],
        _ make: (_ maker: AutoMaker) -> Void) -> [NSLayoutConstraint] {
        constraints.forEach { $0.isActive = false }
        let maker = AutoMaker(for: self, mode: .remake)
        make(maker)
        return maker.install()
    }
}

#endif // canImport(UIKit)
