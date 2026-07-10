import SwiftUI

enum AppTypography {
    static let playerTimeCode = AppFontToken(size: 76, weight: .ultraLight, relativeTo: .largeTitle, tracking: -1)
    static let totalDuration = AppFontToken(size: 15, weight: .light, relativeTo: .body)
    static let playerTitle = AppFontToken(size: 19, weight: .medium, relativeTo: .title3)
    static let secondary = AppFontToken(size: 13, weight: .regular, relativeTo: .subheadline)
    static let metadata = AppFontToken(size: 11, weight: .regular, relativeTo: .caption)
    static let pill = AppFontToken(size: 12, weight: .semibold, relativeTo: .caption)
    static let flag = AppFontToken(size: 10, weight: .semibold, relativeTo: .caption2)
    static let libraryTitle = AppFontToken(size: 34, weight: .thin, relativeTo: .largeTitle)
}
