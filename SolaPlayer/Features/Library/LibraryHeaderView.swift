import SwiftUI

struct LibraryHeaderView: View {
    let itemCount: Int
    let groupCount: Int
    let isImporting: Bool
    let onAudioImport: () -> Void
    let onFolderImport: () -> Void
    let onLinkImport: () -> Void
    let onManageGroups: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: AppSpacing.standard) {
            VStack(alignment: .leading, spacing: 3) {
                Text("音库")
                    .appFont(AppTypography.libraryTitle)
                    .accessibilityAddTraits(.isHeader)

                Text("\(itemCount) 段音频 · \(groupCount) 个分组")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Menu("更多", systemImage: "ellipsis") {
                NavigationLink(value: RootRoute.settings) {
                    Label("设置", systemImage: "gearshape")
                }
                Button("从链接导入", systemImage: "link", action: onLinkImport)
                Button("管理分组", systemImage: "rectangle.3.group", action: onManageGroups)
                    .disabled(groupCount == 0)
                NavigationLink(value: RootRoute.about) {
                    Label("关于与诊断", systemImage: "info.circle")
                }
            }
            .labelStyle(.iconOnly)
            .foregroundStyle(.primary)
            .frame(width: 40, height: 40)
            .background(.primary.opacity(0.055), in: .circle)

            Menu {
                Button("选择音频文件", systemImage: "waveform.badge.plus", action: onAudioImport)
                Button("选择音频文件夹", systemImage: "folder.badge.plus", action: onFolderImport)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(.primary)
                    .frame(width: 48, height: 48)
                    .background(.primary.opacity(0.065), in: .circle)
            }
                .accessibilityLabel("导入音频")
                .disabled(isImporting)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.content)
    }
}
