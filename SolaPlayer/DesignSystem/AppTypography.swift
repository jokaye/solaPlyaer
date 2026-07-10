import SwiftUI

enum AppTypography {
    static let libraryTitle = Font.system(.largeTitle, design: .default, weight: .thin)
    static let trackTitle = Font.headline
    static let secondary = Font.subheadline
    static let metadata = Font.footnote

    // Consumers must use @ScaledMetric(relativeTo: .largeTitle) with this design value.
    static let timeCodeSize: CGFloat = 76
}
