import Foundation

enum PlaybackScope: Hashable, Identifiable, Sendable {
    case master
    case group(UUID)

    var id: String {
        switch self {
        case .master:
            "master"
        case let .group(id):
            "group-\(id.uuidString)"
        }
    }
}
