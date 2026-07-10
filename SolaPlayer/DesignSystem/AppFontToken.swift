import SwiftUI

struct AppFontToken {
    let size: CGFloat
    let weight: Font.Weight
    let relativeTo: Font.TextStyle
    let tracking: CGFloat

    init(size: CGFloat, weight: Font.Weight, relativeTo: Font.TextStyle, tracking: CGFloat = 0) {
        self.size = size
        self.weight = weight
        self.relativeTo = relativeTo
        self.tracking = tracking
    }
}
