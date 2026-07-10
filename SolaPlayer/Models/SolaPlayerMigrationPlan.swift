import SwiftData

enum SolaPlayerMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SolaPlayerSchemaV1.self, SolaPlayerSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [
            .lightweight(
                fromVersion: SolaPlayerSchemaV1.self,
                toVersion: SolaPlayerSchemaV2.self
            ),
        ]
    }
}
