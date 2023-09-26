postfix operator %

/// 90.0%
public postfix func % (value: Double) -> StyleValue {
    return .percentage(value)
}

/// 90%
public postfix func % (value: Int) -> StyleValue {
    return .percentage(Double(value))
}
