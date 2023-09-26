struct LayoutData {
    var layouts: Int = 0
    var measures: Int = 0
    var maxMeasureCache: Int = 0
    var cachedLayouts: Int = 0
    var cachedMeasures: Int = 0
    var measureCallbacks: Int = 0
    var measureCallbackReasonsCount: [Int] = []
}
