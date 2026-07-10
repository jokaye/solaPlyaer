import SwiftUI

struct ManageGroupsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: LibraryStore
    @State private var presentedError: PresentedError?

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
            .alert(item: $presentedError) { error in
                Alert(title: Text("无法调整顺序"), message: Text(error.message))
            }
        }
    }

    private func moveGroups(fromOffsets: IndexSet, toOffset: Int) {
        do {
            try store.reorderGroups(fromOffsets: fromOffsets, toOffset: toOffset)
        } catch {
            presentedError = PresentedError(error)
        }
    }
}
