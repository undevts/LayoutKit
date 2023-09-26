#if canImport(UIKit)
import UIKit

@_transparent
private func sanitizeSize(constrained: Double, measured: Double, mode: MeasureMode) -> Double {
    switch mode {
    case .exactly:
        return constrained
    case .atMost:
        return min(constrained, measured)
    case .undefined:
        return measured
    }
}

private func measureView(_ view: UIView?, _ layout: FlexLayout, _ width: Double,
    _ widthMode: MeasureMode, _  height: Double, _ heightMode: MeasureMode) -> Size {
    guard let view = view else {
        return Size.zero
    }
    let size = CGSize(width: width.isNaN ? CGFloat.greatestFiniteMagnitude : CGFloat(width),
        height: height.isNaN ? CGFloat.greatestFiniteMagnitude : CGFloat(height))
    let fitSize = view.sizeThatFits(size)
//#if DEBUG
//    let result = Size(width: sanitizeSize(constrained: size.width, measured: fitSize.width, mode: widthMode),
//        height: sanitizeSize(constrained: size.height, measured: fitSize.height, mode: heightMode))
//    print(#fileID, #function, "\(view), size = \(size), fitSize = \(fitSize), result = \(result)")
//    return result
//#else
    return Size(width: sanitizeSize(constrained: size.width, measured: fitSize.width, mode: widthMode),
        height: sanitizeSize(constrained: size.height, measured: fitSize.height, mode: heightMode))
//#endif
}

private func baselineLabel(_ view: UILabel?, _ width: Double, _  height: Double) -> Double {
    guard let view = view else {
        return 0.0
    }
    return (view.font ?? UIFont.systemFont(ofSize: 17)).ascender
}

private func baselineTextField(_ view: UITextField?, _ width: Double, _  height: Double) -> Double {
    guard let view = view else {
        return 0.0
    }
    let ascender = (view.font ?? UIFont.systemFont(ofSize: 17)).ascender
    switch view.borderStyle {
    case .none:
        return ascender
    case .line:
        return ascender + 4.0
    case .bezel, .roundedRect:
        return ascender + 7.0
    @unknown default:
        return ascender
    }
}

private func baselineTextView(_ view: UITextView?, _ width: Double, _  height: Double) -> Double {
    guard let view = view else {
        return 0.0
    }
    let ascender = (view.font ?? UIFont.systemFont(ofSize: 17)).ascender
    return ascender + view.contentInset.top + view.contentInset.bottom
}

extension FlexLayout {
    @discardableResult
    public func autoSize(of view: UIView) -> FlexLayout {
        measure { [view = view] layout, width, widthMode, height, heightMode in
            measureView(view, layout, width, widthMode, height, heightMode)
        }
        return self
    }

    @discardableResult
    public func baseline(of view: UILabel) -> FlexLayout {
        baseline { [view = view] _, width, height in
            baselineLabel(view, width, height)
        }
        return self
    }

    @discardableResult
    public func baseline(of view: UITextField) -> FlexLayout {
        baseline { [view = view] _, width, height in
            baselineTextField(view, width, height)
        }
        return self
    }

    @discardableResult
    public func baseline(of view: UITextView) -> FlexLayout {
        baseline { [view = view] _, width, height in
            baselineTextView(view, width, height)
        }
        return self
    }
}
#endif // canImport(UIKit)
