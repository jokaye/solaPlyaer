import SwiftUI

struct GroupChipsView: View {
    @Bindable var store: LibraryStore
    let onCreateGroup: () -> Void
    let onManageGroups: () -> Void
    let onError: (Error) -> Void

    @State private var groupToRename: AudioGroup?
    @State private var groupToDelete: AudioGroup?
    @State private var isShowingDeleteConfirmation = false

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: AppSpacing.small) {
                ScopeChipButton(
                    title: "默认列表",
                    isSelected: store.scope == .master,
                    accentColor: nil,
                    action: selectMaster
                )

                ForEach(store.groups) { group in
                    ScopeChipButton(
                        title: group.name,
                        isSelected: store.scope == .group(group.id),
                        accentColor: group.colorKey
                            .flatMap(AppPalette.init(rawValue:))?
                            .colors.top,
                        action: { select(.group(group.id)) }
                    )
                        .contextMenu {
                            Button("重命名", systemImage: "pencil") {
                                groupToRename = group
                            }

                            Menu("颜色", systemImage: "paintpalette") {
                                ForEach(AppPalette.allCases) { palette in
                                    Button(palette.label) {
                                        setColor(palette, for: group)
                                    }
                                }
                            }

                            Button("删除分组", systemImage: "trash", role: .destructive) {
                                groupToDelete = group
                                isShowingDeleteConfirmation = true
                            }
                        }
                }

                Button("新建分组", systemImage: "plus", action: onCreateGroup)
                    .buttonStyle(.bordered)

                if store.groups.isEmpty == false {
                    Button("调整分组顺序", systemImage: "arrow.up.arrow.down", action: onManageGroups)
                        .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal, AppSpacing.content)
        }
        .scrollIndicators(.hidden)
        .sheet(item: $groupToRename) { group in
            NameEditorSheet(title: "重命名分组", initialName: group.name) { name in
                try store.renameGroup(group, to: name)
            }
        }
        .confirmationDialog(
            "删除分组“\(groupToDelete?.name ?? "")”？",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("删除分组", role: .destructive, action: deleteGroup)
            Button("取消", role: .cancel, action: cancelGroupDeletion)
        } message: {
            Text("组内音频仍会保留在默认列表。")
        }
    }

    private func selectMaster() {
        select(.master)
    }

    private func select(_ scope: PlaybackScope) {
        do {
            try store.setScope(scope)
        } catch {
            onError(error)
        }
    }

    private func setColor(_ palette: AppPalette, for group: AudioGroup) {
        do {
            try store.setColor(palette.rawValue, for: group)
        } catch {
            onError(error)
        }
    }

    private func deleteGroup() {
        guard let group = groupToDelete else {
            return
        }
        defer {
            groupToDelete = nil
            isShowingDeleteConfirmation = false
        }

        do {
            try store.deleteGroup(group)
        } catch {
            onError(error)
        }
    }

    private func cancelGroupDeletion() {
        groupToDelete = nil
        isShowingDeleteConfirmation = false
    }
}
