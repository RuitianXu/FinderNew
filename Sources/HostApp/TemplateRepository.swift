import Foundation
import os

/// Host-side template repository.
/// Metadata manifest:  <App bundle>/Contents/Resources/templates.json (also read by the extension).
/// Text contents:      ~/Library/Application Support/FinderNew/Text/<uuid>.txt
/// File templates:     ~/Library/Application Support/FinderNew/FileTemplates/<uuid>.<ext>
/// Builtin Office templates ship in the bundle at Resources/OfficeTemplates/<id>.<ext>.
final class TemplateRepository {
    static let shared = TemplateRepository()

    private static let log = Logger(subsystem: "com.xuruitian.FinderNew", category: "repo")

    let manifestURL: URL
    let officeDir: URL
    private let textDir: URL
    private let fileDir: URL

    init() {
        let contents = Bundle.main.bundleURL.appendingPathComponent("Contents")
        manifestURL = contents.appendingPathComponent("Resources/templates.json")
        officeDir = contents.appendingPathComponent("Resources/OfficeTemplates")
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FinderNew", isDirectory: true)
        textDir = support.appendingPathComponent("Text", isDirectory: true)
        fileDir = support.appendingPathComponent("FileTemplates", isDirectory: true)
        for dir in [textDir, fileDir] {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    func templates() -> [Template] {
        (try? TemplateStore.load(from: manifestURL)) ?? []
    }

    func template(id: UUID) -> Template? {
        templates().first { $0.id == id }
    }

    /// Resolve the source content for a text template.
    func textContent(for template: Template) -> String {
        assert(template.kind == .text)
        let stored = textDir.appendingPathComponent(template.id.uuidString + ".txt")
        if let s = try? String(contentsOf: stored, encoding: .utf8) {
            return s
        }
        return FileCreator.defaultTextContent(for: template)
    }

    /// Resolve the source file for a file template: user copy first, then bundled builtin.
    func fileTemplateURL(for template: Template) -> URL? {
        assert(template.kind == .file)
        let userCopy = fileDir.appendingPathComponent("\(template.id.uuidString).\(template.fileExtension)")
        if FileManager.default.fileExists(atPath: userCopy.path) {
            return userCopy
        }
        let bundled = officeDir.appendingPathComponent("\(template.id.uuidString).\(template.fileExtension)")
        return FileManager.default.fileExists(atPath: bundled.path) ? bundled : nil
    }

    /// Persist a user file-template copy keyed by template id.
    func importFileTemplate(contentsOf source: URL, for template: Template) throws {
        let dest = fileDir.appendingPathComponent("\(template.id.uuidString).\(template.fileExtension)")
        let tmp = fileDir.appendingPathComponent(".\(UUID().uuidString).tmp")
        if FileManager.default.fileExists(atPath: dest.path) {
            try FileManager.default.removeItem(at: dest)
        }
        try FileManager.default.copyItem(at: source, to: tmp)
        try FileManager.default.moveItem(at: tmp, to: dest)
        Self.log.info("imported file template for \(template.id.uuidString)")
    }

    /// Store custom initial content for a text template.
    func storeTextContent(_ content: String, for template: Template) throws {
        let dest = textDir.appendingPathComponent(template.id.uuidString + ".txt")
        try content.data(using: .utf8)?.write(to: dest, options: .atomic)
    }
}
