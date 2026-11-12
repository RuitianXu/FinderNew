import SwiftUI
import os

/// Host-side request handler: validates the URL-scheme request and creates the file.
final class HostModel: ObservableObject {
    static let shared = HostModel()

    @Published var lastAction = "尚未创建文件"
    @Published var lastError: String?
    @Published var extensionStatus = "未知"

    private static let log = Logger(subsystem: "com.xuruitian.FinderNew", category: "host")

    /// Handle findernew://create?template=<uuid>&dir=<dirURL>
    /// Security: fixed action, template UUID must exist in the manifest, strict directory
    /// validation, exclusive create; no shell, no arbitrary commands.
    func handleCreateRequest(_ url: URL) {
        lastError = nil
        guard url.scheme == "findernew", url.host == "create" else {
            lastError = "未知请求：\(url.absoluteString)"
            return
        }
        guard let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
              let templateID = items.first(where: { $0.name == "template" })?.value,
              let dirString = items.first(where: { $0.name == "dir" })?.value,
              let dirURL = URL(string: dirString),
              let templateUUID = UUID(uuidString: templateID) else {
            lastError = "请求参数缺失或非法"
            return
        }

        guard let template = TemplateRepository.shared.template(id: templateUUID) else {
            lastError = "模板不存在或已禁用"
            Self.log.error("rejected unknown template id \(templateID, privacy: .public)")
            return
        }

        // Strict path validation: existing, resolvable, real directory; standardize kills "..".
        let standardized = dirURL.standardizedFileURL
        var isDir: ObjCBool = false
        guard standardized.isFileURL,
              FileManager.default.fileExists(atPath: standardized.path, isDirectory: &isDir),
              isDir.boolValue,
              standardized.pathComponents.contains("..") == false else {
            lastError = "目标目录非法：\(standardized.path)"
            Self.log.error("rejected illegal target dir")
            return
        }

        do {
            let created: URL
            switch template.kind {
            case .text:
                let content = TemplateRepository.shared.textContent(for: template)
                created = try FileCreator.createTextFile(template: template, content: content, in: standardized)
            case .file:
                guard let source = TemplateRepository.shared.fileTemplateURL(for: template) else {
                    throw FileCreator.CreateError.fileTemplateMissing
                }
                created = try FileCreator.createFileFromTemplate(
                    template: template, templateFileURL: source, in: standardized)
            }
            NSWorkspace.shared.activateFileViewerSelecting([created])
            lastAction = "已创建 \(created.lastPathComponent)（\(standardized.path)）"
            Self.log.info("created \(created.lastPathComponent, privacy: .public)")
        } catch {
            lastError = (error as? FileCreator.CreateError)?.description ?? "\(error)"
            Self.log.error("create failed: \(String(describing: error))")
        }
    }
}
