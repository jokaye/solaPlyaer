import SwiftUI

struct MarkerListView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: MarkerStore

    let onSeek: (TimeInterval) -> Void

    @State private var markerToEdit: Marker?
    @State private var presentedError: PresentedError?

    var body: some View {
        NavigationStack {
            List {
                if store.markers.isEmpty {
                    ContentUnavailableView(
                        "还没有标记",
                        systemImage: "bookmark",
                        description: Text("返回播放页，在需要的位置点击“标记此刻”。")
                    )
                } else {
                    ForEach(store.markers) { marker in
                        Button(action: { jump(to: marker) }) {
                            MarkerRowView(marker: marker)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .contextMenu {
                            Button("编辑", systemImage: "pencil") {
                                markerToEdit = marker
                            }
                            Button("删除", systemImage: "trash", role: .destructive) {
                                delete(marker)
                            }
                        }
                        .swipeActions(allowsFullSwipe: false) {
                            Button("删除", systemImage: "trash", role: .destructive) {
                                delete(marker)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(LibraryBackground())
            .navigationTitle("时刻标记")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成", action: dismiss.callAsFunction)
                }
            }
            .sheet(item: $markerToEdit) { marker in
                MarkerEditorSheet(marker: marker) { title, note in
                    try store.update(marker, title: title, note: note)
                }
            }
            .alert(item: $presentedError) { error in
                Alert(title: Text("标记操作失败"), message: Text(error.message))
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(.ultraThinMaterial)
    }

    private func jump(to marker: Marker) {
        onSeek(marker.time)
        dismiss()
    }

    private func delete(_ marker: Marker) {
        do {
            try store.delete(marker)
        } catch {
            presentedError = PresentedError(error)
        }
    }
}
