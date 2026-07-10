import SwiftData

enum SolaPlayerSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [AudioItem.self, AudioGroup.self, Membership.self, Marker.self]
    }
}
