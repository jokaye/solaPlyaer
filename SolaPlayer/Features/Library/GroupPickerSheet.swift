import SwiftUI

struct GroupPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: LibraryStore

    let items: [AudioItem]

    @State private var isCreatingGroup = false
    @State private var presentedError: PresentedError?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(sheetDescription)
                        .font(.subheadline)
                        .foregroundStyle(AppColor.secondaryInk)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                if store.groups.isEmpty {
                    ContentUnavailableView(
                        "还没有分组",
                        systemImage: "folder.badge.plus",
                        description: Text("先创建一个分组，再把音频加入其中。")
                    )
                } else {
                    ForEach(store.groups) { group in
                        Button {
                            toggle(group)
                        } label: {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(groupPalette(for: group).colors.top)
                                    .frame(width: 10, height: 10)
                                    .accessibilityHidden(true)

                                Text(group.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if allItemsAreMembers(of: group) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(AppColor.ink)
                                        .accessibilityHidden(true)
                                } else if anyItemIsMember(of: group) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.secondary)
                                        .accessibilityHidden(true)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(.tertiary)
                                        .accessibilityHidden(true)
                                }
                            }
                        }
                        .accessibilityValue(accessibilityValue(for: group))
                        .frame(minHeight: 48)
                    }
                }

                Button("新建分组", systemImage: "plus", action: showCreateGroup)
                    .foregroundStyle(AppPalette.lake.colors.top)
                    .bold()
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(
                LinearGradient(
                    colors: [AppPalette.clearSky.colors.bottom.opacity(0.45), Color(uiColor: .systemBackground)],
                    startPoint: .top,
                    endPoint: .center
                )
            )
            .navigationTitle("加入分组")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成", action: dismiss.callAsFunction)
                }
            }
            .sheet(isPresented: $isCreatingGroup) {
                NameEditorSheet(title: "新建分组", initialName: "") { name in
                    _ = try store.createGroup(name: name, adding: items)
                }
            }
            .alert(item: $presentedError) { error in
                Alert(title: Text("操作失败"), message: Text(error.message))
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func showCreateGroup() {
        isCreatingGroup = true
    }

    private var sheetDescription: String {
        if items.count == 1, let item = items.first {
            return "选择要把“\(item.title)”加入的分组，不影响默认列表。"
        }
        return "为已选择的 \(items.count) 段音频勾选分组，不影响默认列表。"
    }

    private func groupPalette(for group: AudioGroup) -> AppPalette {
        group.colorKey.flatMap(AppPalette.init(rawValue:)) ?? .lake
    }

    private func toggle(_ group: AudioGroup) {
        do {
            if allItemsAreMembers(of: group) {
                try store.remove(items, from: group)
            } else {
                try store.add(items, to: [group])
            }
        } catch {
            presentedError = PresentedError(error)
        }
    }

    private func allItemsAreMembers(of group: AudioGroup) -> Bool {
        items.isEmpty == false && items.allSatisfy { store.isMember($0, of: group) }
    }

    private func anyItemIsMember(of group: AudioGroup) -> Bool {
        items.contains { store.isMember($0, of: group) }
    }

    private func accessibilityValue(for group: AudioGroup) -> String {
        if allItemsAreMembers(of: group) {
            return "全部已加入"
        }
        if anyItemIsMember(of: group) {
            return "部分已加入"
        }
        return "未加入"
    }
}
