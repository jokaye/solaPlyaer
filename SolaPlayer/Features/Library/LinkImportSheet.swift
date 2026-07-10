import SwiftUI

struct LinkImportSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onImport: (URL) async throws -> Void

    @State private var link = ""
    @State private var pendingURL: URL?
    @State private var presentedError: PresentedError?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://example.com/audio.mp3", text: $link)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .disabled(pendingURL != nil)
                } header: {
                    Text("音频链接")
                } footer: {
                    Text("支持服务器直接返回的 HTTP/HTTPS 音频文件。")
                }

                if pendingURL != nil {
                    ProgressView("正在下载并导入…")
                }
            }
            .navigationTitle("从链接导入")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消", action: dismiss.callAsFunction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("导入", action: submit)
                        .disabled(link.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || pendingURL != nil)
                }
            }
            .alert(item: $presentedError) { error in
                Alert(title: Text("链接导入失败"), message: Text(error.message))
            }
        }
        .presentationDetents([.medium])
        .task(id: pendingURL) {
            guard let pendingURL else {
                return
            }
            await performImport(pendingURL)
        }
    }

    private func submit() {
        let normalizedLink = link.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: normalizedLink),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            presentedError = PresentedError(RemoteAudioImportError.invalidURL(normalizedLink))
            return
        }
        pendingURL = url
    }

    private func performImport(_ url: URL) async {
        do {
            try await onImport(url)
            dismiss()
        } catch is CancellationError {
            pendingURL = nil
        } catch {
            pendingURL = nil
            presentedError = PresentedError(error)
        }
    }
}
