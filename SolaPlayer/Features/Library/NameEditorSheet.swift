import SwiftUI

struct NameEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var presentedError: PresentedError?

    let title: String
    let save: (String) throws -> Void

    init(title: String, initialName: String, save: @escaping (String) throws -> Void) {
        self.title = title
        self.save = save
        _name = State(initialValue: initialName)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("名称", text: $name)
                    .textInputAutocapitalization(.never)
                    .submitLabel(.done)
                    .onSubmit(saveAndDismiss)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消", action: dismiss.callAsFunction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: saveAndDismiss)
                }
            }
            .alert(item: $presentedError) { error in
                Alert(title: Text("无法保存"), message: Text(error.message))
            }
        }
        .presentationDetents([.medium])
    }

    private func saveAndDismiss() {
        do {
            try save(name)
            dismiss()
        } catch {
            presentedError = PresentedError(error)
        }
    }
}
