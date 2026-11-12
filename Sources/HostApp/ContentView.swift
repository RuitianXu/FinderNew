import SwiftUI

struct ContentView: View {
    @EnvironmentObject var model: HostModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("FinderNew")
                .font(.title2.bold())
            Text("Finder 右键“新建文件”扩展的开发预览（Phase 0 Spike）。")
                .foregroundStyle(.secondary)
            Text("扩展状态：\(model.extensionStatus)")
            Text("最近一次操作：\(model.lastAction)")

            if let err = model.lastError {
                Text("错误：\(err)").foregroundStyle(.red)
            }

            Spacer()
            Text("请保持本 App 运行或在“系统设置 → 登录项与扩展”中启用 Finder 扩展。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(20)
    }
}
