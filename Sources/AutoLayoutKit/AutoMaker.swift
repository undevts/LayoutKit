#if canImport(UIKit)

import UIKit
import CoreSwift

@frozen
@usableFromInline
enum AutoMode {
    case make
    case update
    case remake
}

/// A maker helps us to create constraints.
public final class AutoMaker: NSObject {
    @usableFromInline
    let view: UIView

    @usableFromInline
    let mode: AutoMode

    @usableFromInline
    private(set) var constraints: [NSLayoutConstraint] = []

    @usableFromInline
    private(set) var existedConstraints: [NSLayoutConstraint]

    @inlinable
    init(for view: UIView, mode: AutoMode = AutoMode.make,
        existed constraints: [NSLayoutConstraint] = []) {
        self.view = view
        self.mode = mode
        existedConstraints = constraints
        view.translatesAutoresizingMaskIntoConstraints = false
    }

    @inlinable
    func install() -> [NSLayoutConstraint] {
        let array = constraints
        constraints.removeAll()
        defer {
            (view.superview ?? view).setNeedsUpdateConstraints()
        }
        if mode == AutoMode.update {
            var next = array.compactMap(update(constraint:))
            next.append(contentsOf: existedConstraints)
            return next
        } else {
            return array.map(install(constraint:))
        }
    }

    @usableFromInline
    func install(constraint: NSLayoutConstraint) -> NSLayoutConstraint {
        assert(mode == .make || mode == .remake)
//        constraint.priority = .required
        constraint.isActive = true
        return constraint
    }

    @usableFromInline
    func update(constraint: NSLayoutConstraint) -> NSLayoutConstraint? {
        assert(mode == .update)
        let old = existedConstraints.first { next in
            (next is AutoConstraint) &&
                next.firstAttribute == constraint.firstAttribute &&
                next.secondAttribute == constraint.secondAttribute &&
                next.firstItem === constraint.firstItem &&
                next.secondItem === constraint.secondItem &&
                next.relation == constraint.relation &&
                abs(next.multiplier - constraint.multiplier) < 0.01
        }
        if let t = old {
            t.constant = constraint.constant
            t.isActive = true
            return nil
        } else {
//            constraint.priority = .required
            constraint.isActive = true
            return constraint
        }
    }

    @inline(__always)
    @inlinable
    func _autoEdge(_ edge: AutoEdge, of view: UIView, to other: UIView?, other attribute: AutoAttribute,
        offset: CGFloat, x multiplier: CGFloat, by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        let constraint = AutoConstraint(item: view, attribute: edge.attribute, relatedBy: relation,
            toItem: other, attribute: attribute.attribute, multiplier: multiplier, constant: offset)
        constraints.append(constraint)
        return constraint
    }

    @inline(__always)
    @inlinable
    func _autoSafeEdge(_ edge: AutoEdge, of view: UIView, to other: UIView?, edge otherEdge: AutoEdge,
        offset: CGFloat, by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        view.translatesAutoresizingMaskIntoConstraints = false
        // NSLayoutXAxisAnchor 与 NSLayoutYAxisAnchor 不能用同一个类型记录，必须分开
        let leftX: NSLayoutXAxisAnchor?
        let leftY: NSLayoutYAxisAnchor?
        let rightX: NSLayoutXAxisAnchor?
        let rightY: NSLayoutYAxisAnchor?
        if #available(iOS 11.0, *) {
            switch edge {
            case .left, .leftMargin:
                leftX = view.safeAreaLayoutGuide.leftAnchor
                leftY = nil
            case .right, .rightMargin:
                leftX = view.safeAreaLayoutGuide.rightAnchor
                leftY = nil
            case .top, .topMargin:
                leftX = nil
                leftY = view.safeAreaLayoutGuide.topAnchor
            case .bottom, .bottomMargin:
                leftX = nil
                leftY = view.safeAreaLayoutGuide.bottomAnchor
            case .leading, .leadingMargin:
                leftX = view.safeAreaLayoutGuide.leadingAnchor
                leftY = nil
            case .trailing, .trailingMargin:
                leftX = view.safeAreaLayoutGuide.trailingAnchor
                leftY = nil
            }
            switch otherEdge {
            case .left, .leftMargin:
                rightX = other?.safeAreaLayoutGuide.leftAnchor
                rightY = nil
            case .right, .rightMargin:
                rightX = other?.safeAreaLayoutGuide.rightAnchor
                rightY = nil
            case .top, .topMargin:
                rightX = nil
                rightY = other?.safeAreaLayoutGuide.topAnchor
            case .bottom, .bottomMargin:
                rightX = nil
                rightY = other?.safeAreaLayoutGuide.bottomAnchor
            case .leading, .leadingMargin:
                rightX = other?.safeAreaLayoutGuide.leadingAnchor
                rightY = nil
            case .trailing, .trailingMargin:
                rightX = other?.safeAreaLayoutGuide.trailingAnchor
                rightY = nil
            }
        } else {
            switch edge {
            case .left, .leftMargin:
                leftX = view.leftAnchor
                leftY = nil
            case .right, .rightMargin:
                leftX = view.rightAnchor
                leftY = nil
            case .top, .topMargin:
                leftX = nil
                leftY = view.topAnchor
            case .bottom, .bottomMargin:
                leftX = nil
                leftY = view.bottomAnchor
            case .leading, .leadingMargin:
                leftX = view.leadingAnchor
                leftY = nil
            case .trailing, .trailingMargin:
                leftX = view.trailingAnchor
                leftY = nil
            }
            switch otherEdge {
            case .left, .leftMargin:
                rightX = other?.leftAnchor
                rightY = nil
            case .right, .rightMargin:
                rightX = other?.rightAnchor
                rightY = nil
            case .top, .topMargin:
                rightX = nil
                rightY = other?.topAnchor
            case .bottom, .bottomMargin:
                rightX = nil
                rightY = other?.bottomAnchor
            case .leading, .leadingMargin:
                rightX = other?.leadingAnchor
                rightY = nil
            case .trailing, .trailingMargin:
                rightX = other?.trailingAnchor
                rightY = nil
            }
        }
        assert(leftX != nil || leftY != nil) // 二者不能同时为 nil
        assert(rightX != nil || rightY != nil) // 二者不能同时为 nil
        // NSLayoutXAxisAnchor 只能与 NSLayoutXAxisAnchor 操作
        precondition((leftX != nil && rightX != nil) || leftY != nil)
        // NSLayoutYAxisAnchor 只能与 NSLayoutYAxisAnchor 操作
        precondition((leftY != nil && rightY != nil) || leftX != nil)
        if let left = leftX, let right = rightX {
            let constraint: NSLayoutConstraint
            switch relation {
            case .lessThanOrEqual:
                constraint = left.constraint(lessThanOrEqualTo: right, constant: offset)
            case .equal:
                constraint = left.constraint(equalTo: right, constant: offset)
            case .greaterThanOrEqual:
                constraint = left.constraint(greaterThanOrEqualTo: right, constant: offset)
            @unknown default:
                constraint = NSLayoutConstraint()
            }
            constraint.isActive = true
            constraints.append(constraint)
            return constraint
        }
        if let left = leftY, let right = rightY {
            let constraint: NSLayoutConstraint
            switch relation {
            case .lessThanOrEqual:
                constraint = left.constraint(lessThanOrEqualTo: right, constant: offset)
            case .equal:
                constraint = left.constraint(equalTo: right, constant: offset)
            case .greaterThanOrEqual:
                constraint = left.constraint(greaterThanOrEqualTo: right, constant: offset)
            @unknown default:
                constraint = NSLayoutConstraint()
            }
            constraint.isActive = true
            constraints.append(constraint)
            return constraint
        }
        return NSLayoutConstraint()
    }

    @inline(__always)
    @inlinable
    func _autoGuideEdge(_ edge: AutoEdge, of view: UIView, to other: UILayoutSupport, edge otherEdge: AutoEdge,
        offset: CGFloat, x multiplier: CGFloat, by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        view.translatesAutoresizingMaskIntoConstraints = false
        let constraint = NSLayoutConstraint(item: view, attribute: edge.attribute, relatedBy: relation,
            toItem: other, attribute: otherEdge.attribute, multiplier: multiplier, constant: offset)
        constraint.isActive = true
        constraints.append(constraint)
        return constraint
    }

    @inline(__always)
    @inlinable
    func _autoDimension(_ dimension: AutoDimension, of view: UIView, to other: UIView?, offset: CGFloat,
        x multiplier: CGFloat, by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        let constraint = AutoConstraint(item: view, attribute: dimension.attribute, relatedBy: relation,
            toItem: other, attribute: other == nil ? .notAnAttribute : dimension.attribute,
            multiplier: multiplier, constant: offset)
        constraints.append(constraint)
        return constraint
    }

    @inline(__always)
    @inlinable
    func _autoDimension(first: AutoDimension, second: AutoDimension, of view: UIView, offset: CGFloat,
        x multiplier: CGFloat, by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        view.translatesAutoresizingMaskIntoConstraints = false
        let constraint = AutoConstraint(item: view, attribute: first.attribute, relatedBy: relation,
            toItem: view, attribute: second.attribute, multiplier: multiplier, constant: offset)
        constraints.append(constraint)
        return constraint
    }

    @inline(__always)
    @inlinable
    func _autoAxis(_ axis: AutoAxis, of view: UIView, to other: UIView?, axis otherAxis: AutoAxis,
        offset: CGFloat, x multiplier: CGFloat, by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        let constraint = AutoConstraint(item: view, attribute: axis.attribute, relatedBy: relation,
            toItem: other, attribute: otherAxis.attribute, multiplier: multiplier, constant: offset)
        constraints.append(constraint)
        return constraint
    }

    // MARK: - Auto Pin to Super View Edges

    /// Sets the left inset with the superview to `0`.
    ///
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func left() -> NSLayoutConstraint {
        edge(.left, toSuper: .left, inset: 0, by: .equal)
    }

    /// Sets the left inset with the superview to inset.
    ///
    /// - Parameters:
    ///   - inset: The value of the inset.
    /// - Returns: A newly created constraint.
    @objc(leftInset:)
    @inlinable
    @discardableResult
    public func left(inset: CGFloat) -> NSLayoutConstraint {
        edge(.left, toSuper: .left, inset: inset, by: .equal)
    }

    /// Sets the left inset with the superview to inset, also set the relationship.
    ///
    /// - Parameters:
    ///   - inset: The value of the inset.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @objc(leftInset:by:)
    @inlinable
    @discardableResult
    public func left(inset: CGFloat, by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        edge(.left, toSuper: .left, inset: inset, by: relation)
    }

    /// Sets the right inset with the superview to `0`.
    ///
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func right() -> NSLayoutConstraint {
        edge(.right, toSuper: .right, inset: 0, by: .equal)
    }

    /// Sets the right inset with the superview to inset.
    ///
    /// - Parameters:
    ///   - inset: The value of the inset.
    /// - Returns: A newly created constraint.
    @objc(rightInset:)
    @inlinable
    @discardableResult
    public func right(inset: CGFloat) -> NSLayoutConstraint {
        edge(.right, toSuper: .right, inset: inset, by: .equal)
    }

    /// Sets the right inset with the superview to inset, also set the relationship.
    ///
    /// - Parameters:
    ///   - inset: The value of the inset.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @objc(rightInset:by:)
    @inlinable
    @discardableResult
    public func right(inset: CGFloat, by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        edge(.right, toSuper: .right, inset: inset, by: relation)
    }

    /// Sets the top inset with the superview to `0`.
    ///
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func top() -> NSLayoutConstraint {
        edge(.top, toSuper: .top, inset: 0, by: .equal)
    }

    /// Sets the top inset with the superview to inset.
    ///
    /// - Parameters:
    ///   - inset: The value of the inset.
    /// - Returns: A newly created constraint.
    @objc(topInset:)
    @inlinable
    @discardableResult
    public func top(inset: CGFloat) -> NSLayoutConstraint {
        edge(.top, toSuper: .top, inset: inset, by: .equal)
    }

    /// Sets the top inset with the superview to inset, also set the relationship.
    ///
    /// - Parameters:
    ///   - inset: The value of the inset.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @objc(topInset:by:)
    @inlinable
    @discardableResult
    public func top(inset: CGFloat, by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        edge(.top, toSuper: .top, inset: inset, by: relation)
    }

    /// Sets the bottom inset with the superview to `0`.
    ///
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func bottom() -> NSLayoutConstraint {
        edge(.bottom, toSuper: .bottom, inset: 0, by: .equal)
    }

    /// Sets the bottom inset with the superview to inset.
    ///
    /// - Parameters:
    ///   - inset: The value of the inset.
    /// - Returns: A newly created constraint.
    @objc(bottomInset:)
    @inlinable
    @discardableResult
    public func bottom(inset: CGFloat) -> NSLayoutConstraint {
        edge(.bottom, toSuper: .bottom, inset: inset, by: .equal)
    }

    /// Sets the bottom inset with the superview to inset, also set the relationship.
    ///
    /// - Parameters:
    ///   - inset: The value of the inset.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @objc(bottomInset:by:)
    @inlinable
    @discardableResult
    public func bottom(inset: CGFloat, by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        edge(.bottom, toSuper: .bottom, inset: inset, by: relation)
    }

    /// Sets the leading inset with the superview to `0`.
    ///
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func leading() -> NSLayoutConstraint {
        edge(.leading, toSuper: .leading, inset: 0, by: .equal)
    }

    /// Sets the leading inset with the superview to inset.
    ///
    /// - Parameters:
    ///   - inset: The value of the inset.
    /// - Returns: A newly created constraint.
    @objc(leadingInset:)
    @inlinable
    @discardableResult
    public func leading(inset: CGFloat) -> NSLayoutConstraint {
        edge(.leading, toSuper: .leading, inset: inset, by: .equal)
    }

    /// Sets the leading inset with the superview to inset, also set the relationship.
    ///
    /// - Parameters:
    ///   - inset: The value of the inset.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @objc(leadingInset:by:)
    @inlinable
    @discardableResult
    public func leading(inset: CGFloat, by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        edge(.leading, toSuper: .leading, inset: inset, by: relation)
    }

    /// Sets the trailing inset with the superview to `0`.
    ///
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func trailing() -> NSLayoutConstraint {
        edge(.trailing, toSuper: .trailing, inset: 0, by: .equal)
    }

    /// Sets the trailing inset with the superview to inset.
    ///
    /// - Parameters:
    ///   - inset: The value of the inset.
    /// - Returns: A newly created constraint.
    @objc(trailingInset:)
    @inlinable
    @discardableResult
    public func trailing(inset: CGFloat) -> NSLayoutConstraint {
        edge(.trailing, toSuper: .trailing, inset: inset, by: .equal)
    }

    /// Sets the trailing inset with the superview to inset, also set the relationship.
    ///
    /// - Parameters:
    ///   - inset: The value of the inset.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @objc(trailingInset:by:)
    @inlinable
    @discardableResult
    public func trailing(inset: CGFloat, by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        edge(.trailing, toSuper: .trailing, inset: inset, by: relation)
    }

    /// Creates a constraint that defines the relationship between the specified edges.
    ///
    /// The linear equation for this relationship is shown below:
    /// `view.edge = superview.edge + offset`.
    ///
    /// - Parameters:
    ///   - edge: The edge of self.
    ///   - otherEdge: The edge of super view.
    ///   - inset: The value of the inset.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func edge(_ edge: AutoEdge, toSuper otherEdge: AutoEdge, inset: CGFloat,
        by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        self.edge(edge, toSuper: otherEdge, inset: inset, x: 1, by: relation)
    }

    /// Creates a constraint that defines the relationship between the specified edges.
    ///
    /// The linear equation for this relationship is shown below:
    /// `view.edge = superview.edge × x + offset`.
    ///
    /// - Parameters:
    ///   - edge: The edge of self.
    ///   - otherEdge: The edge of super view.
    ///   - inset: The value of the inset.
    ///   - multiplier: The constant multiplied with the attribute on the superview of
    ///   the constraint as part of getting the modified attribute.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func edge(_ edge: AutoEdge, toSuper otherEdge: AutoEdge, inset: CGFloat, x multiplier: CGFloat,
        by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        precondition(view.superview != nil, "Super view cannot be nil")
        let offset: CGFloat
        let r: NSLayoutConstraint.Relation
        if edge.shouldInvert {
            offset = -inset
            switch relation {
            case .lessThanOrEqual:
                r = .greaterThanOrEqual
            case .greaterThanOrEqual:
                r = .lessThanOrEqual
            case .equal:
                fallthrough
            @unknown default:
                r = relation
            }
        } else {
            offset = inset
            r = relation
        }
        return _autoEdge(edge, of: view, to: view.superview, other: otherEdge, offset: offset, x: multiplier, by: r)
    }

    /// Sets the left inset and the right inset with the superview.
    ///
    /// - Parameter horizontal: The value of the constraints.
    /// - Returns: Newly created constraints.
    @objc(edgesHorizontal:)
    @inlinable
    @discardableResult
    public func edges(horizontal: CGFloat) -> [NSLayoutConstraint] {
        let _left = edge(.left, toSuper: .left, inset: horizontal, by: .equal)
        let _right = edge(.right, toSuper: .right, inset: horizontal, by: .equal)
        return [_left, _right]
    }

    /// Sets the top inset and the bottom inset with the superview.
    ///
    /// - Parameter vertical: The value of the constraints.
    /// - Returns: Newly created constraints.
    @objc(edgesVertical:)
    @inlinable
    @discardableResult
    public func edges(vertical: CGFloat) -> [NSLayoutConstraint] {
        let _top = edge(.top, toSuper: .top, inset: vertical, by: .equal)
        let _bottom = edge(.bottom, toSuper: .bottom, inset: vertical, by: .equal)
        return [_top, _bottom]
    }

    /// Sets all edge insets with the superview.
    ///
    /// - Parameters:
    ///   - horizontal: The value of the left inset and the right inset.
    ///   - vertical:  The value of the top inset and the bottom inset.
    /// - Returns: Newly created constraints.
    @objc(edgesHorizontal:vertical:)
    @inlinable
    @discardableResult
    public func edges(horizontal: CGFloat, vertical: CGFloat) -> [NSLayoutConstraint] {
        let _top = edge(.top, toSuper: .top, inset: vertical, by: .equal)
        let _left = edge(.left, toSuper: .left, inset: horizontal, by: .equal)
        let _bottom = edge(.bottom, toSuper: .bottom, inset: vertical, by: .equal)
        let _right = edge(.right, toSuper: .right, inset: horizontal, by: .equal)
        return [_top, _left, _bottom, _right]
    }

    /// Sets all edge insets with the superview.
    ///
    /// - Parameters:
    ///   - top: The value of the top inset.
    ///   - left: The value of the left inset.
    ///   - bottom: The value of the bottom inset.
    ///   - right: The value of the right inset.
    /// - Returns: Newly created constraints.
    @inlinable
    @discardableResult
    public func edges(top: CGFloat, left: CGFloat, bottom: CGFloat,
        right: CGFloat) -> [NSLayoutConstraint] {
        let _top = edge(.top, toSuper: .top, inset: top, by: .equal)
        let _left = edge(.left, toSuper: .left, inset: left, by: .equal)
        let _bottom = edge(.bottom, toSuper: .bottom, inset: bottom, by: .equal)
        let _right = edge(.right, toSuper: .right, inset: right, by: .equal)
        return [_top, _left, _bottom, _right]
    }

    /// Sets all edge insets with the superview.
    ///
    /// - Parameters:
    ///   - top: The value of the top inset.
    ///   - leading: The value of the leading inset.
    ///   - bottom: The value of the bottom inset.
    ///   - trailing: The value of the trailing inset.
    /// - Returns: Newly created constraints.
    @inlinable
    @discardableResult
    public func edges(top: CGFloat, leading: CGFloat, bottom: CGFloat,
        trailing: CGFloat) -> [NSLayoutConstraint] {
        let _top = edge(.top, toSuper: .top, inset: top, by: .equal)
        let _leading = edge(.leading, toSuper: .leading, inset: leading, by: .equal)
        let _bottom = edge(.bottom, toSuper: .bottom, inset: bottom, by: .equal)
        let _trailing = edge(.trailing, toSuper: .trailing, inset: trailing, by: .equal)
        return [_top, _leading, _bottom, _trailing]
    }

    /// Sets all edge insets with the superview without the specified edge.
    ///
    /// - Parameters:
    ///   - top: The value of the top inset.
    ///   - left: The value of the left inset.
    ///   - bottom: The value of the bottom inset.
    ///   - right: The value of the right inset.
    ///   - edge: The edge should skip setting.
    /// - Returns: Newly created constraints.
    @inlinable
    @discardableResult
    public func edges(top: CGFloat, left: CGFloat, bottom: CGFloat,
        right: CGFloat, except edge: AutoEdge) -> [NSLayoutConstraint] {
        let _top = edge == .top ? nil :
            self.edge(.top, toSuper: .top, inset: top, by: .equal)
        let _left = edge == .left ? nil :
            self.edge(.left, toSuper: .left, inset: left, by: .equal)
        let _bottom = edge == .bottom ? nil :
            self.edge(.bottom, toSuper: .bottom, inset: bottom, by: .equal)
        let _right = edge == .right ? nil :
            self.edge(.right, toSuper: .right, inset: right, by: .equal)
        return [_top, _left, _bottom, _right].compactMap(Function.identity)
    }

    /// Sets all edge insets with the superview without the specified edge.
    ///
    /// - Parameters:
    ///   - top: The value of the top inset.
    ///   - leading: The value of the leading inset.
    ///   - bottom: The value of the bottom inset.
    ///   - trailing: The value of the trailing inset.
    ///   - edge: The edge should skip setting.
    /// - Returns: Newly created constraints.
    @inlinable
    @discardableResult
    public func edges(top: CGFloat, leading: CGFloat, bottom: CGFloat,
        trailing: CGFloat, except edge: AutoEdge) -> [NSLayoutConstraint] {
        let _top = edge == .top ? nil :
            self.edge(.top, toSuper: .top, inset: top, by: .equal)
        let _leading = edge == .leading ? nil :
            self.edge(.leading, toSuper: .leading, inset: leading, by: .equal)
        let _bottom = edge == .bottom ? nil :
            self.edge(.bottom, toSuper: .bottom, inset: bottom, by: .equal)
        let _trailing = edge == .trailing ? nil :
            self.edge(.trailing, toSuper: .trailing, inset: trailing, by: .equal)
        return [_top, _leading, _bottom, _trailing].compactMap(Function.identity)
    }

    // MARK: - Auto Pin to Super View Edges with Margin

    /// Sets the left margin inset with the superview to `0`.
    ///
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func leftMargin() -> NSLayoutConstraint {
        edge(.leftMargin, toSuper: .leftMargin, inset: 0, by: .equal)
    }

    /// Sets the left margin inset with the superview to margin inset.
    ///
    /// - Parameters:
    ///   - inset: The value of the margin inset.
    /// - Returns: A newly created constraint.
    @objc(leftMarginInset:)
    @inlinable
    @discardableResult
    public func leftMargin(inset: CGFloat) -> NSLayoutConstraint {
        edge(.leftMargin, toSuper: .leftMargin, inset: inset, by: .equal)
    }

    /// Sets the left margin inset with the superview to margin inset, also set the relationship.
    ///
    /// - Parameters:
    ///   - inset: The value of the margin inset.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @objc(leftMarginInset:by:)
    @inlinable
    @discardableResult
    public func leftMargin(inset: CGFloat, by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        edge(.leftMargin, toSuper: .leftMargin, inset: inset, by: relation)
    }

    /// Sets the right margin inset with the superview to `0`.
    ///
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func rightMargin() -> NSLayoutConstraint {
        edge(.rightMargin, toSuper: .rightMargin, inset: 0, by: .equal)
    }

    /// Sets the right margin inset with the superview to margin inset.
    ///
    /// - Parameters:
    ///   - inset: The value of the margin inset.
    /// - Returns: A newly created constraint.
    @objc(rightMarginInset:)
    @inlinable
    @discardableResult
    public func rightMargin(inset: CGFloat) -> NSLayoutConstraint {
        edge(.rightMargin, toSuper: .rightMargin, inset: inset, by: .equal)
    }

    /// Sets the right margin inset with the superview to margin inset, also set the relationship.
    ///
    /// - Parameters:
    ///   - inset: The value of the margin inset.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @objc(rightMarginInset:by:)
    @inlinable
    @discardableResult
    public func rightMargin(inset: CGFloat, by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        edge(.rightMargin, toSuper: .rightMargin, inset: inset, by: relation)
    }

    /// Sets the top margin inset with the superview to `0`.
    ///
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func topMargin() -> NSLayoutConstraint {
        edge(.topMargin, toSuper: .topMargin, inset: 0, by: .equal)
    }

    /// Sets the top margin inset with the superview to margin inset.
    ///
    /// - Parameters:
    ///   - inset: The value of the margin inset.
    /// - Returns: A newly created constraint.
    @objc(topMarginInset:)
    @inlinable
    @discardableResult
    public func topMargin(inset: CGFloat) -> NSLayoutConstraint {
        edge(.topMargin, toSuper: .topMargin, inset: inset, by: .equal)
    }

    /// Sets the top margin inset with the superview to margin inset, also set the relationship.
    ///
    /// - Parameters:
    ///   - inset: The value of the margin inset.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @objc(topMarginInset:by:)
    @inlinable
    @discardableResult
    public func topMargin(inset: CGFloat, by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        edge(.topMargin, toSuper: .topMargin, inset: inset, by: relation)
    }

    /// Sets the bottom margin inset with the superview to `0`.
    ///
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func bottomMargin() -> NSLayoutConstraint {
        edge(.bottomMargin, toSuper: .bottomMargin, inset: 0, by: .equal)
    }

    /// Sets the bottom margin inset with the superview to margin inset.
    ///
    /// - Parameters:
    ///   - inset: The value of the margin inset.
    /// - Returns: A newly created constraint.
    @objc(bottomMarginInset:)
    @inlinable
    @discardableResult
    public func bottomMargin(inset: CGFloat) -> NSLayoutConstraint {
        edge(.bottomMargin, toSuper: .bottomMargin, inset: inset, by: .equal)
    }

    /// Sets the bottom margin inset with the superview to margin inset, also set the relationship.
    ///
    /// - Parameters:
    ///   - inset: The value of the margin inset.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @objc(bottomMarginInset:by:)
    @inlinable
    @discardableResult
    public func bottomMargin(inset: CGFloat, by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        edge(.bottomMargin, toSuper: .bottomMargin, inset: inset, by: relation)
    }

    /// Sets the leading margin inset with the superview to `0`.
    ///
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func leadingMargin() -> NSLayoutConstraint {
        edge(.leadingMargin, toSuper: .leadingMargin, inset: 0, by: .equal)
    }

    /// Sets the leading margin inset with the superview to margin inset.
    ///
    /// - Parameters:
    ///   - inset: The value of the margin inset.
    /// - Returns: A newly created constraint.
    @objc(leadingMarginInset:)
    @inlinable
    @discardableResult
    public func leadingMargin(inset: CGFloat) -> NSLayoutConstraint {
        edge(.leadingMargin, toSuper: .leadingMargin, inset: inset, by: .equal)
    }

    /// Sets the leading margin inset with the superview to margin inset, also set the relationship.
    ///
    /// - Parameters:
    ///   - inset: The value of the margin inset.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @objc(leadingMarginInset:by:)
    @inlinable
    @discardableResult
    public func leadingMargin(inset: CGFloat, by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        edge(.leadingMargin, toSuper: .leadingMargin, inset: inset, by: relation)
    }

    /// Sets the trailing margin inset with the superview to `0`.
    ///
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func trailingMargin() -> NSLayoutConstraint {
        edge(.trailingMargin, toSuper: .trailingMargin, inset: 0, by: .equal)
    }

    /// Sets the trailing margin inset with the superview to margin inset.
    ///
    /// - Parameters:
    ///   - inset: The value of the margin inset.
    /// - Returns: A newly created constraint.
    @objc(trailingMarginInset:)
    @inlinable
    @discardableResult
    public func trailingMargin(inset: CGFloat) -> NSLayoutConstraint {
        edge(.trailingMargin, toSuper: .trailingMargin, inset: inset, by: .equal)
    }

    /// Sets the trailing margin inset with the superview to margin inset, also set the relationship.
    ///
    /// - Parameters:
    ///   - inset: The value of the margin inset.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @objc(trailingMarginInset:by:)
    @inlinable
    @discardableResult
    public func trailingMargin(inset: CGFloat, by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        edge(.trailingMargin, toSuper: .trailingMargin, inset: inset, by: relation)
    }

    // MARK: - Auto Pin to Other View Edges

    /// Sets the left edge match the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func left(to other: UIView, edge otherEdge: AutoEdge) -> NSLayoutConstraint {
        edge(.left, to: other, edge: otherEdge, offset: 0, by: .equal)
    }

    /// Sets the distance between the left edge and the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func left(to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat) -> NSLayoutConstraint {
        edge(.left, to: other, edge: otherEdge, offset: offset, by: .equal)
    }

    /// Sets the distance between the left edge and the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func left(to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat,
        by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        edge(.left, to: other, edge: otherEdge, offset: offset, by: relation)
    }

    /// Sets the right edge match the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func right(to other: UIView, edge otherEdge: AutoEdge) -> NSLayoutConstraint {
        edge(.right, to: other, edge: otherEdge, offset: 0, by: .equal)
    }

    /// Sets the distance between the right edge and the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func right(to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat) -> NSLayoutConstraint {
        edge(.right, to: other, edge: otherEdge, offset: offset, by: .equal)
    }

    /// Sets the distance between the right edge and the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func right(to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat,
        by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        edge(.right, to: other, edge: otherEdge, offset: offset, by: relation)
    }

    /// Sets the top edge match the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func top(to other: UIView, edge otherEdge: AutoEdge) -> NSLayoutConstraint {
        edge(.top, to: other, edge: otherEdge, offset: 0, by: .equal)
    }

    /// Sets the distance between the top edge and the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func top(to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat) -> NSLayoutConstraint {
        edge(.top, to: other, edge: otherEdge, offset: offset, by: .equal)
    }

    /// Sets the distance between the top edge and the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func top(to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat,
        by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        edge(.top, to: other, edge: otherEdge, offset: offset, by: relation)
    }

    /// Sets the bottom edge match the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func bottom(to other: UIView, edge otherEdge: AutoEdge) -> NSLayoutConstraint {
        edge(.bottom, to: other, edge: otherEdge, offset: 0, by: .equal)
    }

    /// Sets the distance between the bottom edge and the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func bottom(to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat) -> NSLayoutConstraint {
        edge(.bottom, to: other, edge: otherEdge, offset: offset, by: .equal)
    }

    /// Sets the distance between the bottom edge and the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func bottom(to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat,
        by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        edge(.bottom, to: other, edge: otherEdge, offset: offset, by: relation)
    }

    /// Sets the leading edge match the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func leading(to other: UIView, edge otherEdge: AutoEdge) -> NSLayoutConstraint {
        edge(.leading, to: other, edge: otherEdge, offset: 0, by: .equal)
    }

    /// Sets the distance between the leading edge and the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func leading(to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat) -> NSLayoutConstraint {
        edge(.leading, to: other, edge: otherEdge, offset: offset, by: .equal)
    }

    /// Sets the distance between the leading edge and the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func leading(to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat,
        by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        edge(.leading, to: other, edge: otherEdge, offset: offset, by: relation)
    }

    /// Sets the trailing edge match the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func trailing(to other: UIView, edge otherEdge: AutoEdge) -> NSLayoutConstraint {
        edge(.trailing, to: other, edge: otherEdge, offset: 0, by: .equal)
    }

    /// Sets the distance between the trailing edge and the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func trailing(to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat) -> NSLayoutConstraint {
        edge(.trailing, to: other, edge: otherEdge, offset: offset, by: .equal)
    }

    /// Sets the distance between the trailing edge and the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func trailing(to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat,
        by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        edge(.trailing, to: other, edge: otherEdge, offset: offset, by: relation)
    }

    /// Sets the distance between the edge and the specified edge of the other view with the relationship.
    ///
    /// - Parameters:
    ///   - edge: The edge of self.
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func edge(_ edge: AutoEdge, to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat,
        by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        _autoEdge(edge, of: view, to: other, other: otherEdge, offset: offset, x: 1, by: relation)
    }

    /// Sets the distance between the edge and the specified edge of the other view with the relationship.
    ///
    /// - Parameters:
    ///   - edge: The edge of self.
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    ///   - multiplier: The constant multiplied with the attribute on the superview of
    ///   the constraint as part of getting the modified attribute.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func edge(_ edge: AutoEdge, to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat = 0,
        x multiplier: CGFloat = 1, by relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        _autoEdge(edge, of: view, to: other, other: otherEdge, offset: offset, x: multiplier, by: relation)
    }

    /// Sets the distance between the edge and the specified axis of the other view with the relationship.
    ///
    /// - Parameters:
    ///   - edge: The edge of self.
    ///   - other: The target view.
    ///   - axis: The target axis.
    ///   - offset: The value of the constraint.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func edge(_ edge: AutoEdge, to other: UIView, axis: AutoAxis, offset: CGFloat,
        by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        _autoEdge(edge, of: view, to: other, other: axis, offset: offset, x: 1, by: relation)
    }

    /// Sets the distance between the edge and the specified axis of the other view with the relationship.
    ///
    /// - Parameters:
    ///   - edge: The edge of self.
    ///   - other: The target view.
    ///   - axis: The target axis.
    ///   - offset: The value of the constraint.
    ///   - multiplier: The constant multiplied with the attribute on the superview of
    ///   the constraint as part of getting the modified attribute.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func edge(_ edge: AutoEdge, to other: UIView, axis: AutoAxis, offset: CGFloat = 0,
        x multiplier: CGFloat = 1, by relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        _autoEdge(edge, of: view, to: other, other: axis, offset: offset, x: multiplier, by: relation)
    }

    // MARK: - Auto Pin to Other View Edges

    /// Sets the left edge match the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func leftMargin(to other: UIView, edge otherEdge: AutoEdge) -> NSLayoutConstraint {
        edge(.leftMargin, to: other, edge: otherEdge, offset: 0, by: .equal)
    }

    /// Sets the distance between the left edge and the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func leftMargin(to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat) -> NSLayoutConstraint {
        edge(.leftMargin, to: other, edge: otherEdge, offset: offset, by: .equal)
    }

    /// Sets the distance between the left edge and the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func leftMargin(to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat,
        by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        edge(.leftMargin, to: other, edge: otherEdge, offset: offset, by: relation)
    }

    /// Sets the right edge match the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func rightMargin(to other: UIView, edge otherEdge: AutoEdge) -> NSLayoutConstraint {
        edge(.rightMargin, to: other, edge: otherEdge, offset: 0, by: .equal)
    }

    /// Sets the distance between the right edge and the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func rightMargin(to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat) -> NSLayoutConstraint {
        edge(.rightMargin, to: other, edge: otherEdge, offset: offset, by: .equal)
    }

    /// Sets the distance between the right edge and the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func rightMargin(to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat,
        by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        edge(.rightMargin, to: other, edge: otherEdge, offset: offset, by: relation)
    }

    /// Sets the top edge match the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func topMargin(to other: UIView, edge otherEdge: AutoEdge) -> NSLayoutConstraint {
        edge(.topMargin, to: other, edge: otherEdge, offset: 0, by: .equal)
    }

    /// Sets the distance between the top edge and the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func topMargin(to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat) -> NSLayoutConstraint {
        edge(.topMargin, to: other, edge: otherEdge, offset: offset, by: .equal)
    }

    /// Sets the distance between the top edge and the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func topMargin(to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat,
        by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        edge(.topMargin, to: other, edge: otherEdge, offset: offset, by: relation)
    }

    /// Sets the bottom edge match the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func bottomMargin(to other: UIView, edge otherEdge: AutoEdge) -> NSLayoutConstraint {
        edge(.bottomMargin, to: other, edge: otherEdge, offset: 0, by: .equal)
    }

    /// Sets the distance between the bottom edge and the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func bottomMargin(to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat) -> NSLayoutConstraint {
        edge(.bottomMargin, to: other, edge: otherEdge, offset: offset, by: .equal)
    }

    /// Sets the distance between the bottom edge and the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func bottomMargin(to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat,
        by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        edge(.bottomMargin, to: other, edge: otherEdge, offset: offset, by: relation)
    }

    /// Sets the leading edge match the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func leadingMargin(to other: UIView, edge otherEdge: AutoEdge) -> NSLayoutConstraint {
        edge(.leadingMargin, to: other, edge: otherEdge, offset: 0, by: .equal)
    }

    /// Sets the distance between the leading edge and the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func leadingMargin(to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat) -> NSLayoutConstraint {
        edge(.leadingMargin, to: other, edge: otherEdge, offset: offset, by: .equal)
    }

    /// Sets the distance between the leading edge and the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func leadingMargin(to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat,
        by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        edge(.leadingMargin, to: other, edge: otherEdge, offset: offset, by: relation)
    }

    /// Sets the trailing edge match the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func trailingMargin(to other: UIView, edge otherEdge: AutoEdge) -> NSLayoutConstraint {
        edge(.trailingMargin, to: other, edge: otherEdge, offset: 0, by: .equal)
    }

    /// Sets the distance between the trailing edge and the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func trailingMargin(to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat) -> NSLayoutConstraint {
        edge(.trailingMargin, to: other, edge: otherEdge, offset: offset, by: .equal)
    }

    /// Sets the distance between the trailing edge and the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func trailingMargin(to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat,
        by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        edge(.trailingMargin, to: other, edge: otherEdge, offset: offset, by: relation)
    }

    /// Sets the left inset and the right inset with the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - horizontal: The value of the constraints.
    /// - Returns: Newly created constraints.
    @objc(edgesMatch:Horizontal:)
    @inlinable
    @discardableResult
    public func edges(match other: UIView, horizontal: CGFloat) -> [NSLayoutConstraint] {
        let _left = edge(.left, to: other, edge: .left, offset: horizontal, by: .equal)
        let _right = edge(.right, to: other, edge: .right, offset: -horizontal, by: .equal)
        return [_left, _right]
    }

    /// Sets the top inset and the bottom inset with the other view..
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - vertical: The value of the constraints.
    /// - Returns: Newly created constraints.
    @objc(edgesMatch:Vertical:)
    @inlinable
    @discardableResult
    public func edges(match other: UIView, vertical: CGFloat) -> [NSLayoutConstraint] {
        let _top = edge(.top, to: other, edge: .top, offset: vertical, by: .equal)
        let _bottom = edge(.bottom, to: other, edge: .bottom, offset: -vertical, by: .equal)
        return [_top, _bottom]
    }

    /// Sets all edge insets with the other view..
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - horizontal: The value of the left inset and the right inset.
    ///   - vertical:  The value of the top inset and the bottom inset.
    /// - Returns: Newly created constraints.
    @objc(edgesMatch:Horizontal:vertical:)
    @inlinable
    @discardableResult
    public func edges(match other: UIView, horizontal: CGFloat, vertical: CGFloat) -> [NSLayoutConstraint] {
        let _top = edge(.top, to: other, edge: .top, offset: vertical, by: .equal)
        let _left = edge(.left, to: other, edge: .left, offset: horizontal, by: .equal)
        let _bottom = edge(.bottom, to: other, edge: .bottom, offset: -vertical, by: .equal)
        let _right = edge(.right, to: other, edge: .right, offset: -horizontal, by: .equal)
        return [_top, _left, _bottom, _right]
    }

    /// Sets all edge insets with the other view..
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - top: The value of the top inset.
    ///   - left: The value of the left inset.
    ///   - bottom: The value of the bottom inset.
    ///   - right: The value of the right inset.
    /// - Returns: Newly created constraints.
    @inlinable
    @discardableResult
    public func edges(match other: UIView, top: CGFloat, left: CGFloat, bottom: CGFloat,
        right: CGFloat) -> [NSLayoutConstraint] {
        let _top = edge(.top, to: other, edge: .top, offset: top, by: .equal)
        let _left = edge(.left, to: other, edge: .left, offset: left, by: .equal)
        let _bottom = edge(.bottom, to: other, edge: .bottom, offset: bottom, by: .equal)
        let _right = edge(.right, to: other, edge: .right, offset: right, by: .equal)
        return [_top, _left, _bottom, _right]
    }

    /// Sets all edge insets with the other view..
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - top: The value of the top inset.
    ///   - leading: The value of the leading inset.
    ///   - bottom: The value of the bottom inset.
    ///   - trailing: The value of the trailing inset.
    /// - Returns: Newly created constraints.
    @inlinable
    @discardableResult
    public func edges(match other: UIView, top: CGFloat, leading: CGFloat, bottom: CGFloat,
        trailing: CGFloat) -> [NSLayoutConstraint] {
        let _top = edge(.top, to: other, edge: .top, offset: top, by: .equal)
        let _leading = edge(.leading, to: other, edge: .leading, offset: leading, by: .equal)
        let _bottom = edge(.bottom, to: other, edge: .bottom, offset: bottom, by: .equal)
        let _trailing = edge(.trailing, to: other, edge: .trailing, offset: trailing, by: .equal)
        return [_top, _leading, _bottom, _trailing]
    }

    /// Sets all edge insets with the superview without the specified edge.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - top: The value of the top inset.
    ///   - left: The value of the left inset.
    ///   - bottom: The value of the bottom inset.
    ///   - right: The value of the right inset.
    ///   - edge: The edge should skip setting.
    /// - Returns: Newly created constraints.
    @inlinable
    @discardableResult
    public func edges(match other: UIView, top: CGFloat, left: CGFloat, bottom: CGFloat,
        right: CGFloat, except edge: AutoEdge) -> [NSLayoutConstraint] {
        let _top = edge == .top ? nil :
            self.edge(.top, to: other, edge: .top, offset: top, by: .equal)
        let _left = edge == .left ? nil :
            self.edge(.left, to: other, edge: .left, offset: left, by: .equal)
        let _bottom = edge == .bottom ? nil :
            self.edge(.bottom, to: other, edge: .bottom, offset: bottom, by: .equal)
        let _right = edge == .right ? nil :
            self.edge(.right, to: other, edge: .right, offset: right, by: .equal)
        return [_top, _left, _bottom, _right].compactMap(Function.identity)
    }

    /// Sets all edge insets with the superview without the specified edge.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - top: The value of the top inset.
    ///   - leading: The value of the leading inset.
    ///   - bottom: The value of the bottom inset.
    ///   - trailing: The value of the trailing inset.
    ///   - edge: The edge should skip setting.
    /// - Returns: Newly created constraints.
    @inlinable
    @discardableResult
    public func edges(match other: UIView, top: CGFloat, leading: CGFloat, bottom: CGFloat,
        trailing: CGFloat, except edge: AutoEdge) -> [NSLayoutConstraint] {
        let _top = edge == .top ? nil :
            self.edge(.top, to: other, edge: .top, offset: top, by: .equal)
        let _leading = edge == .leading ? nil :
            self.edge(.leading, to: other, edge: .leading, offset: leading, by: .equal)
        let _bottom = edge == .bottom ? nil :
            self.edge(.bottom, to: other, edge: .bottom, offset: bottom, by: .equal)
        let _trailing = edge == .trailing ? nil :
            self.edge(.trailing, to: other, edge: .trailing, offset: trailing, by: .equal)
        return [_top, _leading, _bottom, _trailing].compactMap(Function.identity)
    }

    // MARK: - Auto Size & Match

    /// Sets the width match the superview.
    ///
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func width() -> NSLayoutConstraint {
        precondition(view.superview != nil, "Super view cannot be nil")
        return _autoDimension(.width, of: view, to: view.superview, offset: 0, x: 1, by: .equal)
    }

    /// Sets the width to the specified value.
    ///
    /// - Parameter value: The value of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func width(_ value: CGFloat) -> NSLayoutConstraint {
        _autoDimension(.width, of: view, to: nil, offset: value, x: 1, by: .equal)
    }

    /// Sets the width to the specified value with the relationship.
    ///
    /// - Parameters:
    ///   - value: The value of the constraint.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func width(_ value: CGFloat,
        by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        _autoDimension(.width, of: view, to: nil, offset: value, x: 1, by: relation)
    }

    /// Sets the height match the superview.
    ///
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func height() -> NSLayoutConstraint {
        precondition(view.superview != nil, "Super view cannot be nil")
        return _autoDimension(.height, of: view, to: view.superview, offset: 0, x: 1, by: .equal)
    }

    /// Sets the height to the specified value.
    ///
    /// - Parameter value: The value of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func height(_ value: CGFloat) -> NSLayoutConstraint {
        _autoDimension(.height, of: view, to: nil, offset: value, x: 1, by: .equal)
    }

    /// Sets the height to the specified value with the relationship.
    ///
    /// - Parameters:
    ///   - value: The value of the constraint.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func height(_ value: CGFloat,
        by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        _autoDimension(.height, of: view, to: nil, offset: value, x: 1, by: relation)
    }

    /// Sets the size match the superview.
    ///
    /// - Returns: Newly created constraints.
    @inlinable
    @discardableResult
    public func size() -> [NSLayoutConstraint] {
        precondition(view.superview != nil, "Super view cannot be nil")
        let width = _autoDimension(.width, of: view, to: view.superview, offset: 0, x: 1, by: .equal)
        let height = _autoDimension(.height, of: view, to: view.superview, offset: 0, x: 1, by: .equal)
        return [width, height]
    }

    /// Sets the size to the specified value.
    ///
    /// - Parameter value: The value of the constraint.
    /// - Returns: Newly created constraints.
    @inlinable
    @discardableResult
    public func size(_ value: CGSize) -> [NSLayoutConstraint] {
        let width = _autoDimension(.width, of: view, to: nil, offset: value.width, x: 1, by: .equal)
        let height = _autoDimension(.height, of: view, to: nil, offset: value.height, x: 1, by: .equal)
        return [width, height]
    }

    /// Sets the size to the specified value with the relationship.
    ///
    /// - Parameters:
    ///   - value: The value of the constraint.
    ///   - relation: The relationship of the constraint.
    /// - Returns: Newly created constraints.
    @inlinable
    @discardableResult
    public func size(_ value: CGSize,
        by relation: NSLayoutConstraint.Relation) -> [NSLayoutConstraint] {
        let width = _autoDimension(.width, of: view, to: nil, offset: value.width, x: 1, by: relation)
        let height = _autoDimension(.height, of: view, to: nil, offset: value.height, x: 1, by: relation)
        return [width, height]
    }

    /// Sets the size to the specified value.
    ///
    /// - Parameters:
    ///   - width: The required width.
    ///   - height: The required height.
    /// - Returns: Newly created constraints.
    @inlinable
    @discardableResult
    public func size(width: CGFloat, height: CGFloat) -> [NSLayoutConstraint] {
        let width = _autoDimension(.width, of: view, to: nil, offset: width, x: 1, by: .equal)
        let height = _autoDimension(.height, of: view, to: nil, offset: height, x: 1, by: .equal)
        return [width, height]
    }

    /// Sets the size to the specified value with the relationship.
    ///
    /// - Parameters:
    ///   - width: The required width.
    ///   - height:  The required height.
    ///   - relation: The relationship of the constraint.
    /// - Returns: Newly created constraints.
    @inlinable
    @discardableResult
    public func size(width: CGFloat, height: CGFloat,
        by relation: NSLayoutConstraint.Relation) -> [NSLayoutConstraint] {
        let width = _autoDimension(.width, of: view, to: nil, offset: width, x: 1, by: relation)
        let height = _autoDimension(.height, of: view, to: nil, offset: height, x: 1, by: relation)
        return [width, height]
    }

    /// Sets the width match with the other view.
    ///
    /// - Parameter other: The target view.
    /// - Returns: A newly created constraint.
    @objc(widthMatch:)
    @inlinable
    @discardableResult
    public func width(match other: UIView) -> NSLayoutConstraint {
        _autoDimension(.width, of: view, to: other, offset: 0, x: 1, by: .equal)
    }

    /// Sets the offset between the width of views.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - offset: The value of the constraint.
    /// - Returns: A newly created constraint.
    @objc(widthMatch:offset:)
    @inlinable
    @discardableResult
    public func width(match other: UIView, offset: CGFloat) -> NSLayoutConstraint {
        _autoDimension(.width, of: view, to: other, offset: offset, x: 1, by: .equal)
    }

    /// Sets the offset between the width of views with the relationship.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - offset: The value of the constraint.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @objc(widthMatch:offset:by:)
    @inlinable
    @discardableResult
    public func width(match other: UIView, offset: CGFloat,
        by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        _autoDimension(.width, of: view, to: other, offset: offset, x: 1, by: relation)
    }

    /// Sets the height match with the other view.
    ///
    /// - Parameter other: The target view.
    /// - Returns: A newly created constraint.
    @objc(heightMatch:)
    @inlinable
    @discardableResult
    public func height(match other: UIView) -> NSLayoutConstraint {
        _autoDimension(.height, of: view, to: other, offset: 0, x: 1, by: .equal)
    }

    /// Sets the offset between the height of views.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - offset: The value of the constraint.
    /// - Returns: A newly created constraint.
    @objc(heightMatch:offset:)
    @inlinable
    @discardableResult
    public func height(match other: UIView, offset: CGFloat) -> NSLayoutConstraint {
        _autoDimension(.height, of: view, to: other, offset: offset, x: 1, by: .equal)
    }

    /// Sets the offset between the height of views with the relationship.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - offset: The value of the constraint.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @objc(heightMatch:offset:by:)
    @inlinable
    @discardableResult
    public func height(match other: UIView, offset: CGFloat,
        by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        _autoDimension(.height, of: view, to: other, offset: offset, x: 1, by: relation)
    }

    /// Sets the offset between the dimension of views with the relationship.
    ///
    /// - Parameters:
    ///   - dimension: The dimension of views.
    ///   - other: The target view.
    ///   - offset: The value of the constraint.
    ///   - multiplier: The constant multiplied with the attribute on the superview of
    ///   the constraint as part of getting the modified attribute.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func dimension(_ dimension: AutoDimension, to other: UIView? = nil, offset: CGFloat,
        x multiplier: CGFloat = 1, by relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        assert(other != nil || view.superview != nil)
        return _autoDimension(dimension, of: view, to: other ?? view.superview, offset: offset,
            x: multiplier, by: relation)
    }

    /// Sets the size match with the other view.
    ///
    /// - Parameter other: The target view.
    /// - Returns: Newly created constraints.
    @objc(sizeMatch:)
    @inlinable
    @discardableResult
    public func size(match other: UIView) -> [NSLayoutConstraint] {
        let width = _autoDimension(.width, of: view, to: other, offset: 0, x: 1, by: .equal)
        let height = _autoDimension(.height, of: view, to: other, offset: 0, x: 1, by: .equal)
        return [width, height]
    }

    /// Sets the size match with the other view with the relationship.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - relation: The relationship of the constraint.
    /// - Returns: Newly created constraints.
    @objc(sizeMatch:by:)
    @inlinable
    @discardableResult
    public func size(match other: UIView,
        by relation: NSLayoutConstraint.Relation) -> [NSLayoutConstraint] {
        let width = _autoDimension(.width, of: view, to: other, offset: 0, x: 1, by: relation)
        let height = _autoDimension(.height, of: view, to: other, offset: 0, x: 1, by: relation)
        return [width, height]
    }

    /// Sets the width equal to the height times the value.
    ///
    /// - Parameter value: The value of aspect radio.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    @available(*, deprecated, message:"please use aspectRadio(usingWidth:) instead")
    public func aspectRadio(forWidth value: CGFloat) -> NSLayoutConstraint {
        _autoDimension(first: .height, second: .width, of: view, offset: 0, x: value, by: .equal)
    }

    /// Sets the relationship between the width and the height times the value.
    ///
    /// - Parameters:
    ///   - value: The value of aspect radio.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    @available(*, deprecated, message:"please use aspectRadio(usingWidth:by:) instead")
    public func aspectRadio(forWidth value: CGFloat, by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        _autoDimension(first: .height, second: .width, of: view, offset: 0, x: value, by: relation)
    }

    /// Sets the height equal to the width times the value.
    ///
    /// - Parameter value: The value of aspect radio.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    @available(*, deprecated, message:"please use aspectRadio(usingHeight:) instead")
    public func aspectRadio(forHeight value: CGFloat) -> NSLayoutConstraint {
        _autoDimension(first: .width, second: .height, of: view, offset: 0, x: value, by: .equal)
    }

    /// Sets the relationship between the height and the width times the value.
    ///
    /// - Parameters:
    ///   - value: The value of aspect radio.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    @available(*, deprecated, message:"please use aspectRadio(usingHeight:by:) instead")
    public func aspectRadio(forHeight value: CGFloat, by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        _autoDimension(first: .width, second: .height, of: view, offset: 0, x: value, by: relation)
    }

    /// Sets the width equal to the height times the value.
    ///
    /// - Parameter value: The value of aspect radio.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func aspectRadio(usingWidth value: CGFloat) -> NSLayoutConstraint {
        _autoDimension(first: .height, second: .width, of: view, offset: 0, x: value, by: .equal)
    }

    /// Sets the relationship between the width and the height times the value.
    ///
    /// - Parameters:
    ///   - value: The value of aspect radio.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func aspectRadio(usingWidth value: CGFloat, by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        _autoDimension(first: .height, second: .width, of: view, offset: 0, x: value, by: relation)
    }

    /// Sets the height equal to the width times the value.
    ///
    /// - Parameter value: The value of aspect radio.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func aspectRadio(usingHeight value: CGFloat) -> NSLayoutConstraint {
        _autoDimension(first: .width, second: .height, of: view, offset: 0, x: value, by: .equal)
    }

    /// Sets the relationship between the height and the width times the value.
    ///
    /// - Parameters:
    ///   - value: The value of aspect radio.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func aspectRadio(usingHeight value: CGFloat, by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        _autoDimension(first: .width, second: .height, of: view, offset: 0, x: value, by: relation)
    }

    // MARK: - Auto Center & Match

    /// Sets the x-axis center match the superview.
    ///
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func centerX() -> NSLayoutConstraint {
        centerX(0, by: .equal)
    }

    /// Sets the offset with the x-axis center and the superview.
    ///
    /// - Parameter offset: The value of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func centerX(_ offset: CGFloat) -> NSLayoutConstraint {
        centerX(offset, by: .equal)
    }

    /// Sets the offset with the x-axis center and the superview with the relationship.
    ///
    /// - Parameters:
    ///   - offset: The value of the constraint.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func centerX(_ offset: CGFloat,
        by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        precondition(view.superview != nil, "Super view cannot be nil")
        return _autoAxis(.centerX, of: view, to: view.superview, axis: .centerX, offset: offset,
            x: 1, by: relation)
    }

    /// Sets the y-axis center match the superview.
    ///
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func centerY() -> NSLayoutConstraint {
        centerY(0, by: .equal)
    }

    /// Sets the offset with the y-axis center and the superview.
    ///
    /// - Parameter offset: The value of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func centerY(_ offset: CGFloat) -> NSLayoutConstraint {
        centerY(offset, by: .equal)
    }

    /// Sets the offset with the y-axis center and the superview with the relationship.
    ///
    /// - Parameters:
    ///   - offset: The value of the constraint.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func centerY(_ offset: CGFloat,
        by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        precondition(view.superview != nil, "Super view cannot be nil")
        return _autoAxis(.centerY, of: view, to: view.superview, axis: .centerY, offset: offset,
            x: 1, by: relation)
    }

    /// Sets the center match the superview.
    ///
    /// - Returns: Newly created constraints.
    @inlinable
    @discardableResult
    public func center() -> [NSLayoutConstraint] {
        let x = centerX(0, by: .equal)
        let y = centerY(0, by: .equal)
        return [x, y]
    }

    /// Sets the offset with the y-axis center and the superview.
    ///
    /// - Parameter offset: The offset with the superview center.
    /// - Returns: Newly created constraints.
    @objc(center:)
    @inlinable
    @discardableResult
    public func center(_ offset: CGPoint) -> [NSLayoutConstraint] {
        let x = centerX(offset.x, by: .equal)
        let y = centerY(offset.y, by: .equal)
        return [x, y]
    }

    /// Sets the offset with the y-axis center and the superview.
    ///
    /// - Parameters:
    ///   - x: The offset with the superview x-axis center
    ///   - y: The offset with the superview y-axis center
    /// - Returns: Newly created constraints.
    @objc(centerX:y:)
    @inlinable
    @discardableResult
    public func center(x: CGFloat, y: CGFloat) -> [NSLayoutConstraint] {
        let x = centerX(x, by: .equal)
        let y = centerY(y, by: .equal)
        return [x, y]
    }

    /// Sets the x-axis center match the other view.
    ///
    /// - Returns: A newly created constraint.
    @objc(centerXMatch:)
    @inlinable
    @discardableResult
    public func centerX(match other: UIView) -> NSLayoutConstraint {
        centerX(match: other, offset: 0, by: .equal)
    }

    /// Sets the offset with the x-axis center and the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - offset: The value of the constraint.
    /// - Returns: A newly created constraint.
    @objc(centerXMatch:offset:)
    @inlinable
    @discardableResult
    public func centerX(match other: UIView, offset: CGFloat) -> NSLayoutConstraint {
        centerX(match: other, offset: offset, by: .equal)
    }

    /// Sets the offset with the x-axis center and the other view with the relationship.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - offset: The value of the constraint.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @objc(centerXMatch:offset:by:)
    @inlinable
    @discardableResult
    public func centerX(match other: UIView, offset: CGFloat,
        by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        _autoAxis(.centerX, of: view, to: other, axis: .centerX, offset: offset, x: 1, by: relation)
    }

    /// Sets the y-axis center match the other view.
    ///
    /// - Returns: A newly created constraint.
    @objc(centerYMatch:)
    @inlinable
    @discardableResult
    public func centerY(match other: UIView) -> NSLayoutConstraint {
        centerY(match: other, offset: 0, by: .equal)
    }

    /// Sets the offset with the y-axis center and the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - offset: The value of the constraint.
    /// - Returns: A newly created constraint.
    @objc(centerYMatch:offset:)
    @inlinable
    @discardableResult
    public func centerY(match other: UIView, offset: CGFloat) -> NSLayoutConstraint {
        centerY(match: other, offset: offset, by: .equal)
    }

    /// Sets the offset with the y-axis center and the other view with the relationship.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - offset: The value of the constraint.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @objc(centerYMatch:offset:by:)
    @inlinable
    @discardableResult
    public func centerY(match other: UIView, offset: CGFloat,
        by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        _autoAxis(.centerY, of: view, to: other, axis: .centerY, offset: offset, x: 1, by: relation)
    }

    /// Sets the center match the other view.
    ///
    /// - Returns: A newly created constraint.
    @objc(centerMatch:)
    @inlinable
    @discardableResult
    public func center(match other: UIView) -> [NSLayoutConstraint] {
        let x = centerX(match: other, offset: 0, by: .equal)
        let y = centerY(match: other, offset: 0, by: .equal)
        return [x, y]
    }

    /// Sets the offset with the y-axis center and the other view.
    /// - Parameters:
    ///   - other: The target view.
    ///   - offset: The offset with the other view center.
    /// - Returns: Newly created constraints.
    @objc(centerMatch:offset:)
    @inlinable
    @discardableResult
    public func center(match other: UIView, offset: CGPoint) -> [NSLayoutConstraint] {
        let x = centerX(match: other, offset: offset.x, by: .equal)
        let y = centerY(match: other, offset: offset.y, by: .equal)
        return [x, y]
    }

    /// Sets the offset with the y-axis center and the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - x: The offset with other the view x-axis center
    ///   - y: The offset with other the view y-axis center
    /// - Returns: Newly created constraints.
    @objc(centerMatch:x:y:)
    @inlinable
    @discardableResult
    public func center(match other: UIView, x: CGFloat, y: CGFloat) -> [NSLayoutConstraint] {
        let x = centerX(match: other, offset: x, by: .equal)
        let y = centerY(match: other, offset: y, by: .equal)
        return [x, y]
    }

    /// Sets the x-axis center match the other view.
    ///
    /// - Returns: A newly created constraint.
    @objc(centerXMarginMatch:)
    @inlinable
    @discardableResult
    public func centerXMargin(match other: UIView) -> NSLayoutConstraint {
        centerX(match: other, offset: 0, by: .equal)
    }

    /// Sets the offset with the x-axis center and the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - offset: The value of the constraint.
    /// - Returns: A newly created constraint.
    @objc(centerXMarginMatch:offset:)
    @inlinable
    @discardableResult
    public func centerXMargin(match other: UIView, offset: CGFloat) -> NSLayoutConstraint {
        centerX(match: other, offset: offset, by: .equal)
    }

    /// Sets the offset with the x-axis center and the other view with the relationship.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - offset: The value of the constraint.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @objc(centerXMarginMatch:offset:by:)
    @inlinable
    @discardableResult
    public func centerXMargin(match other: UIView, offset: CGFloat,
        by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        _autoAxis(.centerXMargin, of: view, to: other, axis: .centerXMargin, offset: offset, x: 1, by: relation)
    }

    /// Sets the y-axis center match the other view.
    ///
    /// - Returns: A newly created constraint.
    @objc(centerYMarginMatch:)
    @inlinable
    @discardableResult
    public func centerYMargin(match other: UIView) -> NSLayoutConstraint {
        centerY(match: other, offset: 0, by: .equal)
    }

    /// Sets the offset with the y-axis center and the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - offset: The value of the constraint.
    /// - Returns: A newly created constraint.
    @objc(centerYMarginMatch:offset:)
    @inlinable
    @discardableResult
    public func centerYMargin(match other: UIView, offset: CGFloat) -> NSLayoutConstraint {
        centerY(match: other, offset: offset, by: .equal)
    }

    /// Sets the offset with the y-axis center and the other view with the relationship.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - offset: The value of the constraint.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @objc(centerYMarginMatch:offset:by:)
    @inlinable
    @discardableResult
    public func centerYMargin(match other: UIView, offset: CGFloat,
        by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        _autoAxis(.centerYMargin, of: view, to: other, axis: .centerYMargin, offset: offset, x: 1, by: relation)
    }

    /// Sets the distance between the axis and the specified axis of the other view with the relationship.
    ///
    /// - Parameters:
    ///   - axis: The axis of self.
    ///   - other: The target view.
    ///   - otherAxis: The target axis.
    ///   - offset: The value of the constraint.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func axis(_ axis: AutoAxis, to other: UIView?, axis otherAxis: AutoAxis,
        offset: CGFloat, by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        _autoAxis(axis, of: view, to: other, axis: otherAxis, offset: offset, x: 1.0, by: relation)
    }

    /// Sets the distance between the axis and the specified axis of the other view with the relationship.
    ///
    /// - Parameters:
    ///   - axis: The axis of self.
    ///   - other: The target view.
    ///   - otherAxis: The target axis.
    ///   - offset: The value of the constraint.
    ///   - multiplier: The constant multiplied with the attribute on the superview of
    ///   the constraint as part of getting the modified attribute.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func axis(_ axis: AutoAxis, to other: UIView?, axis otherAxis: AutoAxis, offset: CGFloat = 0.0,
        x multiplier: CGFloat = 1.0, by relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        _autoAxis(axis, of: view, to: other, axis: otherAxis, offset: offset, x: multiplier, by: relation)
    }

    // MARK: - Auto Pin to Super View Safe Edges

    /// Sets the left inset with the superview to `0`.
    ///
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func safeLeft() -> NSLayoutConstraint {
        safeEdge(.left, toSuper: .left, inset: 0, by: .equal)
    }

    /// Sets the left inset with the superview to inset.
    ///
    /// - Parameters:
    ///   - inset: The value of the inset.
    /// - Returns: A newly created constraint.
    @objc(safeLeftInset:)
    @inlinable
    @discardableResult
    public func safeLeft(inset: CGFloat) -> NSLayoutConstraint {
        safeEdge(.left, toSuper: .left, inset: inset, by: .equal)
    }

    /// Sets the left inset with the superview to inset, also set the relationship.
    ///
    /// - Parameters:
    ///   - inset: The value of the inset.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @objc(safeLeftInset:by:)
    @inlinable
    @discardableResult
    public func safeLeft(inset: CGFloat, by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        safeEdge(.left, toSuper: .left, inset: inset, by: relation)
    }

    /// Sets the right inset with the superview to `0`.
    ///
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func safeRight() -> NSLayoutConstraint {
        safeEdge(.right, toSuper: .right, inset: 0, by: .equal)
    }

    /// Sets the right inset with the superview to inset.
    ///
    /// - Parameters:
    ///   - inset: The value of the inset.
    /// - Returns: A newly created constraint.
    @objc(safeRightInset:)
    @inlinable
    @discardableResult
    public func safeRight(inset: CGFloat) -> NSLayoutConstraint {
        safeEdge(.right, toSuper: .right, inset: inset, by: .equal)
    }

    /// Sets the right inset with the superview to inset, also set the relationship.
    ///
    /// - Parameters:
    ///   - inset: The value of the inset.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @objc(safeRightInset:by:)
    @inlinable
    @discardableResult
    public func safeRight(inset: CGFloat, by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        safeEdge(.right, toSuper: .right, inset: inset, by: relation)
    }

    /// Sets the top inset with the superview to `0`.
    ///
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func safeTop() -> NSLayoutConstraint {
        safeEdge(.top, toSuper: .top, inset: 0, by: .equal)
    }

    /// Sets the top inset with the superview to inset.
    ///
    /// - Parameters:
    ///   - inset: The value of the inset.
    /// - Returns: A newly created constraint.
    @objc(safeTopInset:)
    @inlinable
    @discardableResult
    public func safeTop(inset: CGFloat) -> NSLayoutConstraint {
        safeEdge(.top, toSuper: .top, inset: inset, by: .equal)
    }

    /// Sets the top inset with the superview to inset, also set the relationship.
    ///
    /// - Parameters:
    ///   - inset: The value of the inset.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @objc(safeTopInset:by:)
    @inlinable
    @discardableResult
    public func safeTop(inset: CGFloat, by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        safeEdge(.top, toSuper: .top, inset: inset, by: relation)
    }

    /// Sets the bottom inset with the superview to `0`.
    ///
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func safeBottom() -> NSLayoutConstraint {
        safeEdge(.bottom, toSuper: .bottom, inset: 0, by: .equal)
    }

    /// Sets the bottom inset with the superview to inset.
    ///
    /// - Parameters:
    ///   - inset: The value of the inset.
    /// - Returns: A newly created constraint.
    @objc(safeBottomInset:)
    @inlinable
    @discardableResult
    public func safeBottom(inset: CGFloat) -> NSLayoutConstraint {
        safeEdge(.bottom, toSuper: .bottom, inset: inset, by: .equal)
    }

    /// Sets the bottom inset with the superview to inset, also set the relationship.
    ///
    /// - Parameters:
    ///   - inset: The value of the inset.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @objc(safeBottomInset:by:)
    @inlinable
    @discardableResult
    public func safeBottom(inset: CGFloat, by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        safeEdge(.bottom, toSuper: .bottom, inset: inset, by: relation)
    }

    /// Sets the leading inset with the superview to `0`.
    ///
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func safeLeading() -> NSLayoutConstraint {
        safeEdge(.leading, toSuper: .leading, inset: 0, by: .equal)
    }

    /// Sets the leading inset with the superview to inset.
    ///
    /// - Parameters:
    ///   - inset: The value of the inset.
    /// - Returns: A newly created constraint.
    @objc(safeLeadingInset:)
    @inlinable
    @discardableResult
    public func safeLeading(inset: CGFloat) -> NSLayoutConstraint {
        safeEdge(.leading, toSuper: .leading, inset: inset, by: .equal)
    }

    /// Sets the leading inset with the superview to inset, also set the relationship.
    ///
    /// - Parameters:
    ///   - inset: The value of the inset.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @objc(safeLeadingInset:by:)
    @inlinable
    @discardableResult
    public func safeLeading(inset: CGFloat, by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        safeEdge(.leading, toSuper: .leading, inset: inset, by: relation)
    }

    /// Sets the trailing inset with the superview to `0`.
    ///
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func safeTrailing() -> NSLayoutConstraint {
        safeEdge(.trailing, toSuper: .trailing, inset: 0, by: .equal)
    }

    /// Sets the trailing inset with the superview to inset.
    ///
    /// - Parameters:
    ///   - inset: The value of the inset.
    /// - Returns: A newly created constraint.
    @objc(safeTrailingInset:)
    @inlinable
    @discardableResult
    public func safeTrailing(inset: CGFloat) -> NSLayoutConstraint {
        safeEdge(.trailing, toSuper: .trailing, inset: inset, by: .equal)
    }

    /// Sets the trailing inset with the superview to inset, also set the relationship.
    ///
    /// - Parameters:
    ///   - inset: The value of the inset.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @objc(safeTrailingInset:by:)
    @inlinable
    @discardableResult
    public func safeTrailing(inset: CGFloat, by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        safeEdge(.trailing, toSuper: .trailing, inset: inset, by: relation)
    }

    /// Creates a constraint that defines the relationship between the specified edge.
    ///
    /// The linear equation for this relationship is shown below:
    /// `view.edge = superview.edge + offset`.
    ///
    /// - Parameters:
    ///   - edge: The edge of self.
    ///   - otherEdge: The edge of super view.
    ///   - inset: The value of the inset.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func safeEdge(_ edge: AutoEdge, toSuper otherEdge: AutoEdge, inset: CGFloat,
        by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        precondition(view.superview != nil, "Super view cannot be nil")
        let offset: CGFloat
        let r: NSLayoutConstraint.Relation
        if edge.shouldInvert {
            offset = -inset
            switch relation {
            case .lessThanOrEqual:
                r = .greaterThanOrEqual
            case .greaterThanOrEqual:
                r = .lessThanOrEqual
            case .equal:
                fallthrough
            @unknown default:
                r = relation
            }
        } else {
            offset = inset
            r = relation
        }
        return _autoSafeEdge(edge, of: view, to: view.superview, edge: edge, offset: offset, by: r)
    }

    /// Sets the left inset and the right inset with the superview.
    ///
    /// - Parameter horizontal: The value of the constraints.
    /// - Returns: Newly created constraints.
    @objc(safeEdgesHorizontal:)
    @inlinable
    @discardableResult
    public func safeEdges(horizontal: CGFloat) -> [NSLayoutConstraint] {
        let _left = safeEdge(.left, toSuper: .left, inset: horizontal, by: .equal)
        let _right = safeEdge(.right, toSuper: .right, inset: horizontal, by: .equal)
        return [_left, _right]
    }

    /// Sets the top inset and the bottom inset with the superview.
    ///
    /// - Parameter vertical: The value of the constraints.
    /// - Returns: Newly created constraints.
    @objc(safeEdgesVertical:)
    @inlinable
    @discardableResult
    public func safeEdges(vertical: CGFloat) -> [NSLayoutConstraint] {
        let _top = safeEdge(.top, toSuper: .top, inset: vertical, by: .equal)
        let _bottom = safeEdge(.bottom, toSuper: .bottom, inset: vertical, by: .equal)
        return [_top, _bottom]
    }

    /// Sets all edge insets with the superview.
    ///
    /// - Parameters:
    ///   - horizontal: The value of the left inset and the right inset.
    ///   - vertical:  The value of the top inset and the bottom inset.
    /// - Returns: Newly created constraints.
    @objc(safeEdgesHorizontal:vertical:)
    @inlinable
    @discardableResult
    public func safeEdges(horizontal: CGFloat, vertical: CGFloat) -> [NSLayoutConstraint] {
        let _top = safeEdge(.top, toSuper: .top, inset: vertical, by: .equal)
        let _left = safeEdge(.left, toSuper: .left, inset: horizontal, by: .equal)
        let _bottom = safeEdge(.bottom, toSuper: .bottom, inset: vertical, by: .equal)
        let _right = safeEdge(.right, toSuper: .right, inset: horizontal, by: .equal)
        return [_top, _left, _bottom, _right]
    }

    /// Sets all edge insets with the superview.
    ///
    /// - Parameters:
    ///   - top: The value of the top inset.
    ///   - left: The value of the left inset.
    ///   - bottom: The value of the bottom inset.
    ///   - right: The value of the right inset.
    /// - Returns: Newly created constraints.
    @inlinable
    @discardableResult
    public func safeEdges(top: CGFloat, left: CGFloat, bottom: CGFloat,
        right: CGFloat) -> [NSLayoutConstraint] {
        let _top = safeEdge(.top, toSuper: .top, inset: top, by: .equal)
        let _left = safeEdge(.left, toSuper: .left, inset: left, by: .equal)
        let _bottom = safeEdge(.bottom, toSuper: .bottom, inset: bottom, by: .equal)
        let _right = safeEdge(.right, toSuper: .right, inset: right, by: .equal)
        return [_top, _left, _bottom, _right]
    }

    /// Sets all edge insets with the superview.
    ///
    /// - Parameters:
    ///   - top: The value of the top inset.
    ///   - leading: The value of the leading inset.
    ///   - bottom: The value of the bottom inset.
    ///   - trailing: The value of the trailing inset.
    /// - Returns: Newly created constraints.
    @inlinable
    @discardableResult
    public func safeEdges(top: CGFloat, leading: CGFloat, bottom: CGFloat,
        trailing: CGFloat) -> [NSLayoutConstraint] {
        let _top = safeEdge(.top, toSuper: .top, inset: top, by: .equal)
        let _leading = safeEdge(.leading, toSuper: .leading, inset: leading, by: .equal)
        let _bottom = safeEdge(.bottom, toSuper: .bottom, inset: bottom, by: .equal)
        let _trailing = safeEdge(.trailing, toSuper: .trailing, inset: trailing, by: .equal)
        return [_top, _leading, _bottom, _trailing]
    }

    /// Sets all edge insets with the superview without the specified edges.
    ///
    /// - Parameters:
    ///   - top: The value of the top inset.
    ///   - left: The value of the left inset.
    ///   - bottom: The value of the bottom inset.
    ///   - right: The value of the right inset.
    ///   - edge: The edge should skip setting.
    /// - Returns: Newly created constraints.
    @inlinable
    @discardableResult
    public func safeEdges(top: CGFloat, left: CGFloat, bottom: CGFloat,
        right: CGFloat, except edge: AutoEdge) -> [NSLayoutConstraint] {
        let _top = edge == .top ? nil :
            safeEdge(.top, toSuper: .top, inset: top, by: .equal)
        let _left = edge == .left ? nil :
            safeEdge(.left, toSuper: .left, inset: left, by: .equal)
        let _bottom = edge == .bottom ? nil :
            safeEdge(.bottom, toSuper: .bottom, inset: bottom, by: .equal)
        let _right = edge == .right ? nil :
            safeEdge(.right, toSuper: .right, inset: right, by: .equal)
        return [_top, _left, _bottom, _right].compactMap(Function.identity)
    }

    /// Sets all edge insets with the superview without the specified edges.
    ///
    /// - Parameters:
    ///   - top: The value of the top inset.
    ///   - leading: The value of the leading inset.
    ///   - bottom: The value of the bottom inset.
    ///   - trailing: The value of the trailing inset.
    ///   - edge: The edge should skip setting.
    /// - Returns: Newly created constraints.
    @inlinable
    @discardableResult
    public func safeEdges(top: CGFloat, leading: CGFloat, bottom: CGFloat,
        trailing: CGFloat, except edge: AutoEdge) -> [NSLayoutConstraint] {
        let _top = edge == .top ? nil :
            safeEdge(.top, toSuper: .top, inset: top, by: .equal)
        let _leading = edge == .leading ? nil :
            safeEdge(.leading, toSuper: .leading, inset: leading, by: .equal)
        let _bottom = edge == .bottom ? nil :
            safeEdge(.bottom, toSuper: .bottom, inset: bottom, by: .equal)
        let _trailing = edge == .trailing ? nil :
            safeEdge(.trailing, toSuper: .trailing, inset: trailing, by: .equal)
        return [_top, _leading, _bottom, _trailing].compactMap(Function.identity)
    }

    // MARK: - Auto Pin to Other View Safe Edges

    /// Sets the left edge match the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func safeLeft(to other: UIView, edge otherEdge: AutoEdge) -> NSLayoutConstraint {
        safeEdge(.left, to: other, edge: otherEdge, offset: 0, by: .equal)
    }

    /// Sets the distance between the left edge and the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func safeLeft(to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat) -> NSLayoutConstraint {
        safeEdge(.left, to: other, edge: otherEdge, offset: offset, by: .equal)
    }

    /// Sets the distance between the left edge and the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func safeLeft(to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat,
        by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        safeEdge(.left, to: other, edge: otherEdge, offset: offset, by: relation)
    }

    /// Sets the right edge match the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func safeRight(to other: UIView, edge otherEdge: AutoEdge) -> NSLayoutConstraint {
        safeEdge(.right, to: other, edge: otherEdge, offset: 0, by: .equal)
    }

    /// Sets the distance between the right edge and the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func safeRight(to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat) -> NSLayoutConstraint {
        safeEdge(.right, to: other, edge: otherEdge, offset: offset, by: .equal)
    }

    /// Sets the distance between the right edge and the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func safeRight(to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat,
        by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        safeEdge(.right, to: other, edge: otherEdge, offset: offset, by: relation)
    }

    /// Sets the top edge match the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func safeTop(to other: UIView, edge otherEdge: AutoEdge) -> NSLayoutConstraint {
        safeEdge(.top, to: other, edge: otherEdge, offset: 0, by: .equal)
    }

    /// Sets the distance between the top edge and the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func safeTop(to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat) -> NSLayoutConstraint {
        safeEdge(.top, to: other, edge: otherEdge, offset: offset, by: .equal)
    }

    /// Sets the distance between the top edge and the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func safeTop(to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat,
        by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        safeEdge(.top, to: other, edge: otherEdge, offset: offset, by: relation)
    }

    /// Sets the bottom edge match the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func safeBottom(to other: UIView, edge otherEdge: AutoEdge) -> NSLayoutConstraint {
        safeEdge(.bottom, to: other, edge: otherEdge, offset: 0, by: .equal)
    }

    /// Sets the distance between the bottom edge and the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func safeBottom(to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat) -> NSLayoutConstraint {
        safeEdge(.bottom, to: other, edge: otherEdge, offset: offset, by: .equal)
    }

    /// Sets the distance between the bottom edge and the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func safeBottom(to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat,
        by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        safeEdge(.bottom, to: other, edge: otherEdge, offset: offset, by: relation)
    }

    /// Sets the leading edge match the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func safeLeading(to other: UIView, edge otherEdge: AutoEdge) -> NSLayoutConstraint {
        safeEdge(.leading, to: other, edge: otherEdge, offset: 0, by: .equal)
    }

    /// Sets the distance between the leading edge and the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func safeLeading(to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat) -> NSLayoutConstraint {
        safeEdge(.leading, to: other, edge: otherEdge, offset: offset, by: .equal)
    }

    /// Sets the distance between the leading edge and the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func safeLeading(to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat,
        by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        safeEdge(.leading, to: other, edge: otherEdge, offset: offset, by: relation)
    }

    /// Sets the trailing edge match the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func safeTrailing(to other: UIView, edge otherEdge: AutoEdge) -> NSLayoutConstraint {
        safeEdge(.trailing, to: other, edge: otherEdge, offset: 0, by: .equal)
    }

    /// Sets the distance between the trailing edge and the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func safeTrailing(to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat) -> NSLayoutConstraint {
        safeEdge(.trailing, to: other, edge: otherEdge, offset: offset, by: .equal)
    }

    /// Sets the distance between the trailing edge and the specified edge of the other view.
    ///
    /// - Parameters:
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func safeTrailing(to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat,
        by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        safeEdge(.trailing, to: other, edge: otherEdge, offset: offset, by: relation)
    }

    /// Sets the distance between the edge and the specified edge of the other view with the relationship.
    ///
    /// - Parameters:
    ///   - edge: The edge of self.
    ///   - other: The target view.
    ///   - otherEdge: The target edge.
    ///   - offset: The value of the constraint.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @inlinable
    @discardableResult
    public func safeEdge(_ edge: AutoEdge, to other: UIView, edge otherEdge: AutoEdge, offset: CGFloat,
        by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        _autoSafeEdge(edge, of: view, to: other, edge: otherEdge, offset: offset, by: relation)
    }

    // MARK: - Auto Layout Guide (Deprecated)

    /// Creates a constraint that defines the relationship between the top layout guide of the controller.
    ///
    /// - Parameter viewController: The target view controller.
    /// - Returns: A newly created constraint.
    @available(iOS, introduced: 7.0, deprecated: 11.0)
    @inlinable
    @discardableResult
    public func guideTop(to viewController: UIViewController) -> NSLayoutConstraint {
        guideTop(to: viewController, inset: 0, by: .equal)
    }

    /// Creates a constraint that defines the relationship between the top layout guide of the controller.
    ///
    /// - Parameters:
    ///   - viewController: The target view controller.
    ///   - inset: The value of the constraint.
    /// - Returns: A newly created constraint.
    @available(iOS, introduced: 7.0, deprecated: 11.0)
    @inlinable
    @discardableResult
    public func guideTop(to viewController: UIViewController, inset: CGFloat) -> NSLayoutConstraint {
        guideTop(to: viewController, inset: inset, by: .equal)
    }

    /// Creates a constraint that defines the relationship between the top layout guide of the controller.
    ///
    /// - Parameters:
    ///   - viewController: The target view controller.
    ///   - inset: The value of the constraint.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @available(iOS, introduced: 7.0, deprecated: 11.0)
    @inlinable
    @discardableResult
    public func guideTop(to viewController: UIViewController, inset: CGFloat,
        by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        _autoGuideEdge(.top, of: view, to: viewController.topLayoutGuide, edge: .bottom,
            offset: inset, x: 1, by: relation)
    }

    /// Creates a constraint that defines the relationship between the bottom layout guide of the controller.
    ///
    /// - Parameter viewController: The target view controller.
    /// - Returns: A newly created constraint.
    @available(iOS, introduced: 7.0, deprecated: 11.0)
    @inlinable
    @discardableResult
    public func guideBottom(to viewController: UIViewController) -> NSLayoutConstraint {
        guideBottom(to: viewController, inset: 0, by: .equal)
    }

    /// Creates a constraint that defines the relationship between the bottom layout guide of the controller.
    ///
    /// - Parameters:
    ///   - viewController: The target view controller.
    ///   - inset: The value of the constraint.
    /// - Returns: A newly created constraint.
    @available(iOS, introduced: 7.0, deprecated: 11.0)
    @inlinable
    @discardableResult
    public func guideBottom(to viewController: UIViewController, inset: CGFloat) -> NSLayoutConstraint {
        guideBottom(to: viewController, inset: inset, by: .equal)
    }

    /// Creates a constraint that defines the relationship between the bottom layout guide of the controller.
    ///
    /// - Parameters:
    ///   - viewController: The target view controller.
    ///   - inset: The value of the constraint.
    ///   - relation: The relationship of the constraint.
    /// - Returns: A newly created constraint.
    @available(iOS, introduced: 7.0, deprecated: 11.0)
    @inlinable
    @discardableResult
    public func guideBottom(to viewController: UIViewController, inset: CGFloat,
        by relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        let r: NSLayoutConstraint.Relation
        switch relation {
        case .lessThanOrEqual:
            r = .greaterThanOrEqual
        case .greaterThanOrEqual:
            r = .lessThanOrEqual
        case .equal:
            fallthrough
        @unknown default:
            r = relation
        }
        return _autoGuideEdge(.bottom, of: view, to: viewController.bottomLayoutGuide, edge: .top,
            offset: -inset, x: 1, by: r)
    }
}

extension AutoMaker {
    /// Sets the priority with which a view resists being made smaller than its intrinsic size.
    ///
    /// - Parameter value: The new priority.
    @inlinable
    public func horizontalHuggingPriority(_ value: UILayoutPriority) {
        view.setContentHuggingPriority(value, for: .horizontal)
    }

    /// Sets the priority with which a view resists being made smaller than its intrinsic size.
    ///
    /// - Parameter value: The new priority.
    @inlinable
    public func verticalHuggingPriority(_ value: UILayoutPriority) {
        view.setContentHuggingPriority(value, for: .vertical)
    }

    /// Sets the priority with which a view resists being made larger than its intrinsic size.
    ///
    /// - Parameter value: The new priority.
    @inlinable
    public func horizontalCompressionResistancePriority(_ value: UILayoutPriority) {
        view.setContentCompressionResistancePriority(value, for: .horizontal)
    }

    /// Sets the priority with which a view resists being made larger than its intrinsic size.
    ///
    /// - Parameter value: The new priority.
    @inlinable
    public func verticalCompressionResistancePriority(_ value: UILayoutPriority) {
        view.setContentCompressionResistancePriority(value, for: .vertical)
    }
}

/// A subclass for distinguish between manually created constraint
/// and system or xcode (interface builder) created.
public final class AutoConstraint: NSLayoutConstraint {
    // Do nothing.
}

#endif // canImport(UIKit)
