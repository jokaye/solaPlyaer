import SwiftUI

struct LibraryHeaderView: View {
    let itemCount: Int
    let groupCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("音库")
                .appFont(AppTypography.libraryTitle)
                .accessibilityAddTraits(.isHeader)

            Text("\(itemCount) 段音频 · \(groupCount) 个分组")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.content)
    }
}
