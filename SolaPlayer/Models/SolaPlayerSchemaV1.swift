import SwiftData

enum SolaPlayerSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [AudioItem.self, AudioGroup.self, Membership.self, Marker.self]
    }
}
