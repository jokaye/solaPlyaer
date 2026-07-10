import SwiftData

enum AppModelContainer {
    @MainActor
    static func make(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(versionedSchema: SolaPlayerSchemaV1.self)
        let configuration = ModelConfiguration(
            "SolaPlayer",
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none
        )

        return try ModelContainer(
            for: schema,
            migrationPlan: SolaPlayerMigrationPlan.self,
            configurations: configuration
        )
    }
}
