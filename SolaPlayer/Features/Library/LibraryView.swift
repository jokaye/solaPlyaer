import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @Bindable var store: LibraryStore

    @State private var isShowingImporter = false
    @State private var isCreatingGroup = false
    @State private var isManagingGroups = false
    @State private var groupPickerRequest: GroupPickerRequest?
    @State private var itemToRename: AudioItem?
    @State private var itemToDelete: AudioItem?
    @State private var isShowingDeleteConfirmation = false
    @State private var presentedError: PresentedError?
    @State private var selectedItemIDs: Set<UUID> = []

    var body: some View {
        List(selection: $selectedItemIDs) {
            if store.isImporting {
                ProgressView("正在导入音频…")
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            Section {
                LibraryHeaderView(itemCount: store.items.count, groupCount: store.groups.count)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 2, trailing: 0))
                    .listRowSeparator(.hidden)

                GroupChipsView(
                    store: store,
                    onCreateGroup: showCreateGroup,
                    onManageGroups: showManageGroups,
                    onError: present
                )
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                .listRowSeparator(.hidden)
            }

            Section(store.scopeName) {
                if store.scope == .master {
                    ImportCardView(action: showImporter)
                }

                if store.visibleItems.isEmpty, store.scope != .master {
                    ContentUnavailableView(
                        "分组还没有音频",
                        systemImage: "music.note.list",
                        description: Text("从默认列表选择音频并加入这个分组。")
                    )
                } else {
                    ForEach(store.visibleItems) { item in
                        TrackRowView(
                            item: item,
                            membershipCount: store.membershipCount(for: item),
                            canRemoveFromCurrentGroup: store.scope != .master,
                            onChooseGroups: { showGroupPicker(for: item) },
                            onRemoveFromCurrentGroup: { removeFromCurrentGroup(item) },
                            onRename: { showRename(for: item) },
                            onDelete: { confirmDelete(item) }
                        )
                        .tag(item.id)
                    }
                    .onMove(perform: moveItems)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if store.visibleItems.isEmpty == false {
                    EditButton()
                }

                Button("导入音频", systemImage: "plus", action: showImporter)
                    .disabled(store.isImporting)

                Menu("更多", systemImage: "ellipsis.circle") {
                    Button("管理分组", systemImage: "rectangle.3.group", action: showManageGroups)
                        .disabled(store.groups.isEmpty)
                    NavigationLink("关于与诊断", systemImage: "info.circle", value: RootRoute.about)
                }
            }

            if selectedItemIDs.isEmpty == false {
                ToolbarItemGroup(placement: .bottomBar) {
                    Text("已选择 \(selectedItemIDs.count) 项")
                    Spacer()
                    Button("加入分组…", systemImage: "folder.badge.plus", action: showBulkGroupPicker)
                }
            }
        }
        .fileImporter(
            isPresented: $isShowingImporter,
            allowedContentTypes: [.audio, .folder],
            allowsMultipleSelection: true,
            onCompletion: handleImportResult
        )
        .onOpenURL(perform: importOpenedURL)
        .sheet(isPresented: $isCreatingGroup) {
            NameEditorSheet(title: "新建分组", initialName: "") { name in
                try store.createGroup(name: name)
            }
        }
        .sheet(isPresented: $isManagingGroups) {
            ManageGroupsSheet(store: store)
        }
        .sheet(item: $groupPickerRequest) { request in
            GroupPickerSheet(store: store, items: request.items)
        }
        .sheet(item: $itemToRename) { item in
            NameEditorSheet(title: "重命名音频", initialName: item.title) { title in
                try store.renameItem(item, to: title)
            }
        }
        .confirmationDialog(
            "确定删除这段音频？",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("彻底删除", role: .destructive, action: deleteConfirmedItem)
            Button("取消", role: .cancel, action: cancelItemDeletion)
        } message: {
            Text("音频会从默认列表和所有分组中移除，此操作不可撤销。")
        }
        .alert(item: $presentedError) { error in
            Alert(title: Text("操作失败"), message: Text(error.message))
        }
        .onChange(of: store.scope) { _, _ in
            selectedItemIDs.removeAll()
        }
        .overlay(alignment: .bottom) {
            if let removal = store.pendingRemoval {
                UndoSnackbar(removal: removal, undo: undoRemoval)
                    .padding(AppSpacing.controls)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .task(id: store.pendingRemoval?.id) {
            await dismissRemovalAfterDelay(store.pendingRemoval)
        }
        .task {
            await purgePendingFileDeletions()
        }
    }

    private func showImporter() {
        guard store.isImporting == false else {
            return
        }
        isShowingImporter = true
    }

    private func showCreateGroup() {
        isCreatingGroup = true
    }

    private func showManageGroups() {
        isManagingGroups = true
    }

    private func showGroupPicker(for item: AudioItem) {
        groupPickerRequest = GroupPickerRequest(items: [item])
    }

    private func showBulkGroupPicker() {
        let selectedItems = store.items.filter { selectedItemIDs.contains($0.id) }
        guard selectedItems.isEmpty == false else {
            return
        }
        groupPickerRequest = GroupPickerRequest(items: selectedItems)
        selectedItemIDs.removeAll()
    }

    private func showRename(for item: AudioItem) {
        itemToRename = item
    }

    private func confirmDelete(_ item: AudioItem) {
        itemToDelete = item
        isShowingDeleteConfirmation = true
    }

    private func handleImportResult(_ result: Result<[URL], Error>) {
        Task {
            do {
                try await store.importFiles(result.get())
            } catch {
                present(error)
            }
        }
    }

    private func importOpenedURL(_ url: URL) {
        Task {
            do {
                try await store.importFiles([url])
            } catch {
                present(error)
            }
        }
    }

    private func moveItems(fromOffsets: IndexSet, toOffset: Int) {
        do {
            try store.reorderItems(fromOffsets: fromOffsets, toOffset: toOffset)
        } catch {
            present(error)
        }
    }

    private func removeFromCurrentGroup(_ item: AudioItem) {
        guard case let .group(groupID) = store.scope,
              let group = store.groups.first(where: { $0.id == groupID }) else {
            present(LibraryStoreError.groupNotFound)
            return
        }

        do {
            withAnimation {
                try store.remove(item, from: group)
            }
        } catch {
            present(error)
        }
    }

    private func undoRemoval() {
        do {
            withAnimation {
                try store.undoPendingRemoval()
            }
        } catch {
            present(error)
        }
    }

    private func deleteConfirmedItem() {
        guard let item = itemToDelete else {
            return
        }
        itemToDelete = nil
        isShowingDeleteConfirmation = false

        Task {
            do {
                try await store.deleteItem(item)
            } catch {
                present(error)
            }
        }
    }

    private func cancelItemDeletion() {
        itemToDelete = nil
        isShowingDeleteConfirmation = false
    }

    private func present(_ error: Error) {
        presentedError = PresentedError(error)
    }

    private func dismissRemovalAfterDelay(_ removal: MembershipRemoval?) async {
        guard let removal else {
            return
        }
        try? await Task.sleep(for: .seconds(3))
        guard Task.isCancelled == false else {
            return
        }
        withAnimation {
            store.dismissPendingRemoval(id: removal.id)
        }
    }

    private func purgePendingFileDeletions() async {
        do {
            try await store.purgePendingFileDeletions()
        } catch {
            present(error)
        }
    }
}
