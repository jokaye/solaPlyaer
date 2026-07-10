import Foundation

enum RootRoute: Hashable {
    case about
    case settings
    case player(scope: PlaybackScope, itemID: UUID)
}
