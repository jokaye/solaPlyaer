import SwiftUI

struct AboutView: View {
    var body: some View {
        Form {
            Section("应用") {
                LabeledContent("版本", value: BuildInfo.version)
                LabeledContent("构建号", value: BuildInfo.buildNumber)
                LabeledContent("Commit") {
                    Text(BuildInfo.gitCommitSHA)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                }
            }

            Section("运行环境") {
                LabeledContent("最低系统", value: "iOS 17.0")
                LabeledContent("数据状态", value: "M0 · 工程脚手架")
            }
        }
        .navigationTitle("关于与诊断")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
