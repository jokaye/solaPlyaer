import SwiftUI

struct MarkerEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let marker: Marker
    let onSave: (String, String) throws -> Void

    @State private var title: String
    @State private var note: String
    @State private var presentedError: PresentedError?

    init(marker: Marker, onSave: @escaping (String, String) throws -> Void) {
        self.marker = marker
        self.onSave = onSave
        _title = State(initialValue: marker.title)
        _note = State(initialValue: marker.note)
    }

    var body: some View {
        NavigationStack {
            Form {
                LabeledContent("时间", value: marker.time.durationText)

                TextField("名称", text: $title)

                TextField("备注（可选）", text: $note, axis: .vertical)
                    .lineLimit(3...6)
            }
            .navigationTitle("编辑标记")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消", action: dismiss.callAsFunction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: save)
                }
            }
            .alert(item: $presentedError) { error in
                Alert(title: Text("无法保存标记"), message: Text(error.message))
            }
        }
        .presentationDetents([.medium])
    }

    private func save() {
        do {
            try onSave(title, note)
            dismiss()
        } catch {
            presentedError = PresentedError(error)
        }
    }
}
