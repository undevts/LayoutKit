import CoreGraphics

extension FlexLayout {
    @discardableResult
    public func direction(_ value: Direction) -> FlexLayout {
        if style.direction != value {
            style.direction = value
            _markDirty()
        }
        return self
    }

    @discardableResult
    public func flexDirection(_ value: FlexDirection) -> FlexLayout {
        if style.flexDirection != value {
            style.flexDirection = value
            _markDirty()
        }
        return self
    }

    @discardableResult
    public func justifyContent(_ value: JustifyContent) -> FlexLayout {
        if style.justifyContent != value {
            style.justifyContent = value
            _markDirty()
        }
        return self
    }

    @discardableResult
    public func alignContent(_ value: AlignContent) -> FlexLayout {
        if style.alignContent != value {
            style.alignContent = value
            _markDirty()
        }
        return self
    }

    @discardableResult
    public func alignItems(_ value: AlignItems) -> FlexLayout {
        if style.alignItems != value {
            style.alignItems = value
            _markDirty()
        }
        return self
    }

    @discardableResult
    public func alignSelf(_ value: AlignSelf) -> FlexLayout {
        if style.alignSelf != value {
            style.alignSelf = value
            _markDirty()
        }
        return self
    }

    @discardableResult
    public func flexWrap(_ value: FlexWrap) -> FlexLayout {
        if style.flexWrap != value {
            style.flexWrap = value
            _markDirty()
        }
        return self
    }

    @discardableResult
    public func overflow(_ value: Overflow) -> FlexLayout {
        if style.overflow != value {
            style.overflow = value
            _markDirty()
        }
        return self
    }

    @discardableResult
    public func display(_ value: Display) -> FlexLayout {
        if style.display != value {
            style.display = value
            _markDirty()
        }
        return self
    }

    @discardableResult
    public func flex(_ value: Flex) -> FlexLayout {
        if style.flex != value {
            style.flex = value
            _markDirty()
        }
        return self
    }

    @discardableResult
    public func flexGrow(_ value: Double) -> FlexLayout {
        if style.flexGrow != value {
            // Flex default is Flex.None => flexGrow default is 0
            let resolved = value.isNaN ? 0 : value
            style.flexGrow = resolved
            _markDirty()
        }
        return self
    }

    @discardableResult
    public func flexShrink(_ value: Double) -> FlexLayout {
        if style.flexShrink != value {
            // Flex default is Flex.None => flexShrink default is 0
            let resolved = value.isNaN ? 0 : value
            style.flexShrink = resolved
            _markDirty()
        }
        return self
    }

    @discardableResult
    public func flexBasis(_ value: FlexBasis) -> FlexLayout {
        if style.flexBasis != value {
            style.flexBasis = value
            _markDirty()
        }
        return self
    }

    @discardableResult
    public func flexBasis(_ value: Double) -> FlexLayout {
        flexBasis(FlexBasis(from: value))
    }

    @discardableResult
    public func positionType(_ value: PositionType) -> FlexLayout {
        if style.positionType != value {
            style.positionType = value
            _markDirty()
        }
        return self
    }

    /// Constrains this view’s dimensions to the aspect ratio of the given value.
    ///
    /// - Parameter value: A double value that specifies the ratio of width to height.
    /// - Returns: Self, for fluent method call.
    @discardableResult
    public func aspectRatio(_ value: Double) -> FlexLayout {
        if style.aspectRatio != value {
            style.aspectRatio = value
            _markDirty()
        }
        return self
    }

    @discardableResult
    public func measure(_ value: FlexMeasureMethod?) -> FlexLayout {
        if value == nil {
            layoutType = .default
        } else {
            assert(children.isEmpty,
                "Cannot set measure function: Nodes with measure functions cannot have children.")
            layoutType = .text
        }
        _measure = value
        return self
    }

    @discardableResult
    public func baseline(_ value: FlexBaselineMethod?) -> FlexLayout {
        _baseline = value
        return self
    }
}
