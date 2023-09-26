import Darwin.C

@inlinable
func isDoubleEqual(_ lhs: Double, to rhs: Double) -> Bool {
    if !lhs.isNaN && !rhs.isNaN {
        return fabs(lhs - rhs) < 0.0001
    }
    return lhs.isNaN && rhs.isNaN
}

@inlinable
func inner<T>(_ value: T, min: T, max: T) -> T where T: Comparable {
    Swift.max(Swift.min(value, max), min)
}

func inner<T>(_ value: T?, min: T?, max: T?) -> T?  where T: Comparable {
    guard var result = value else {
        return nil
    }
    if let max = max {
        result = Swift.min(result, max)
    }
    if let min = min {
        result = Swift.max(result, min)
    }
    return result
}
