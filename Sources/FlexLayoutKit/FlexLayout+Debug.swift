extension FlexBox {
    var rect: Rect {
        Rect(x: left, y: top, width: width, height: height)
    }
}

extension FlexLayout {
    public func debugPrint(file: StaticString = #fileID, function: StaticString = #function) {
        print(file, function)
        debugPrint(intent: "")
    }

    private func debugPrint(intent: String) {
        print(intent, box.rect, separator: "")
        let intent = intent + "    " // 4 spaces
        for child in children {
            child.debugPrint(intent: intent)
        }
    }
}
