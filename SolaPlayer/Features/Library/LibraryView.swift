import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @Bindable var store: LibraryStore
    @Bindable var playerStore: PlayerStore
    let onPlay: (AudioItem, PlaybackScope) -> Void
    let onResumePlayer: () -> Void

    @State private var isShowingImporter = false
    @State private var isShowingLinkImporter = false
    @State private var isCreatingGroup = false
    @State private var isManagingGroups = false
    @State private var groupPickerRequest: GroupPickerRequest?
    @State private var itemToRename: AudioItem?
    @State private var itemToDelete: AudioItem?
    @State private var isShowingDeleteConfirmation = false
    @State private var presentedError: PresentedError?
    @State private var selectedItemIDs: Set<UUID> = []
    @State private var editMode: EditMode = .inactive

    private func setPalette(_ palette: AppPalette?, for item: AudioItem) {
        do {
            try store.setPalette(palette, for: item)
        } catch {
            present(error)
        }
    }

    private func importLink(_ url: URL) async throws {
        try await store.importFiles([url])
    }

    private func showLinkImporter() {
        isShowingLinkImporter = true
    }

    private var libraryList: some View {
        List(selection: $selectedItemIDs) {
            if store.isImporting {
                ProgressView("正在导入音频…")
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            Section {
                LibraryHeaderView(
                    itemCount: store.items.count,
                    groupCount: store.groups.count,
                    isImporting: store.isImporting,
                    onImport: showImporter,
                    onLinkImport: showLinkImporter,
                    onManageGroups: showManageGroups
                )
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 2, trailing: 0))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                GroupChipsView(
                    store: store,
                    onCreateGroup: showCreateGroup,
                    onManageGroups: showManageGroups,
                    onError: present
                )
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }

            Section {
                if store.scope == .master {
                    ImportCardView(isEmpty: store.items.isEmpty, action: showImporter)
                        .listRowInsets(
                            EdgeInsets(
                                top: 0,
                                leading: AppSpacing.controls,
                                bottom: AppSpacing.standard,
                                trailing: AppSpacing.controls
                            )
                        )
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
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
                            isCurrent: playerStore.currentItem?.id == item.id,
                            canRemoveFromCurrentGroup: store.scope != .master,
                            selectedPalette: item.paletteKey.flatMap(AppPalette.init(rawValue:)),
                            onPlay: { onPlay(item, store.scope) },
                            onChooseGroups: { showGroupPicker(for: item) },
                            onSetPalette: { setPalette($0, for: item) },
                            onRemoveFromCurrentGroup: { removeFromCurrentGroup(item) },
                            onRename: { showRename(for: item) },
                            onDelete: { confirmDelete(item) }
                        )
                        .tag(item.id)
                        .listRowInsets(
                            EdgeInsets(
                                top: 3,
                                leading: AppSpacing.controls,
                                bottom: 3,
                                trailing: AppSpacing.controls
                            )
                        )
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    .onMove(perform: moveItems)
                }
            } header: {
                HStack {
                    Text(scopeSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    if store.visibleItems.isEmpty == false, editMode.isEditing == false {
                        Button(action: playCurrentScope) {
                            Label("播放本列表", systemImage: "play.fill")
                                .labelStyle(.titleAndIcon)
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppPalette.lake.colors.top)
                    }

                    if store.visibleItems.isEmpty == false {
                        Button(editMode.isEditing ? "完成" : "编辑", action: toggleEditMode)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppPalette.lake.colors.top)
                    }
                }
                .textCase(nil)
                .padding(.horizontal, 4)
            }
        }
        .listStyle(.plain)
        .listSectionSpacing(12)
        .scrollContentBackground(.hidden)
        .background(LibraryBackground())
        .navigationTitle("")
        .toolbar(.hidden, for: .navigationBar)
        .toolbar {
            if selectedItemIDs.isEmpty == false {
                ToolbarItemGroup(placement: .bottomBar) {
                    Text("已选择 \(selectedItemIDs.count) 项")
                    Spacer()
                    Button("加入分组…", systemImage: "folder.badge.plus", action: showBulkGroupPicker)
                }
            }
        }
        .environment(\.editMode, $editMode)
    }

    private var scopeSummary: String {
        let base = "\(store.visibleItems.count) 段音频"
        if store.scope == .master {
            if editMode.isEditing {
                return "\(base) · 自定义顺序"
            }
            return base
        }
        return "\(base) · 组内自定义顺序"
    }

    private var librarySheets: some View {
        libraryList
        .fileImporter(
            isPresented: $isShowingImporter,
            allowedContentTypes: [.audio, .folder],
            allowsMultipleSelection: true,
            onCompletion: handleImportResult
        )
        .sheet(isPresented: $isShowingLinkImporter) {
            LinkImportSheet(onImport: importLink)
        }
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
    }

    var body: some View {
        librarySheets
        .onChange(of: store.scope) { _, _ in
            selectedItemIDs.removeAll()
            editMode = .inactive
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: AppSpacing.small) {
                if let removal = store.pendingRemoval {
                    UndoSnackbar(removal: removal, undo: undoRemoval)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if let currentItem = playerStore.currentItem {
                    NowPlayingBar(
                        item: currentItem,
                        sourceName: playerStore.sourceName,
                        isPlaying: playerStore.isPlaying,
                        onOpen: onResumePlayer,
                        onTogglePlayback: toggleMiniPlayer
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, AppSpacing.standard)
        }
        .task(id: store.pendingRemoval?.id) {
            await dismissRemovalAfterDelay(store.pendingRemoval)
        }
        .task {
            configureDesignPreviewIfNeeded()
            await reconcilePendingFileDeletions()
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
            _ = try withAnimation {
                try store.remove(item, from: group)
            }
        } catch {
            present(error)
        }
    }

    private func undoRemoval() {
        do {
            _ = try withAnimation {
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

    private func toggleMiniPlayer() {
        do {
            try playerStore.togglePlayback()
        } catch {
            present(error)
        }
    }

    private func toggleEditMode() {
        withAnimation(.easeInOut(duration: 0.22)) {
            if editMode.isEditing {
                editMode = .inactive
            } else {
                selectedItemIDs.removeAll()
                editMode = .active
            }
        }
    }

    private func playCurrentScope() {
        guard let first = store.visibleItems.first else {
            return
        }
        onPlay(first, store.scope)
    }

    private func configureDesignPreviewIfNeeded() {
        #if DEBUG
        switch ProcessInfo.processInfo.environment["SOLA_DESIGN_PREVIEW"] {
        case "group-edit":
            guard let group = store.groups.first(where: { $0.name == "灵感速记" }) else {
                return
            }
            try? store.setScope(.group(group.id))
            editMode = .active
        case "group-sheet":
            guard let item = store.items.first else {
                return
            }
            groupPickerRequest = GroupPickerRequest(items: [item])
        default:
            break
        }
        #endif
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

    private func reconcilePendingFileDeletions() async {
        do {
            try await store.reconcilePendingFileDeletions()
        } catch {
            present(error)
        }
    }
}
