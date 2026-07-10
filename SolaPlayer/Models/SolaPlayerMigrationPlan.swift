import SwiftData

enum SolaPlayerMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SolaPlayerSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
