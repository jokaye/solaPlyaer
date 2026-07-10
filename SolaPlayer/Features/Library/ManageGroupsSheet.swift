import SwiftUI

struct ManageGroupsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: LibraryStore
    let onError: (Error) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.groups) { group in
                    Label(group.name, systemImage: "line.3.horizontal")
                }
                .onMove(perform: moveGroups)
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("调整分组顺序")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成", action: dismiss.callAsFunction)
                }
            }
        }
    }

    private func moveGroups(fromOffsets: IndexSet, toOffset: Int) {
        do {
            try store.reorderGroups(fromOffsets: fromOffsets, toOffset: toOffset)
        } catch {
            onError(error)
        }
    }
}
