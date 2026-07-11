#if DEBUG
import Foundation
import SwiftData

@MainActor
enum DesignPreviewSeeder {
    static func seed(modelContext: ModelContext) throws {
        let definitions: [(String, TimeInterval, AppPalette)] = [
            ("城市清晨 · 环境采集", 228, .lake),
            ("产品复盘会 · 片段", 2_530, .aqua),
            ("深夜灵感 · 旋律哼唱", 72, .mint),
            ("雨落屋檐", 485, .ocean),
            ("副歌 Demo v3", 140, .azure),
            ("用户访谈 · 张女士", 1_664, .clearSky),
            ("地铁人声底噪", 333, .lake),
        ]

        let items = definitions.enumerated().map { index, definition in
            AudioItem(
                title: definition.0,
                bookmark: Data(),
                localCopyURL: URL(fileURLWithPath: "/tmp/sola-design-\(index).m4a"),
                duration: definition.1,
                masterOrder: index,
                paletteKey: definition.2.rawValue
            )
        }
        items.forEach { modelContext.insert($0) }

        let interview = AudioGroup(name: "采访", colorKey: AppPalette.aqua.rawValue, chipOrder: 0)
        let ideas = AudioGroup(name: "灵感速记", colorKey: AppPalette.azure.rawValue, chipOrder: 1)
        let ambience = AudioGroup(name: "环境声", colorKey: AppPalette.mint.rawValue, chipOrder: 2)
        [interview, ideas, ambience].forEach { modelContext.insert($0) }

        let memberships = [
            Membership(group: interview, item: items[5], orderInGroup: 0),
            Membership(group: interview, item: items[1], orderInGroup: 1),
            Membership(group: ideas, item: items[2], orderInGroup: 0),
            Membership(group: ideas, item: items[4], orderInGroup: 1),
            Membership(group: ambience, item: items[0], orderInGroup: 0),
            Membership(group: ambience, item: items[3], orderInGroup: 1),
            Membership(group: ambience, item: items[6], orderInGroup: 2),
        ]
        memberships.forEach { modelContext.insert($0) }

        [31.0, 95.0, 164.0].enumerated().forEach { index, time in
            modelContext.insert(
                Marker(ownerID: items[0].id, time: time, title: "标记 \(index + 1)")
            )
        }
        try modelContext.save()
    }
}
#endif
