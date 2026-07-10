import SwiftUI

enum AppHaptic {
    static let selection = SensoryFeedback.selection
    static let boundary = SensoryFeedback.impact(weight: .light)
    static let marker = SensoryFeedback.impact(weight: .medium)
}
