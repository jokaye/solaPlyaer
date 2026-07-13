import UniformTypeIdentifiers
import Testing
@testable import SolaPlayer

struct AudioImportModeTests {
    @Test("音频选择器使用复制模式并允许多选")
    func audioPickerConfiguration() {
        let mode = AudioImportMode.audio

        #expect(mode.importsAsCopy)
        #expect(mode.allowsMultipleSelection)
        #expect(mode.allowedContentTypes.contains(.audio))
        #expect(mode.allowedContentTypes.contains(.mpeg4Audio))
        #expect(mode.allowedContentTypes.contains(.item))
    }

    @Test("文件夹选择器使用原位授权且仅允许单选")
    func folderPickerConfiguration() {
        let mode = AudioImportMode.folder

        #expect(mode.importsAsCopy == false)
        #expect(mode.allowsMultipleSelection == false)
        #expect(mode.allowedContentTypes == [.folder])
    }
}
