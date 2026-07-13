import SwiftUI
import UIKit
import UniformTypeIdentifiers

enum AudioDocumentPickerError: LocalizedError {
    case presentationUnavailable

    var errorDescription: String? {
        "无法打开系统文件选择器，请稍后重试。"
    }
}

enum AudioImportMode: Identifiable, Equatable {
    case audio
    case folder

    var id: Self { self }

    var allowedContentTypes: [UTType] {
        switch self {
        case .audio:
            [.audio, .mp3, .mpeg4Audio, .wav, .aiff, .item]
        case .folder:
            [.folder]
        }
    }

    var allowsMultipleSelection: Bool {
        self == .audio
    }

    var importsAsCopy: Bool {
        self == .audio
    }
}

struct AudioDocumentPicker: UIViewControllerRepresentable {
    @Binding var mode: AudioImportMode?
    let onPick: ([URL]) -> Void
    let onFailure: (Error) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        context.coordinator.hostController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        context.coordinator.parent = self
        context.coordinator.presentIfNeeded(for: mode)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate, UIAdaptivePresentationControllerDelegate {
        var parent: AudioDocumentPicker
        let hostController = UIViewController()
        private var isPresenting = false

        init(_ parent: AudioDocumentPicker) {
            self.parent = parent
        }

        func presentIfNeeded(for mode: AudioImportMode?) {
            guard let mode, isPresenting == false else {
                return
            }
            isPresenting = true
            present(mode: mode, attempt: 0)
        }

        private func present(mode: AudioImportMode, attempt: Int) {
            guard let presenter = Self.topViewController(),
                  presenter.presentedViewController == nil else {
                guard attempt < 10 else {
                    parent.onFailure(AudioDocumentPickerError.presentationUnavailable)
                    finish(delivering: nil)
                    return
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                    self?.present(mode: mode, attempt: attempt + 1)
                }
                return
            }

            let picker = UIDocumentPickerViewController(
                forOpeningContentTypes: mode.allowedContentTypes,
                asCopy: mode.importsAsCopy
            )
            picker.allowsMultipleSelection = mode.allowsMultipleSelection
            picker.shouldShowFileExtensions = true
            picker.delegate = self
            picker.presentationController?.delegate = self
            presenter.present(picker, animated: true)
        }

        private static func topViewController() -> UIViewController? {
            let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
            let window = scene?.windows.first { $0.isKeyWindow } ?? scene?.windows.first
            var top = window?.rootViewController
            while let presented = top?.presentedViewController {
                top = presented
            }
            return top
        }

        func documentPicker(
            _ controller: UIDocumentPickerViewController,
            didPickDocumentsAt urls: [URL]
        ) {
            finish(delivering: urls)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            finish(delivering: nil)
        }

        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            finish(delivering: nil)
        }

        private func finish(delivering urls: [URL]?) {
            guard isPresenting else {
                return
            }
            isPresenting = false
            if let urls, urls.isEmpty == false {
                parent.onPick(urls)
            }
            parent.mode = nil
        }
    }
}
