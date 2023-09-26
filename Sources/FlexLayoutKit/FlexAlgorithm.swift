import Foundation
import CoreGraphics

// YGCollectFlexItemsRowValues
// TODO: struct
final class CollectFlexItems {
    var itemsOnLine: Int = 0
    var sizeConsumedOnCurrentLine: Double = 0.0
    var totalFlexGrowFactors: Double = 0.0
    var totalFlexShrinkScaledFactors: Double = 0.0
    var endOfLineIndex: Int = 0
    var relativeChildren: [FlexLayout] = []
    var remainingFreeSpace: Double = 0.0
    var mainDim: Double = 0.0
    var crossDim: Double = 0.0
}

enum LayoutReason: String {
    case initial
    case absLayout
    case stretch
    case multilineStretch
    case flexLayout
    case measureChild
    case absMeasureChild
    case flexMeasure
}

// This is the main routine that implements a subset of the flexbox layout
// algorithm described in the W3C CSS documentation:
// https://www.w3.org/TR/CSS3-flexbox/.
//
// Limitations of this algorithm, compared to the full standard:
//  * Display property is always assumed to be 'flex' except for Text nodes,
//    which are assumed to be 'inline-flex'.
//  * The 'zIndex' property (or any form of z ordering) is not supported. Nodes
//    are stacked in document order.
//  * The 'order' property is not supported. The order of flex items is always
//    defined by document order.
//  * The 'visibility' property is always assumed to be 'visible'. Values of
//    'collapse' and 'hidden' are not supported.
//  * There is no support for forced breaks.
//  * It does not support vertical inline directions (top-to-bottom or
//    bottom-to-top text).
//
// Deviations from standard:
//  * Section 4.5 of the spec indicates that all flex items have a default
//    minimum main size. For text blocks, for example, this is the width of the
//    widest word. Calculating the minimum width is expensive, so we forego it
//    and assume a default minimum main size of 0.
//  * Min/Max sizes in the main axis are not honored when resolving flexible
//    lengths.
//  * The spec indicates that the default value for 'flexDirection' is 'row',
//    but the algorithm below assumes a default of 'column'.
//
// Input parameters:
//    - node: current node to be sized and layed out
//    - availableWidth & availableHeight: available size to be used for sizing
//      the node or YGUndefined if the size is not available; interpretation
//      depends on layout flags
//    - ownerDirection: the inline (text) direction within the owner
//      (left-to-right or right-to-left)
//    - widthMeasureMode: indicates the sizing rules for the width (see below
//      for explanation)
//    - heightMeasureMode: indicates the sizing rules for the height (see below
//      for explanation)
//    - performLayout: specifies whether the caller is interested in just the
//      dimensions of the node or it requires the entire node and its subtree to
//      be layed out (with final positions)
//
// Details:
//    This routine is called recursively to lay out subtrees of flexbox
//    nodes. It uses the information in node.style, which is treated as a
//    read-only input. It is responsible for setting the layout.direction and
//    layout.measuredDimensions fields for the input node as well as the
//    layout.position and layout.lineIndex fields for its child nodes. The
//    layout.measuredDimensions field includes any border or padding for the
//    node but does not include margins.
//
//    The spec describes four different layout modes: "fill available", "max
//    content", "min content", and "fit content". Of these, we don't use "min
//    content" because we don't support default minimum main sizes (see above
//    for details). Each of our measure modes maps to a layout mode from the
//    spec (https://www.w3.org/TR/CSS3-sizing/#terms):
//      - YGMeasureModeUndefined: max content
//      - YGMeasureModeExactly: fill available
//      - YGMeasureModeAtMost: fit content
//
//    When calling YGNodelayoutImpl and YGLayoutNodeInternal, if the caller
//    passes an available size of undefined then it must also pass a measure
//    mode of YGMeasureModeUndefined in that dimension.
//
struct FlexAlgorithm { // YGNodelayoutImpl
    let availableWidth: Double
    let availableHeight: Double
    let ownerDirection: Direction
    let widthMeasureMode: MeasureMode
    let heightMeasureMode: MeasureMode
    let ownerWidth: Double
    let ownerHeight: Double
    let performLayout: Bool

    let node: FlexLayout
    @inline(__always)
    var style: FlexStyle {
        node.style
    }

    let direction: Direction
    let mainAxis: FlexDirection
    let crossAxis: FlexDirection
    let isMainAxisRow: Bool
    let isNodeFlexWrap: Bool
    let mainAxisOwnerSize: Double
    let crossAxisOwnerSize: Double
    let totalLeadingCross: Double
    // paddingAndBorderAxisMain
    let totalInnerMain: Double
    // paddingAndBorderAxisCross
    let totalInnerCross: Double
    // paddingAndBorderAxisRow
    let totalInnerRow: Double
    // paddingAndBorderAxisColumn
    let totalInnerColumn: Double
    let marginRow: Double
    let marginColumn: Double

    var mainMeasureMode: MeasureMode
    var crossMeasureMode: MeasureMode
    // for step2
    var availableInnerWidth: Double = 0.0
    var availableInnerHeight: Double = 0.0
    var availableInnerMain: Double = 0.0
    var availableInnerCross: Double = 0.0
    // for step3
    var totalOuterFlexBasis: Double = 0.0
    var flexBasisOverflows = false
    // for step4
    var totalLineCrossDim: Double = 0.0
    var maxLineMainDim: Double = 0.0
    // for step6
    var containerCrossAxis: Double = 0.0

    // STEP 1: CALCULATE VALUES FOR REMAINDER OF ALGORITHM
    init(for layout: FlexLayout, ownerDirection: Direction, availableWidth: Double, availableHeight: Double,
        widthMeasureMode: MeasureMode, heightMeasureMode: MeasureMode, ownerWidth: Double, ownerHeight: Double,
        performLayout: Bool) {
        self.availableWidth = availableWidth
        self.availableHeight = availableHeight
        self.ownerDirection = ownerDirection
        self.widthMeasureMode = widthMeasureMode
        self.heightMeasureMode = heightMeasureMode
        self.ownerWidth = ownerWidth
        self.ownerHeight = ownerHeight
        self.performLayout = performLayout

        node = layout
        direction = node.style.resolveDirection(by: ownerDirection)

        mainAxis = node.style.flexDirection.resolve(by: direction)
        crossAxis = mainAxis.cross(by: direction)
        isMainAxisRow = mainAxis.isRow
        isNodeFlexWrap = node.style.wrapped
        mainAxisOwnerSize = isMainAxisRow ? ownerWidth : ownerHeight
        crossAxisOwnerSize = isMainAxisRow ? ownerHeight : ownerWidth

        // leadingPaddingAndBorderCross
        totalLeadingCross = node.style.totalLeadingSize(for: crossAxis, width: ownerWidth)
        // trailingPaddingAndBorderCross
        let totalTrailingCross = node.style.totalTrailingSize(for: crossAxis, width: ownerWidth)
        // paddingAndBorderAxisMain
        totalInnerMain = node.style.totalInnerSize(for: mainAxis, width: ownerWidth)
        // paddingAndBorderAxisCross
        totalInnerCross = totalLeadingCross + totalTrailingCross
        // paddingAndBorderAxisRow
        totalInnerRow = isMainAxisRow ? totalInnerMain : totalInnerCross
        // paddingAndBorderAxisColumn
        totalInnerColumn = isMainAxisRow ? totalInnerCross : totalInnerMain
        // marginAxisRow
        marginRow = node.style.totalOuterSize(for: .row, width: ownerWidth)
        // marginAxisColumn
        marginColumn = node.style.totalOuterSize(for: .column, width: ownerWidth)

        // measureModeMainDim
        mainMeasureMode = isMainAxisRow ? widthMeasureMode : heightMeasureMode
        // measureModeCrossDim
        crossMeasureMode = isMainAxisRow ? heightMeasureMode : widthMeasureMode
    }

    mutating func steps() {
        step2()
        step3()
        step4()
        step9()
        step10()
        step11()
    }

    // STEP 2: DETERMINE AVAILABLE SIZE IN MAIN AND CROSS DIRECTIONS
    @inline(__always)
    private mutating func step2() {
        availableInnerWidth = availableInnerSize(isWidth: true, availableSize: availableWidth - marginRow,
            innerSize: totalInnerRow, ownerSize: ownerWidth)
        availableInnerHeight = availableInnerSize(isWidth: false, availableSize: availableHeight - marginColumn,
            innerSize: totalInnerColumn, ownerSize: ownerHeight)
        availableInnerMain = isMainAxisRow ? availableInnerWidth : availableInnerHeight
        availableInnerCross = isMainAxisRow ? availableInnerHeight : availableInnerWidth
    }

    // STEP 3: DETERMINE FLEX BASIS FOR EACH ITEM
    @inline(__always)
    private mutating func step3() {
        totalOuterFlexBasis = computeFlexBasis()
        flexBasisOverflows = mainMeasureMode.isUndefined ? false : totalOuterFlexBasis > availableInnerWidth
        if isNodeFlexWrap && flexBasisOverflows && mainMeasureMode.isAtMost {
            mainMeasureMode = MeasureMode.exactly
        }
    }

    // STEP 4: COLLECT FLEX ITEMS INTO FLEX LINES
    @inline(__always)
    private mutating func step4() {
        // Indexes of children that represent the first and last items in the line.
        var startOfLineIndex = 0
        var endOfLineIndex = 0
        // Number of lines.
        var lineCount = 0
        var items = CollectFlexItems()
        let childCount = node.children.count
        while endOfLineIndex < childCount {
            items = calculateCollectFlexItems(lineCount, startOfLineIndex)
            endOfLineIndex = items.endOfLineIndex
            // If we don't need to measure the cross axis, we can skip the entire flex step.
            let canSkipFlex = !performLayout && crossMeasureMode.isExactly
            step5(items: items, canSkipFlex: canSkipFlex)
            step6(items: items, startOfLineIndex)
            step7(items: items, startOfLineIndex, endOfLineIndex)
            lineCount += 1
            startOfLineIndex = endOfLineIndex
        }
        step8(lineCount, node.isBaselineLayout)
    }

    // STEP 5: RESOLVING FLEXIBLE LENGTHS ON MAIN AXIS
    // Calculate the remaining available space that needs to be allocated. If
    // the main dimension size isn't known, it is computed based on the line
    // length, so there's no more space left to distribute.
    @inline(__always)
    private mutating func step5(items: CollectFlexItems, canSkipFlex: Bool) {
        var sizeBasedOnContent = false
        // If we don't measure with exact main dimension we want to ensure we don't violate min and max
        if !mainMeasureMode.isExactly {
            let minInnerWidth = style.minWidth.resolve(by: ownerWidth) - totalInnerRow
            let maxInnerWidth = style.computedMaxWidth.resolve(by: ownerWidth) - totalInnerRow
            let minInnerHeight = style.minHeight.resolve(by: ownerHeight) - totalInnerColumn
            let maxInnerHeight = style.computedMaxHeight.resolve(by: ownerHeight) - totalInnerColumn
            let minInnerMain = isMainAxisRow ? minInnerWidth : minInnerHeight
            let maxInnerMain = isMainAxisRow ? maxInnerWidth : maxInnerHeight
            if !minInnerMain.isNaN && items.sizeConsumedOnCurrentLine < minInnerMain {
                availableInnerMain = minInnerMain
            } else if !maxInnerMain.isNaN && items.sizeConsumedOnCurrentLine > maxInnerMain {
                availableInnerMain = maxInnerMain
            } else {
                if items.totalFlexGrowFactors == 0 || node.computedFlexGrow == 0 {
                    availableInnerMain = items.sizeConsumedOnCurrentLine
                }
                sizeBasedOnContent = true
            }
        }
        if !sizeBasedOnContent && !availableInnerMain.isNaN {
            items.remainingFreeSpace = availableInnerMain - items.sizeConsumedOnCurrentLine
        } else if items.sizeConsumedOnCurrentLine < 0 {
            items.remainingFreeSpace = 0 - items.sizeConsumedOnCurrentLine
        }
        if !canSkipFlex {
            resolveFlexibleLength(items: items)
        }
        node.box.hasOverflow = node.box.hasOverflow || (items.remainingFreeSpace < 0)
    }

    // STEP 6: MAIN-AXIS JUSTIFICATION & CROSS-AXIS SIZE DETERMINATION
    @inline(__always)
    private mutating func step6(items: CollectFlexItems, _ startOfLineIndex: Int) {
        justifyMainAxis(items, startOfLineIndex)
        containerCrossAxis = availableInnerCross
        if !crossMeasureMode.isExactly {
            containerCrossAxis = style.bound(axis: crossAxis, value: items.crossDim + totalInnerCross,
                axisSize: crossAxisOwnerSize, width: ownerWidth) - totalInnerCross
        }
        if !isNodeFlexWrap && crossMeasureMode.isExactly {
            items.crossDim = availableInnerCross
        }
        // Clamp to the min/max size specified on the container.
        items.crossDim = style.bound(axis: crossAxis, value: items.crossDim + totalInnerCross,
            axisSize: crossAxisOwnerSize, width: ownerWidth) - totalInnerCross
    }

    // STEP 7: CROSS-AXIS ALIGNMENT
    // We can skip child alignment if we're just measuring the container.
    @inline(__always)
    private mutating func step7(items: CollectFlexItems, _ startOfLineIndex: Int, _ endOfLineIndex: Int) {
        if !performLayout {
            totalLineCrossDim += items.crossDim
            maxLineMainDim = max(maxLineMainDim, items.mainDim)
            return
        }
        for child: FlexLayout in node.children[startOfLineIndex..<endOfLineIndex] where !child.style.hidden {
            if child.style.absoluteLayout {
                // If the child is absolutely positioned and has a top/left/bottom/right
                // set, override all the previously computed positions to set it correctly.
                // isLeadingPositionDefined
                let leadingDefined = child.style.isLeadingPositionDefined(for: crossAxis)
                if leadingDefined {
                    child.box.position[crossAxis] = style.leadingBorder(for: crossAxis) +
                        child.style.leadingPosition(for: crossAxis, size: availableInnerCross) +
                        child.style.leadingMargin(for: crossAxis, width: availableInnerWidth)
                }
                if !leadingDefined || child.box.position.leading(direction: crossAxis).isNaN {
                    // If leading position is not defined or calculations result in Nan, default to border + margin
                    child.box.position[crossAxis] = style.leadingBorder(for: crossAxis) +
                        child.style.leadingMargin(for: crossAxis, width: availableInnerWidth)
                }
            } else {
                var leadingCrossDim = totalLeadingCross
                let alignItem = node.computedAlignItem(child: child)
                if alignItem == AlignItems.stretch &&
                    child.style.margin.leading(direction: crossAxis) != StyleValue.auto &&
                    child.style.margin.trailing(direction: crossAxis) != StyleValue.auto {
                    if !child.isDimensionDefined(for: crossAxis, size: availableInnerCross) {
                        var childMainSize: Double = child.box.measuredDimension(for: mainAxis)
                        var childCrossSize: Double = 0.0
                        let aspectRatio = child.style.aspectRatio
                        if aspectRatio.isNaN {
                            childCrossSize = items.crossDim
                        } else {
                            childCrossSize = child.style.totalOuterSize(for: crossAxis, width: availableInnerWidth)
                            if isMainAxisRow {
                                childCrossSize += childMainSize / aspectRatio
                            } else {
                                childCrossSize += childMainSize * aspectRatio
                            }
                        }
                        childMainSize += child.style.totalOuterSize(for: mainAxis, width: availableInnerWidth)
                        var childMainMeasureMode = MeasureMode.exactly
                        var childCrossMeasureMode = MeasureMode.exactly
                        (childMainMeasureMode, childMainSize) = child.style.constrainMaxSize(axis: mainAxis,
                            parentAxisSize: availableInnerMain, parentWidth: availableInnerWidth,
                            mode: childMainMeasureMode, size: childMainSize)
                        (childCrossMeasureMode, childCrossSize) = child.style.constrainMaxSize(axis: crossAxis,
                            parentAxisSize: availableInnerCross, parentWidth: availableInnerWidth,
                            mode: childCrossMeasureMode, size: childCrossSize)
                        let childWidth = isMainAxisRow ? childMainSize : childCrossSize
                        let childHeight = isMainAxisRow ? childCrossSize : childMainSize
                        let childWidthMeasureMode: MeasureMode =
                            childWidth.isNaN ? MeasureMode.undefined : MeasureMode.exactly
                        let childHeightMeasureMode: MeasureMode =
                            childHeight.isNaN ? MeasureMode.undefined : MeasureMode.exactly
                        _ = child.layoutInternal(width: childWidth, height: childHeight,
                            widthMode: childWidthMeasureMode, heightMode: childHeightMeasureMode,
                            parentWidth: availableInnerWidth, parentHeight: availableInnerHeight,
                            direction: direction, layout: true, reason: .stretch)
                    }
                } else {
                    let remainingCrossDim = containerCrossAxis -
                        child.dimensionWithMargin(for: crossAxis, width: availableInnerWidth)
                    if child.style.margin.leading(direction: crossAxis) == StyleValue.auto &&
                        child.style.margin.trailing(direction: crossAxis) == StyleValue.auto {
                        leadingCrossDim += max(0, remainingCrossDim / 2)
                    } else if child.style.margin.trailing(direction: crossAxis) == StyleValue.auto {
                        // No-op
                    } else if child.style.margin.leading(direction: crossAxis) == StyleValue.auto {
                        leadingCrossDim += max(0, remainingCrossDim)
                    } else if alignItem == AlignItems.start {
                        // No-op
                    } else if alignItem == AlignItems.center {
                        leadingCrossDim += remainingCrossDim / 2
                    } else {
                        leadingCrossDim += remainingCrossDim
                    }
                }
                child.box.position[crossAxis] += totalLineCrossDim + leadingCrossDim
            }
        }
        totalLineCrossDim += items.crossDim
        maxLineMainDim = max(maxLineMainDim, items.mainDim)
    }

    // STEP 8: MULTI-LINE CONTENT ALIGNMENT
    // currentLead stores the size of the cross dim
    @inline(__always)
    private mutating func step8(_ lineCount: Int, _ isBaselineLayout: Bool) {
        guard performLayout && (lineCount > 1 || isBaselineLayout) else {
            return
        }
        var crossDimLead: Double = 0.0
        var currentLead: Double = totalLeadingCross
        if !availableInnerCross.isNaN {
            let remainingAlignContentDim = availableInnerCross - totalLineCrossDim
            switch style.alignContent {
            case .start:
                break
            case .end:
                currentLead += remainingAlignContentDim
            case .center:
                currentLead += remainingAlignContentDim / 2
            case .stretch:
                if availableInnerCross > totalLineCrossDim {
                    crossDimLead = remainingAlignContentDim / Double(lineCount)
                }
            case .spaceAround:
                if availableInnerCross > totalLineCrossDim {
                    currentLead += remainingAlignContentDim / Double(2 * lineCount)
                    if lineCount > 1 {
                        crossDimLead = remainingAlignContentDim / Double(lineCount)
                    }
                } else {
                    currentLead += remainingAlignContentDim / 2
                }
            case .spaceBetween:
                if availableInnerCross > totalLineCrossDim && lineCount > 1 {
                    crossDimLead = remainingAlignContentDim / Double(lineCount - 1)
                }
            }
        }
        var endIndex = 0
        for i in 0..<lineCount {
            let startIndex = endIndex
            // compute the line's height and find the endIndex
            var lineHeight = 0.0
            var maxAscentForCurrentLine = 0.0
            var maxDescentForCurrentLine = 0.0
            var ii = startIndex
            for child: FlexLayout in node.children[startIndex...] {
                if child.style.hidden {
                    ii += 1
                    continue
                }
                if !child.style.absoluteLayout {
                    if child.lineIndex != i {
                        break
                    }
                    if child.box.isLayoutDimensionDefined(for: crossAxis) {
                        lineHeight = max(lineHeight,
                            child.box.measuredDimension(for: crossAxis) +
                                child.style.totalOuterSize(for: crossAxis, width: availableInnerWidth))
                    }
                    if node.computedAlignItem(child: child) == AlignItems.baseline {
                        let ascent: Double = child.baseline() +
                            child.style.leadingMargin(for: .column, width: availableInnerWidth)
                        let descent: Double = child.box.measuredDimension(for: .column) - ascent +
                            child.style.totalOuterSize(for: .column, width: availableInnerWidth)
                        maxAscentForCurrentLine = max(maxAscentForCurrentLine, ascent)
                        maxDescentForCurrentLine = max(maxDescentForCurrentLine, descent)
                        lineHeight = max(lineHeight, maxAscentForCurrentLine + maxDescentForCurrentLine)
                    }
                }
                ii += 1
            }
            endIndex = ii
            lineHeight += crossDimLead
            if performLayout {
                for child: FlexLayout in node.children[startIndex..<endIndex]
                    where !child.style.hidden && !child.style.absoluteLayout {
                    switch node.computedAlignItem(child: child) {
                    case .start:
                        child.box.position[crossAxis] = currentLead +
                            child.style.leadingMargin(for: crossAxis, width: availableInnerWidth)
                    case .end:
                        child.box.position[crossAxis] = currentLead + lineHeight -
                            child.style.trailingMargin(for: crossAxis, width: availableInnerWidth) -
                            child.box.measuredDimension(for: crossAxis)
                    case .center:
                        child.box.position[crossAxis] = currentLead +
                            (lineHeight - child.box.measuredDimension(for: crossAxis)) / 2
                    case .stretch:
                        child.box.position[crossAxis] = currentLead +
                            child.style.leadingMargin(for: crossAxis, width: availableInnerWidth)
                        if !child.isDimensionDefined(for: crossAxis, size: availableInnerCross) {
                            let childWidth: Double
                            let childHeight: Double
                            if isMainAxisRow {
                                childWidth = child.box.measuredWidth +
                                    child.style.totalOuterSize(for: mainAxis, width: availableInnerWidth)
                                childHeight = lineHeight
                            } else {
                                childWidth = lineHeight
                                childHeight = child.box.measuredHeight +
                                    child.style.totalOuterSize(for: crossAxis, width: availableInnerWidth)
                            }
                            // !(a == b && c == d) => a != b || c != d
                            if childWidth != child.box.measuredWidth || childHeight != child.box.measuredHeight {
                                _ = child.layoutInternal(width: childWidth, height: childHeight,
                                    widthMode: MeasureMode.exactly, heightMode: MeasureMode.exactly,
                                    parentWidth: availableInnerWidth, parentHeight: availableInnerHeight,
                                    direction: direction, layout: true, reason: .multilineStretch)
                            }
                        }
                    case .baseline:
                        child.box.position.top = currentLead + maxAscentForCurrentLine -
                            child.baseline() + child.style.leadingPosition(for: .column, size: availableInnerCross)
                    }
                }
            }
            currentLead += lineHeight
        }
    }

    // STEP 9: COMPUTING FINAL DIMENSIONS
    @inline(__always)
    private mutating func step9() {
        node.box.measuredWidth = style.bound(axis: FlexDirection.row,
            value: availableWidth - marginRow, axisSize: ownerWidth, width: ownerWidth)
        node.box.measuredHeight = style.bound(axis: FlexDirection.column,
            value: availableHeight - marginColumn, axisSize: ownerHeight, width: ownerWidth)
        if mainMeasureMode.isUndefined || (!style.overflow.scrolled && mainMeasureMode.isAtMost) {
            let size: Double = style.bound(axis: mainAxis, value: maxLineMainDim,
                axisSize: mainAxisOwnerSize, width: ownerWidth)
            node.box.setMeasuredDimension(for: mainAxis, size: size)
        } else if mainMeasureMode.isAtMost && style.overflow.scrolled {
            var size: Double = style.bound(for: mainAxis, value: maxLineMainDim, size: mainAxisOwnerSize)
            size = max(min(availableInnerMain + totalInnerMain, size), totalInnerMain)
            node.box.setMeasuredDimension(for: mainAxis, size: size)
        }
        if crossMeasureMode.isUndefined || (!style.overflow.scrolled && crossMeasureMode.isAtMost) {
            let size: Double = style.bound(axis: crossAxis, value: totalLineCrossDim + totalInnerCross,
                axisSize: crossAxisOwnerSize, width: ownerWidth)
            node.box.setMeasuredDimension(for: crossAxis, size: size)
        } else if crossMeasureMode.isAtMost && style.overflow.scrolled {
            var size: Double = style.bound(for: crossAxis, value: totalLineCrossDim + totalInnerCross,
                size: crossAxisOwnerSize)
            size = max(min(availableInnerCross + totalInnerCross, size), totalInnerCross)
            node.box.setMeasuredDimension(for: crossAxis, size: size)
        }
        guard performLayout && style.flexWrap == FlexWrap.wrapReverse else {
            return
        }
        for child in node.children where !child.style.absoluteLayout {
            child.box.position[crossAxis] = node.box.measuredDimension(for: crossAxis) -
                child.box.position[crossAxis] -
                child.box.measuredDimension(for: crossAxis)
        }
    }

    // STEP 10: SIZING AND POSITIONING ABSOLUTE CHILDREN
    @inline(__always)
    private func step10() {
        guard performLayout else {
            return
        }
        for child in node.children where child.style.absoluteLayout {
            node.absoluteLayout(child: child, width: availableInnerWidth,
                widthMode: (isMainAxisRow ? mainMeasureMode : crossMeasureMode),
                height: availableInnerHeight, direction: direction)
        }
    }

    // STEP 11: SETTING TRAILING POSITIONS FOR CHILDREN
    @inline(__always)
    private func step11() {
        let needsMainTrailingPos = mainAxis.isReversed
        let needsCrossTrailingPos = crossAxis.isReversed
        guard needsMainTrailingPos || needsCrossTrailingPos else {
            return
        }
        for child: FlexLayout in node.children where !child.style.hidden {
            if needsMainTrailingPos {
                node.setChildTrailingPosition(child: child, direction: mainAxis)
            }
            if needsCrossTrailingPos {
                node.setChildTrailingPosition(child: child, direction: crossAxis)
            }
        }
    }

    // YGNodeComputeFlexBasisForChildren
    private mutating func computeFlexBasis() -> Double {
        var totalOuterFlexBasis: Double = 0.0
        // If there is only one child with flexGrow + flexShrink it means we can set
        // the computedFlexBasis to 0 instead of measuring and shrinking / flexing the
        // child to exactly match the remaining space
        let singleFlexChild: FlexLayout? = mainMeasureMode.isExactly ? node.findFlexChild() : nil
        for child: FlexLayout in node.children {
            child.resolveDimensions()
            if child.style.hidden {
                child.zeroLayout()
                child.hasNewLayout = true
                child.isDirty = false
                continue
            }
            if performLayout {
                // Set the initial position (relative to the owner).
                let childDirection = child.style.resolveDirection(by: direction)
                let mainSize: Double = mainAxis.isRow ? availableInnerWidth : availableInnerHeight
                let crossSize: Double = mainAxis.isRow ? availableInnerHeight : availableInnerWidth
                child.setPosition(for: childDirection, main: mainSize, cross: crossSize,
                    width: availableInnerWidth)
            }
            if child.style.absoluteLayout {
                continue
            }
            if child == singleFlexChild {
                // TODO: setLayoutComputedFlexBasisGeneration
                child.box.computedFlexBasis = 0.0
            } else {
                node.resolveFlexBasis(for: child,
                    width: availableInnerWidth, widthMode: widthMeasureMode,
                    height: availableInnerHeight, heightMode: heightMeasureMode,
                    parentWidth: availableInnerWidth, parentHeight: availableInnerHeight,
                    direction: direction)
            }
            totalOuterFlexBasis += child.box.computedFlexBasis +
                child.style.totalOuterSize(for: mainAxis, width: availableInnerWidth)
        }
        return totalOuterFlexBasis
    }

    // YGResolveFlexibleLength
    private func resolveFlexibleLength(items: CollectFlexItems) {
        let originalFreeSpace = items.remainingFreeSpace
        distributeFreeSpace(items)
        let size = distributeFreeSpace2(items)
        items.remainingFreeSpace = originalFreeSpace - size
    }

    // YGDistributeFreeSpaceFirstPass
    private func distributeFreeSpace(_ items: CollectFlexItems) {
        var flexShrinkScaledFactor = 0.0
        var flexGrowFactor = 0.0
        var baseMainSize = 0.0
        var boundMainSize = 0.0
        var deltaFreeSpace = 0.0
        for child in items.relativeChildren {
            let childFlexBasis = child.style.bound(for: mainAxis,
                value: child.box.computedFlexBasis, size: mainAxisOwnerSize)
            if items.remainingFreeSpace < 0 {
                flexShrinkScaledFactor = (0 - child.computedFlexShrink) * childFlexBasis
                // Is this child able to shrink?
                if !flexShrinkScaledFactor.isNaN && flexShrinkScaledFactor != 0 {
                    baseMainSize = childFlexBasis + items.remainingFreeSpace /
                        items.totalFlexShrinkScaledFactors * flexShrinkScaledFactor
                    boundMainSize = child.style.bound(axis: mainAxis, value: baseMainSize,
                        axisSize: availableInnerMain, width: availableInnerWidth)
                    if !baseMainSize.isNaN && !boundMainSize.isNaN && baseMainSize != boundMainSize {
                        // By excluding this item's size and flex factor from remaining, this
                        // item's min/max constraints should also trigger in the second pass
                        // resulting in the item's size calculation being identical in the
                        // first and second passes.
                        deltaFreeSpace += boundMainSize - childFlexBasis
                        items.totalFlexShrinkScaledFactors -= flexShrinkScaledFactor
                    }
                }
            } else if !items.remainingFreeSpace.isNaN && items.remainingFreeSpace > 0 {
                flexGrowFactor = child.computedFlexGrow
                // Is this child able to grow?
                if !flexGrowFactor.isNaN && flexGrowFactor != 0 {
                    baseMainSize = childFlexBasis + items.remainingFreeSpace /
                        items.totalFlexGrowFactors * flexGrowFactor
                    boundMainSize = child.style.bound(axis: mainAxis, value: baseMainSize,
                        axisSize: availableInnerMain, width: availableInnerWidth)
                    if !baseMainSize.isNaN && !boundMainSize.isNaN && baseMainSize != boundMainSize {
                        deltaFreeSpace += boundMainSize - childFlexBasis
                        items.totalFlexGrowFactors -= flexGrowFactor
                    }
                }
            }
        }
        items.remainingFreeSpace -= deltaFreeSpace
    }

    // YGDistributeFreeSpaceSecondPass
    private func distributeFreeSpace2(_ items: CollectFlexItems) -> Double {
        var flexShrinkScaledFactor = 0.0
        var flexGrowFactor = 0.0
        var deltaFreeSpace = 0.0
        for child in items.relativeChildren {
            let childFlexBasis = child.style.bound(for: mainAxis,
                value: child.box.computedFlexBasis, size: mainAxisOwnerSize)
            var updatedMainSize = childFlexBasis
            if !items.remainingFreeSpace.isNaN && items.remainingFreeSpace < 0 {
                flexShrinkScaledFactor = (0 - child.computedFlexShrink) * childFlexBasis
                // Is this child able to shrink?
                if flexShrinkScaledFactor != 0 {
                    let childSize: Double
                    if !items.totalFlexShrinkScaledFactors.isNaN && items.totalFlexShrinkScaledFactors == 0 {
                        childSize = childFlexBasis + flexShrinkScaledFactor
                    } else {
                        childSize = childFlexBasis + items.remainingFreeSpace /
                            items.totalFlexShrinkScaledFactors * flexShrinkScaledFactor
                    }
                    updatedMainSize = child.style.bound(axis: mainAxis, value: childSize,
                        axisSize: availableInnerMain, width: availableInnerWidth)
                }
            } else if !items.remainingFreeSpace.isNaN && items.remainingFreeSpace > 0 {
                flexGrowFactor = child.computedFlexGrow
                // Is this child able to grow?
                if !flexGrowFactor.isNaN && flexGrowFactor != 0 {
                    updatedMainSize = child.style.bound(axis: mainAxis,
                        value: childFlexBasis + items.remainingFreeSpace / items.totalFlexGrowFactors * flexGrowFactor,
                        axisSize: availableInnerMain, width: availableInnerWidth)
                }
            }
            deltaFreeSpace += updatedMainSize - childFlexBasis
            let marginMain = child.style.totalOuterSize(for: mainAxis, width: availableInnerWidth)
            let marginCross = child.style.totalOuterSize(for: crossAxis, width: availableInnerWidth)
            var childCrossSize = 0.0
            var childMainSize = updatedMainSize + marginMain
            var childCrossMeasureMode = MeasureMode.undefined
            var childMainMeasureMode = MeasureMode.exactly
            if !child.style.aspectRatio.isNaN {
                let ratio = child.style.aspectRatio
                if isMainAxisRow {
                    childCrossSize = (childMainSize - marginMain) / ratio
                } else {
                    childCrossSize = (childMainSize - marginMain) * ratio
                }
                childCrossMeasureMode = MeasureMode.exactly
                childCrossSize += marginCross
            } else if !availableInnerCross.isNaN &&
                !child.isDimensionDefined(for: crossAxis, size: availableInnerCross) &&
                crossMeasureMode.isExactly &&
                !(isNodeFlexWrap && flexBasisOverflows) &&
                node.computedAlignItem(child: child) == AlignItems.stretch &&
                child.style.margin.leading(direction: crossAxis) != StyleValue.auto &&
                child.style.margin.trailing(direction: crossAxis) != StyleValue.auto {
                childCrossSize = availableInnerCross
                childCrossMeasureMode = MeasureMode.exactly
            } else if !child.isDimensionDefined(for: crossAxis, size: availableInnerCross) {
                childCrossSize = availableInnerCross
                childCrossMeasureMode = childCrossSize.isNaN ? MeasureMode.undefined : MeasureMode.atMost
            } else {
                let size: StyleValue = child.computedDimension(by: crossAxis)
                let flag: Bool
                if case StyleValue.percentage = size {
                    flag = true
                } else {
                    flag = false
                }
                childCrossSize = size.resolve(by: availableInnerCross) + marginCross
                // isLoosePercentageMeasurement
                let loose = flag && !crossMeasureMode.isExactly
                childCrossMeasureMode = (childCrossSize.isNaN || loose) ? MeasureMode.undefined : MeasureMode.exactly
            }
            (childMainMeasureMode, childMainSize) = child.style.constrainMaxSize(axis: mainAxis,
                parentAxisSize: availableInnerMain, parentWidth: availableInnerWidth,
                mode: childMainMeasureMode, size: childMainSize)
            (childCrossMeasureMode, childCrossSize) = child.style.constrainMaxSize(axis: crossAxis,
                parentAxisSize: availableInnerCross, parentWidth: availableInnerWidth,
                mode: childCrossMeasureMode, size: childCrossSize)
            let requiresStretchLayout = !child.isDimensionDefined(for: crossAxis, size: availableInnerCross) &&
                node.computedAlignItem(child: child) == AlignItems.stretch &&
                child.style.margin.leading(direction: crossAxis) != StyleValue.auto &&
                child.style.margin.trailing(direction: crossAxis) != StyleValue.auto
            let childWidth = isMainAxisRow ? childMainSize : childCrossSize
            let childHeight = !isMainAxisRow ? childMainSize : childCrossSize
            let childWidthMeasureMode = isMainAxisRow ? childMainMeasureMode : childCrossMeasureMode
            let childHeightMeasureMode = isMainAxisRow ? childCrossMeasureMode : childMainMeasureMode
            _ = child.layoutInternal(width: childWidth, height: childHeight,
                widthMode: childWidthMeasureMode, heightMode: childHeightMeasureMode,
                parentWidth: availableInnerWidth, parentHeight: availableInnerHeight,
                direction: direction, layout: performLayout && !requiresStretchLayout,
                reason: .flexLayout)
            node.box.hasOverflow = node.box.hasOverflow || child.box.hasOverflow
        }
        return deltaFreeSpace
    }

    // YGCalculateCollectFlexItemsRowValues
    // This function assumes that all the children of node have their
    // computedFlexBasis properly computed(To do this use
    // YGNodeComputeFlexBasisForChildren function). This function calculates
    // YGCollectFlexItemsRowMeasurement
    private func calculateCollectFlexItems(_ lineCount: Int, _ startOfLineIndex: Int) -> CollectFlexItems {
        let items = CollectFlexItems()
        items.relativeChildren.reserveCapacity(node.children.count)
        // sizeConsumedOnCurrentLineIncludingMinConstraint
        var sizeConsumed: Double = 0.0
        let mainAxis = style.flexDirection.resolve(by: ownerDirection)
        // Add items to the current line until it's full or we run out of items.
        var endOfLineIndex: Int = startOfLineIndex
        for child in node.children[startOfLineIndex...] {
            if child.style.hidden || child.style.absoluteLayout {
                endOfLineIndex += 1
                continue
            }
            child.lineIndex = lineCount
            let childMarginMain = child.style.totalOuterSize(for: mainAxis, width: availableInnerWidth)
            // flexBasisWithMinAndMaxConstraints
            let flexBasis = child.style.bound(for: mainAxis, value: child.box.computedFlexBasis,
                size: mainAxisOwnerSize)
            // If this is a multi-line flow and this item pushes us over the available
            // size, we've hit the end of the current line. Break out of the loop and
            // lay out the current line.
            if sizeConsumed + flexBasis + childMarginMain > availableInnerMain &&
                   isNodeFlexWrap && items.itemsOnLine > 0 {
                break
            }
            sizeConsumed += flexBasis + childMarginMain
            items.sizeConsumedOnCurrentLine += flexBasis + childMarginMain
            items.itemsOnLine += 1
            if child.flexible {
                items.totalFlexGrowFactors += child.computedFlexGrow
                // Unlike the grow factor, the shrink factor is scaled relative to the child dimension.
                items.totalFlexShrinkScaledFactors += -child.computedFlexShrink * child.box.computedFlexBasis
            }
            items.relativeChildren.append(child)
            endOfLineIndex += 1
        }
        // The total flex factor needs to be floored to 1.
        if items.totalFlexGrowFactors > 0 && items.totalFlexGrowFactors < 1 {
            items.totalFlexGrowFactors = 1
        }
        // The total flex shrink factor needs to be floored to 1.
        if items.totalFlexShrinkScaledFactors > 0 && items.totalFlexShrinkScaledFactors < 1 {
            items.totalFlexShrinkScaledFactors = 1
        }
        items.endOfLineIndex = endOfLineIndex
        return items
    }

    // YGJustifyMainAxis
    private func justifyMainAxis(_ items: CollectFlexItems, _ startOfLineIndex: Int) {
        let leadingInnerMain = style.totalLeadingSize(for: mainAxis, width: ownerWidth)
        let trailingInnerMain = style.totalTrailingSize(for: mainAxis, width: ownerWidth)
        if mainMeasureMode.isAtMost && items.remainingFreeSpace > 0 {
            let minMainSize = style.minDimension(by: mainAxis).resolve(by: mainAxisOwnerSize)
            if !minMainSize.isNaN {
                let minAvailableMain: Double = minMainSize - leadingInnerMain - trailingInnerMain
                // occupiedSpaceByChildNodes
                let occupied: Double = availableInnerMain - items.remainingFreeSpace
                items.remainingFreeSpace = max(0, minAvailableMain - occupied)
            } else {
                items.remainingFreeSpace = 0
            }
        }
        var numberOfAutoMarginsOnCurrentLine: Int = 0
        for child in node.children[startOfLineIndex..<items.endOfLineIndex] where !child.style.absoluteLayout {
            if child.style.margin.leading(direction: mainAxis) == StyleValue.auto {
                numberOfAutoMarginsOnCurrentLine += 1
            }
            if child.style.margin.trailing(direction: mainAxis) == StyleValue.auto {
                numberOfAutoMarginsOnCurrentLine += 1
            }
        }
        var leadingMainDim: Double = 0.0
        var betweenMainDim: Double = 0.0
        if numberOfAutoMarginsOnCurrentLine == 0 {
            switch style.justifyContent {
            case .center:
                leadingMainDim = items.remainingFreeSpace / 2
            case .end:
                leadingMainDim = items.remainingFreeSpace
            case .spaceBetween:
                if items.itemsOnLine > 1 {
                    betweenMainDim = max(items.remainingFreeSpace, 0) / Double(items.itemsOnLine - 1)
                } else {
                    betweenMainDim = 0
                }
            case .spaceEvenly: // Space is distributed evenly across all nodes
                betweenMainDim = items.remainingFreeSpace / Double(items.itemsOnLine + 1)
                leadingMainDim = betweenMainDim
            case .spaceAround:
                betweenMainDim = items.remainingFreeSpace / Double(items.itemsOnLine)
                leadingMainDim = betweenMainDim / 2
            case .start:
                break
            }
        }
        items.mainDim = leadingInnerMain + leadingMainDim
        items.crossDim = 0.0
        let baselineLayout: Bool = node.isBaselineLayout
        var maxAscentForCurrentLine: Double = 0.0
        var maxDescentForCurrentLine: Double = 0.0
        for child: FlexLayout in node.children[startOfLineIndex..<items.endOfLineIndex]
            where !child.style.hidden {
            if child.style.absoluteLayout && child.style.isLeadingPositionDefined(for: mainAxis) {
                if performLayout {
                    // In case the child is position absolute and has left/top being defined,
                    // we override the position to whatever the user said (and margin/border).
                    child.box.position[mainAxis] = style.leadingBorder(for: mainAxis) +
                        child.style.leadingPosition(for: mainAxis, size: availableInnerMain) +
                        child.style.leadingMargin(for: mainAxis, width: availableInnerWidth)
                }
            } else {
                // Now that we placed the node, we need to update the variables.
                // We need to do that only for relative nodes. Absolute nodes do not
                // take part in that phase.
                if !child.style.absoluteLayout {
                    if child.style.margin.leading(direction: mainAxis) == StyleValue.auto {
                        items.mainDim += items.remainingFreeSpace / Double(numberOfAutoMarginsOnCurrentLine)
                    }
                    if performLayout {
                        child.box.position[mainAxis] += items.mainDim
                    }
                    if child.style.margin.trailing(direction: mainAxis) == StyleValue.auto {
                        items.mainDim += items.remainingFreeSpace / Double(numberOfAutoMarginsOnCurrentLine)
                    }
                    let canSkipFlex = !performLayout && crossMeasureMode.isExactly
                    if canSkipFlex {
                        items.mainDim += betweenMainDim + child.box.computedFlexBasis +
                            child.style.totalOuterSize(for: mainAxis, width: availableInnerWidth)
                        items.crossDim = availableInnerCross
                    } else {
                        items.mainDim += betweenMainDim + child.dimensionWithMargin(for: mainAxis, width: availableInnerWidth)
                        if baselineLayout {
                            let ascent = child.baseline() + child.style.leadingMargin(for: .column,
                                width: availableInnerWidth)
                            let descent = child.box.measuredHeight + child.style.totalOuterSize(for: .column,
                                width: availableInnerWidth) - ascent
                            maxAscentForCurrentLine = max(maxAscentForCurrentLine, ascent)
                            maxDescentForCurrentLine = max(maxDescentForCurrentLine, descent)
                        } else {
                            items.crossDim = max(items.crossDim,
                                child.dimensionWithMargin(for: crossAxis, width: availableInnerWidth))
                        }
                    }
                } else if performLayout {
                    child.box.position[mainAxis] += style.leadingBorder(for: mainAxis) + leadingMainDim
                }
            }
        }
        items.mainDim += trailingInnerMain
        if baselineLayout {
            items.crossDim = maxAscentForCurrentLine + maxDescentForCurrentLine
        }
    }

    // YGNodeCalculateAvailableInnerDim
    private func availableInnerSize(isWidth: Bool, availableSize: Double, innerSize: Double,
        ownerSize: Double) -> Double {
        let availableInner = availableSize - innerSize
        // Max dimension overrides predefined dimension value; Min dimension in turn overrides both of the above
        guard !availableInner.isNaN else {
            return availableInner
        }
        // We want to make sure our available height does not violate min and max constraints
        let minSize = isWidth ? style.minWidth.resolve(by: ownerSize) :
            style.minHeight.resolve(by: ownerSize)
        let minInnerSize = minSize.isNaN ? 0.0 : minSize - innerSize
        let maxSize = isWidth ? style.computedMaxWidth.resolve(by: ownerSize) :
            style.computedMaxHeight.resolve(by: ownerSize)
        let maxInnerSize = maxSize.isNaN ? Double.greatestFiniteMagnitude : maxSize - innerSize
        return inner(availableInner, min: minInnerSize, max: maxInnerSize)
    }
}

extension FlexLayout {
    // YGNode::resolveDimension
    func resolveDimensions() {
        if let maxWidth = style.maxWidth {
            resolvedWidth = (maxWidth == style.minWidth) ? maxWidth : style.width
        } else {
            resolvedWidth = style.width
        }
        if let maxHeight = style.maxHeight {
            resolvedHeight = (maxHeight == style.minHeight) ? maxHeight : style.height
        } else {
            resolvedHeight = style.height
        }
    }

    func layoutMode(size: Double, resolvedSize: StyleValue, maxSize: StyleValue,
        direction: FlexDirection) -> (Double, MeasureMode) {
        let result: Double
        let mode: MeasureMode
        if isDimensionDefined(for: direction, size: size) {
            result = resolvedSize.resolve(by: size) + style.totalOuterSize(for: direction, width: size)
            mode = .exactly
        } else if maxSize.resolve(by: size) >= 0.0 {
            result = maxSize.resolve(by: size)
            mode = .atMost
        } else {
            result = size
            mode = result.isNaN ? .undefined : .exactly
        }
        return (result, mode)
    }

    // YGNode::setPosition
    func setPosition(for direction: Direction, main mainSize: Double, cross crossSize: Double,
        width ownerWidth: Double) {
        // Root nodes should be always layouted as LTR, so we don't return negative values.
        let direction = parent != nil ? direction : Direction.ltr
        let mainAxis = style.resolveFlexDirection(by: direction)
        let crossAxis = mainAxis.cross(by: direction)
        // Here we should check for `PositionType.static` and in this case zero inset
        // properties (left, right, top, bottom, begin, end).
        // https://www.w3.org/TR/css-position-3/#valdef-position-static
        let mainPosition = style.relativePosition(for: mainAxis, size: mainSize)
        let crossPosition = style.relativePosition(for: crossAxis, size: crossSize)
        box.setLeadingPosition(for: mainAxis,
            size: style.leadingMargin(for: mainAxis, width: ownerWidth) + mainPosition)
        box.setTrailingPosition(for: mainAxis,
            size: style.trailingMargin(for: mainAxis, width: ownerWidth) + mainPosition)
        box.setLeadingPosition(for: crossAxis,
            size: style.leadingMargin(for: crossAxis, width: ownerWidth) + crossPosition)
        box.setTrailingPosition(for: crossAxis,
            size: style.trailingMargin(for: crossAxis, width: ownerWidth) + crossPosition)
    }

    // YGRoundToPixelGrid
    func roundPosition(scale: Double, absoluteLeft left: Double, absoluteTop top: Double) {
        guard scale != 0.0 else {
            return
        }

        func fn(layout: FlexLayout, scale: Double, left: Double, top: Double) {
            let textLayout = layout.layoutType == LayoutType.text
            let (_left, _top) = layout.box.roundPosition(scale: scale, left: left, top: top, textLayout: textLayout)
            for child in layout.children {
                fn(layout: child, scale: scale, left: _left, top: _top)
            }
        }

        fn(layout: self, scale: scale, left: left, top: top)
    }

    @inline(__always)
    func findFlexChild() -> FlexLayout? {
        var result: FlexLayout?
        for child in children where child.flexible {
            if result != nil || isDoubleEqual(child.computedFlexGrow, to: 0.0) ||
                isDoubleEqual(child.computedFlexShrink, to: 0.0) {
                // There is already a flexible child, or this flexible child doesn't
                // have flexGrow and flexShrink, abort
                result = nil
                break
            } else {
                result = child
            }
        }
        return result
    }

    // YGZeroOutLayoutRecursivly
    func zeroLayout() { // TODO: Update YGZeroOutLayoutRecursivly
        invalidate()
        box.width = 0
        box.height = 0
        hasNewLayout = true
        copyChildrenIfNeeded()
        children.forEach { child in
            child.zeroLayout()
        }
    }

    // YGNodeAlignItem
    func computedAlignItem(child: FlexLayout) -> AlignItems {
        let align = child.style.alignSelf.alignItems ?? style.alignItems
        if align == AlignItems.baseline && style.flexDirection.isColumn {
            return AlignItems.start
        }
        return align
    }

    // YGNodeSetChildTrailingPosition
    func setChildTrailingPosition(child: FlexLayout, direction: FlexDirection) {
        let size = child.box.measuredDimension(for: direction)
        child.box.setTrailingPosition(for: direction, size: box.measuredDimension(for: direction) -
            size - child.box.position[direction])
    }

    // YGNodeDimWithMargin
    @inline(__always)
    func dimensionWithMargin(for direction: FlexDirection, width: Double) -> Double {
        box.measuredDimension(for: direction) + style.totalOuterSize(for: direction, width: width)
    }

    // YGNodeComputeFlexBasisForChild
    // TODO: Update
    func resolveFlexBasis(for child: FlexLayout, width: Double, widthMode: MeasureMode, height: Double,
        heightMode: MeasureMode, parentWidth: Double, parentHeight: Double, direction: Direction) {
        let mainDirection = style.resolveFlexDirection(by: direction)
        let isMainAxisRow = mainDirection.isRow
        let mainDirectionSize = isMainAxisRow ? width : height
        let mainDirectionParentSize = isMainAxisRow ? parentWidth : parentHeight
        var childWidth = 0.0
        var childHeight = 0.0
        var childWidthMeasureMode = MeasureMode.undefined
        var childHeightMeasureMode = MeasureMode.undefined
        let resolvedFlexBasis = child.style.flexBasis.resolve(by: mainDirectionParentSize)
        let isRowStyleDimDefined = child.isDimensionDefined(for: .row, size: parentWidth)
        let isColumnStyleDimDefined = child.isDimensionDefined(for: .column, size: parentHeight)
        if !resolvedFlexBasis.isNaN && !mainDirectionSize.isNaN {
            if child.box.computedFlexBasis.isNaN {
                child.box.computedFlexBasis = max(resolvedFlexBasis,
                    child.style.totalInnerSize(for: mainDirection, width: parentWidth))
            }
        } else if isMainAxisRow && isRowStyleDimDefined {
            // The width is definite, so use that as the flex basis.
            child.box.computedFlexBasis = max(child.resolvedWidth.resolve(by: parentWidth),
                child.style.totalInnerSize(for: .row, width: parentWidth))
        } else if !isMainAxisRow && isColumnStyleDimDefined {
            // The height is definite, so use that as the flex basis.
            child.box.computedFlexBasis = max(child.resolvedHeight.resolve(by: parentHeight),
                child.style.totalInnerSize(for: .column, width: parentWidth))
        } else {
            // Compute the flex basis and hypothetical main size (i.e. the clamped flex basis).
            childWidth = Double.nan
            childHeight = Double.nan
            let marginRow: Double = child.style.totalOuterSize(for: .row, width: parentWidth)
            let marginColumn: Double = child.style.totalOuterSize(for: .column, width: parentWidth)
            if isRowStyleDimDefined {
                childWidth = child.resolvedWidth.resolve(by: parentWidth) + marginRow
                childWidthMeasureMode = MeasureMode.exactly
            }
            if isColumnStyleDimDefined {
                childHeight = child.resolvedHeight.resolve(by: parentWidth) + marginColumn
                childHeightMeasureMode = MeasureMode.exactly
            }
            // The W3C spec doesn't say anything about the 'overflow' property,
            // but all major browsers appear to implement the following logic.
            if !isMainAxisRow && style.overflow.scrolled || !style.overflow.scrolled {
                if childWidth.isNaN && !width.isNaN {
                    childWidth = width
                    childWidthMeasureMode = MeasureMode.atMost
                }
            }
            if isMainAxisRow && style.overflow.scrolled || !style.overflow.scrolled {
                if childHeight.isNaN && !height.isNaN {
                    childHeight = height
                    childHeightMeasureMode = MeasureMode.atMost
                }
            }
            if !child.style.aspectRatio.isNaN {
                if !isMainAxisRow && childWidthMeasureMode.isExactly {
                    childHeight = marginColumn + (childWidth - marginRow) / child.style.aspectRatio
                    childHeightMeasureMode = MeasureMode.exactly
                } else if isMainAxisRow && childHeightMeasureMode.isExactly {
                    childWidth = (childHeight - marginColumn) * child.style.aspectRatio
                    childWidthMeasureMode = MeasureMode.exactly
                }
            }
            // If child has no defined size in the cross axis and is set to stretch, set the cross axis to be measured
            // exactly with the available inner width
            let hasExactWidth: Bool = !width.isNaN && widthMode.isExactly
            let childWidthStretch: Bool = computedAlignItem(child: child) == AlignItems.stretch && !childWidthMeasureMode.isExactly
            if !isMainAxisRow && !isRowStyleDimDefined && hasExactWidth && childWidthStretch {
                childWidth = width
                childWidthMeasureMode = MeasureMode.exactly
                if !child.style.aspectRatio.isNaN {
                    childHeight = (childWidth - marginRow) / child.style.aspectRatio
                    childHeightMeasureMode = MeasureMode.exactly
                }
            }
            let hasExactHeight: Bool = !height.isNaN && heightMode.isExactly
            let childHeightStretch: Bool = computedAlignItem(child: child) == AlignItems.stretch &&
                !childHeightMeasureMode.isExactly
            if isMainAxisRow && !isColumnStyleDimDefined && hasExactHeight && childHeightStretch {
                childHeight = height
                childHeightMeasureMode = MeasureMode.exactly
                if !child.style.aspectRatio.isNaN {
                    childWidth = (childHeight - marginColumn) * child.style.aspectRatio
                    childWidthMeasureMode = MeasureMode.exactly
                }
            }
            (childWidthMeasureMode, childWidth) = child.style.constrainMaxSize(axis: .row,
                parentAxisSize: parentWidth, parentWidth: parentWidth, mode: childWidthMeasureMode, size: childWidth)
            (childHeightMeasureMode, childHeight) = child.style.constrainMaxSize(axis: .column,
                parentAxisSize: parentHeight, parentWidth: parentWidth, mode: childHeightMeasureMode, size: childHeight)
            // Measure the child
            _ = child.layoutInternal(width: childWidth, height: childHeight, widthMode: childWidthMeasureMode,
                heightMode: childHeightMeasureMode, parentWidth: parentWidth, parentHeight: parentHeight,
                direction: direction, layout: false, reason: .measureChild)
            child.box.computedFlexBasis = max(child.box.measuredDimension(for: mainDirection),
                child.style.totalInnerSize(for: mainDirection, width: parentWidth))
        }
    }

    // YGLayoutNodeInternal
    func layoutInternal(width: Double, height: Double, widthMode: MeasureMode, heightMode: MeasureMode,
        parentWidth: Double, parentHeight: Double, direction: Direction, layout: Bool, reason: LayoutReason) -> Bool {
        let layoutNeeded = (isDirty && box.generation != FlexBox.totalGeneration) ||
            box.lastParentDirection != direction
        if layoutNeeded {
            // Invalidate the cached results.
            box.cachedLayout = nil
            box.cachedMeasurements.removeAll()
        }
        var cachedResult: LayoutCache?
        if children.isEmpty && hasMeasureMethod {
            let marginRow = style.totalOuterSize(for: .row, width: parentWidth)
            let marginColumn = style.totalOuterSize(for: .column, width: parentWidth)
            if let layout = box.cachedLayout, layout.validate(width: width, height: height, widthMode: widthMode,
                heightMode: heightMode, marginRow: marginRow, marginColumn: marginColumn, scale: FlexStyle.scale) {
                cachedResult = layout
            } else {
                cachedResult = box.cachedMeasurements.first { cache in
                    cache.validate(width: width, height: height, widthMode: widthMode, heightMode: heightMode,
                        marginRow: marginRow, marginColumn: marginColumn, scale: FlexStyle.scale)
                }
            }
        } else if layout {
            if let layout = box.cachedLayout,
               layout.isEqual(width: width, height: height, widthMode: widthMode, heightMode: heightMode) {
                cachedResult = layout
            }
        } else {
            cachedResult = box.cachedMeasurements.first { cache in
                cache.isEqual(width: width, height: height, widthMode: widthMode, heightMode: heightMode)
            }
        }
        if let result = cachedResult, !layoutNeeded {
            box.measuredWidth = result.computedWidth
            box.measuredHeight = result.computedHeight
        } else {
            layoutImplement(width: width, height: height, widthMode: widthMode, heightMode: heightMode,
                direction: direction, parentWidth: parentWidth, parentHeight: parentHeight, layout: layout)
            box.lastParentDirection = direction
            if cachedResult == nil {
                if box.cachedMeasurements.count > 20 {
                    box.cachedMeasurements.removeFirst(10)
                }
                let result = LayoutCache(width: width, height: height, computedWidth: box.measuredWidth,
                    computedHeight: box.measuredHeight, widthMode: widthMode, heightMode: heightMode)
                if layout {
                    box.cachedLayout = result
                } else {
                    box.cachedMeasurements.append(result)
                }
            }
        }
        if layout {
            box.width = box.measuredWidth
            box.height = box.measuredHeight
            hasNewLayout = true
            isDirty = false
        }
        box.generation = FlexBox.totalGeneration
        return (layoutNeeded || cachedResult == nil)
    }

    // YGNodelayoutImpl
    func layoutImplement(width: Double, height: Double, widthMode: MeasureMode, heightMode: MeasureMode,
        direction: Direction, parentWidth: Double, parentHeight: Double, layout: Bool) {
        assert(width.isNaN && widthMode == .undefined || !width.isNaN,
            "width is indefinite so widthMode must be MeasureMode.undefined")
        assert(height.isNaN && heightMode == .undefined || !height.isNaN,
            "height is indefinite so heightMode must be MeasureMode.undefined")

        // Set the resolved resolution in the node's layout.
        let direction = style.resolveDirection(by: direction)
        box.direction = direction
        let (marginAxisRow, marginAxisColumn) = layoutBox(by: direction, width: parentWidth)

        if hasMeasureMethod {
            measureLayout(width: width - marginAxisRow, height: height - marginAxisColumn, widthMode: widthMode,
                heightMode: heightMode, parentWidth: parentWidth, parentHeight: parentHeight)
            return
        }

        if children.isEmpty {
            emptyLayout(width: width, height: height, widthMode: widthMode, heightMode: heightMode,
                parentWidth: parentWidth, parentHeight: parentHeight)
            return
        }

        // If we're not being asked to perform a full layout we can skip the algorithm if we already know the size
        if !layout && fixedLayout(width: width - marginAxisRow, height: height - marginAxisColumn,
            widthMode: widthMode, heightMode: heightMode, parentWidth: parentWidth, parentHeight: parentHeight) {
            return
        }

        flexLayout(width: width, height: height, direction: direction, widthMode: widthMode,
            heightMode: heightMode, parentWidth: parentWidth, parentHeight: parentHeight, layout: layout)
    }

    // YGNodelayoutImpl
    @inline(__always)
    func layoutBox(by direction: Direction, width: Double) -> (Double, Double) {
        let rowDirection = FlexDirection.row.resolve(by: direction)
        let columnDirection = FlexDirection.column.resolve(by: direction)

        let top = style.leadingMargin(for: columnDirection, width: width)
        let leading = style.leadingMargin(for: rowDirection, width: width)
        let bottom = style.trailingMargin(for: columnDirection, width: width)
        let trailing = style.trailingMargin(for: rowDirection, width: width)
        box.margin.setAll(by: direction, top: top, leading: leading, bottom: bottom, trailing: trailing)

        box.border.setAll(by: direction,
            top: style.leadingBorder(for: columnDirection),
            leading: style.leadingBorder(for: rowDirection),
            bottom: style.trailingBorder(for: columnDirection),
            trailing: style.trailingBorder(for: rowDirection))

        box.padding.setAll(by: direction,
            top: style.leadingPadding(for: columnDirection, width: width),
            leading: style.leadingPadding(for: rowDirection, width: width),
            bottom: style.trailingPadding(for: columnDirection, width: width),
            trailing: style.trailingPadding(for: rowDirection, width: width))

        return (leading + trailing, top + bottom)
    }

    // YGNodeWithMeasureFuncSetMeasuredDimensions
    @inline(__always)
    func measureLayout(width: Double, height: Double, widthMode: MeasureMode, heightMode: MeasureMode,
        parentWidth: Double, parentHeight: Double) {
        assert(hasMeasureMethod, "Expected node to have custom measure function")

        let width = widthMode.isUndefined ? Double.nan : width
        let height = heightMode.isUndefined ? Double.nan : height

        // paddingAndBorderAxisRow
        let innerSizeRow = style.totalInnerSize(for: .row, width: width)
        // paddingAndBorderAxisColumn
        let innerSizeColumn = style.totalInnerSize(for: .column, width: width)

        // We want to make sure we don't call measure with negative size
        let innerWidth = width.isNaN ? width : max(0.0, width - innerSizeRow)
        let innerHeight = height.isNaN ? height : max(0.0, height - innerSizeColumn)

        if widthMode.isExactly && heightMode.isExactly {
            // Don't bother sizing the text if both dimensions are already defined.
            box.measuredWidth = style.bound(axis: .row, value: width, axisSize: parentWidth,
                width: parentWidth)
            box.measuredHeight = style.bound(axis: .column, value: height, axisSize: parentHeight,
                width: parentWidth)
        } else {
            // Measure the text under the current constraints.
            let size = measure(width: innerWidth, widthMode: widthMode, height: innerHeight, heightMode: heightMode)
            let _width = !widthMode.isExactly ? (size.width + innerSizeRow) : width
            let _height = !heightMode.isExactly ? (size.height + innerSizeColumn) : height
            box.measuredWidth = style.bound(axis: .row, value: _width, axisSize: parentWidth, width: parentWidth)
            box.measuredHeight = style.bound(axis: .column, value: _height, axisSize: parentHeight, width: parentWidth)
        }
    }

    // YGNodeEmptyContainerSetMeasuredDimensions
    @inline(__always)
    func emptyLayout(width: Double, height: Double, widthMode: MeasureMode, heightMode: MeasureMode,
        parentWidth: Double, parentHeight: Double) {
        // paddingAndBorderAxisRow
        let innerRow = style.totalInnerSize(for: .row, width: parentWidth)
        // paddingAndBorderAxisColumn
        let innerColumn = style.totalInnerSize(for: .column, width: parentWidth)
        // marginAxisRow
        let outerRow = style.totalOuterSize(for: .row, width: parentWidth)
        // marginAxisColumn
        let outerColumn = style.totalOuterSize(for: .column, width: parentWidth)
        let _width: Double = (!widthMode.isExactly) ? innerRow : (width - outerRow)
        box.measuredWidth = style.bound(axis: .row, value: _width, axisSize: parentWidth, width: parentWidth)
        let _height: Double = (!heightMode.isExactly) ? innerColumn : (height - outerColumn)
        box.measuredHeight = style.bound(axis: .column, value: _height, axisSize: parentHeight, width: parentWidth)
    }

    // YGNodeFixedSizeSetMeasuredDimensions
    func fixedLayout(width: Double, height: Double, widthMode: MeasureMode, heightMode: MeasureMode,
        parentWidth: Double, parentHeight: Double) -> Bool {
        guard (!width.isNaN && widthMode.isAtMost && width <= 0.0) ||
                  (!height.isNaN && heightMode.isAtMost && height <= 0.0) ||
                  (widthMode.isExactly && heightMode.isExactly) else {
            return false
        }
        let width: Double = (width.isNaN || (widthMode.isAtMost && width < 0.0)) ? 0.0 : width
        box.measuredWidth = style.bound(axis: .row, value: width, axisSize: parentWidth, width: parentHeight)
        let height: Double = (height.isNaN || (heightMode.isAtMost && height < 0.0)) ? 0.0 : height
        box.measuredHeight = style.bound(axis: .column, value: height, axisSize: parentHeight, width: parentWidth)
        return true
    }

    // YGNodelayoutImpl
    @inline(__always)
    func flexLayout(width: Double, height: Double, direction: Direction, widthMode: MeasureMode,
        heightMode: MeasureMode, parentWidth: Double, parentHeight: Double, layout performLayout: Bool) {
        // At this point we know we're going to perform work. Ensure that each child has a mutable copy.
        copyChildrenIfNeeded()
        // Reset layout flags, as they could have changed.
        box.hasOverflow = false
        var algorithm = FlexAlgorithm(for: self, ownerDirection: direction,
            availableWidth: width, availableHeight: height,
            widthMeasureMode: widthMode, heightMeasureMode: heightMode,
            ownerWidth: parentWidth, ownerHeight: parentHeight, performLayout: performLayout)
        algorithm.steps()
    }

    // YGNodeAbsoluteLayoutChild
    func absoluteLayout(child: FlexLayout, width: Double, widthMode: MeasureMode, height: Double,
        direction: Direction) {
        let mainAxis = style.flexDirection.resolve(by: direction)
        let crossAxis = mainAxis.cross(by: direction)
        let isMainAxisRow = mainAxis.isRow
        var childWidth = Double.nan
        var childHeight = Double.nan
        var childWidthMeasureMode = MeasureMode.undefined
        var childHeightMeasureMode = MeasureMode.undefined
        let marginRow: Double = child.style.totalOuterSize(for: .row, width: width)
        let marginColumn: Double = child.style.totalOuterSize(for: .column, width: width)
        if child.isDimensionDefined(for: .row, size: width) {
            childWidth = child.resolvedWidth.resolve(by: width) + marginRow
        } else {
            // If the child doesn't have a specified width, compute the width based
            // on the left/right offsets if they're defined.
            if child.style.isLeadingPositionDefined(for: .row) && child.style.isTrailingPositionDefined(for: .row) {
                childWidth = box.measuredWidth - style.totalBorder(for: .row) -
                    child.style.leadingPosition(for: .row, size: width) -
                    child.style.trailingPosition(for: .row, size: width)
                childWidth = child.style.bound(axis: .row, value: childWidth, axisSize: width, width: width)
            }
        }
        if child.isDimensionDefined(for: .column, size: height) {
            childHeight = child.resolvedHeight.resolve(by: height) + marginColumn
        } else {
            // If the child doesn't have a specified height, compute the height
            // based on the top/bottom offsets if they're defined.
            if child.style.isLeadingPositionDefined(for: .column) &&
                child.style.isTrailingPositionDefined(for: .column) {
                childHeight = box.measuredHeight - style.totalBorder(for: .column) -
                    child.style.leadingPosition(for: .column, size: height) -
                    child.style.trailingPosition(for: .column, size: height)
                childHeight = child.style.bound(axis: .column, value: childHeight, axisSize: height, width: width)
            }
        }
        // true  ^ true  = false
        // true  ^ false = true
        // false ^ true  = true
        // false ^ false = false
        // Exactly one dimension needs to be defined for us to be able to do aspect ratio
        // calculation. One dimension being the anchor and the other being flexible.
        if childWidth.isNaN != childHeight.isNaN {
            if !child.style.aspectRatio.isNaN {
                if childWidth.isNaN {
                    childWidth = marginRow + (childHeight - marginColumn) * child.style.aspectRatio
                } else if childHeight.isNaN {
                    childHeight = marginColumn + (childWidth - marginRow) / child.style.aspectRatio
                }
            }
        }
        // If we're still missing one or the other dimension, measure the content.
        if childWidth.isNaN || childHeight.isNaN {
            childWidthMeasureMode = childWidth.isNaN ? .undefined : .exactly
            childHeightMeasureMode = childHeight.isNaN ? .undefined : .exactly
            // If the size of the parent is defined then try to constrain the absolute child to that size
            // as well. This allows text within the absolute child to wrap to the size of its parent.
            // This is the same behavior as many browsers implement.
            if !isMainAxisRow && childWidth.isNaN && widthMode != MeasureMode.undefined &&
                   !width.isNaN && width > 0 {
                childWidth = width
                childWidthMeasureMode = .atMost
            }
            _ = child.layoutInternal(width: childWidth, height: childHeight,
                widthMode: childWidthMeasureMode, heightMode: childHeightMeasureMode,
                parentWidth: childWidth, parentHeight: childHeight, direction: direction,
                layout: false, reason: .absMeasureChild)
            childWidth = child.box.measuredWidth + child.style.totalOuterSize(for: .row, width: width)
            childHeight = child.box.measuredHeight + child.style.totalOuterSize(for: .column, width: width)
        }
        _ = child.layoutInternal(width: childWidth, height: childHeight,
            widthMode: .exactly, heightMode: .exactly, parentWidth: childWidth,
            parentHeight: childHeight, direction: direction, layout: true, reason: .absLayout)
        if child.style.isTrailingPositionDefined(for: mainAxis) &&
            !child.style.isLeadingPositionDefined(for: mainAxis) {
            let size: Double = box.measuredDimension(for: mainAxis) -
                child.box.measuredDimension(for: mainAxis) - style.trailingBorder(for: mainAxis) -
                child.style.trailingMargin(for: mainAxis, width: width) -
                child.style.trailingPosition(for: mainAxis, size: (isMainAxisRow ? width : height))
            child.box.position.setLeading(direction: mainAxis, size: size)
        } else if !child.style.isLeadingPositionDefined(for: mainAxis) &&
            style.justifyContent == JustifyContent.center {
            let size: Double = (box.measuredDimension(for: mainAxis) - child.box.measuredDimension(for: mainAxis)) / 2
            child.box.position.setLeading(direction: mainAxis, size: size)
        } else if !child.style.isTrailingPositionDefined(for: crossAxis) &&
            style.justifyContent == JustifyContent.end {
            let size = box.measuredDimension(for: mainAxis) - child.box.measuredDimension(for: mainAxis)
            child.box.position.setLeading(direction: mainAxis, size: size)
        }
        if child.style.isTrailingPositionDefined(for: crossAxis) &&
            !child.style.isLeadingPositionDefined(for: crossAxis) {
            let size: Double = box.measuredDimension(for: crossAxis) -
                child.box.measuredDimension(for: crossAxis) - style.trailingBorder(for: crossAxis) -
                child.style.trailingMargin(for: crossAxis, width: width) -
                child.style.trailingPosition(for: crossAxis, size: (isMainAxisRow ? height : width))
            child.box.position.setLeading(direction: crossAxis, size: size)
        } else if !child.style.isLeadingPositionDefined(for: crossAxis) &&
            computedAlignItem(child: child) == AlignItems.center {
            let size: Double = (box.measuredDimension(for: crossAxis) - child.box.measuredDimension(for: crossAxis)) / 2
            child.box.position.setLeading(direction: crossAxis, size: size)
        } else if !child.style.isTrailingPositionDefined(for: crossAxis) &&
            ((computedAlignItem(child: child) == AlignItems.end) != (style.flexWrap == FlexWrap.wrapReverse)) {
            let size = box.measuredDimension(for: crossAxis) - child.box.measuredDimension(for: crossAxis)
            child.box.position.setLeading(direction: crossAxis, size: size)
        }
    }
}
