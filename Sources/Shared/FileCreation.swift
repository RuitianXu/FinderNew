import Foundation

/// Shared core: template model + exclusive file creation rules.
/// Must not depend on Finder private APIs so both host and extension can use it.

enum TemplateKind: String, Codable {
    case text
    case file
}

struct Template: Codable, Identifiable, Equatable {
    var id: UUID
    var displayName: String
    var defaultBaseName: String
    var fileExtension: String   // may be empty for dotfile-less templates like ".env" handled via defaultBaseName
    var kind: TemplateKind
    var textContent: String
    var isEnabled: Bool
    var sortOrder: Int

    /// Built-in spike templates (Phase 1 will move these to a persistent store with Office templates).
    static func builtin() -> [Template] {
        return [
            Template(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                     displayName: "文本文件 (.txt)", defaultBaseName: "未命名",
                     fileExtension: "txt", kind: .text, textContent: "", isEnabled: true, sortOrder: 0),
            Template(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                     displayName: "Markdown (.md)", defaultBaseName: "未命名",
                     fileExtension: "md", kind: .text,
                     textContent: "# 未命名\n", isEnabled: true, sortOrder: 1),
            Template(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
                     displayName: "Python (.py)", defaultBaseName: "untitled",
                     fileExtension: "py", kind: .text,
                     textContent: "#!/usr/bin/env python3\n", isEnabled: true, sortOrder: 2),
        ]
    }
}

enum FileNameSanitizer {
    /// Remove illegal path components; keep dotfile names like ".env".
    static func sanitize(_ name: String) -> String {
        var name = name
        for illegal in ["/", "\0", ":"] {
            name = name.replacingOccurrences(of: illegal, with: "-")
        }
        name = name.trimmingCharacters(in: .whitespaces)
        if name.isEmpty { name = "未命名" }
        return name
    }

    /// Produce a unique URL using exclusive creation; never overwrites.
    /// Returns nil if the directory itself is unwritable.
    static func uniqueURL(baseName: String, ext: String, in directory: URL) -> URL {
        let clean = sanitize(baseName)
        let candidate: (Int) -> String = { n in
            n == 1 ? "\(clean).\(ext)" : "\(clean) \(n).\(ext)"
        }
        var n = 1
        while n < 10_000 {
            let url = directory.appendingPathComponent(candidate(n))
            if !FileManager.default.fileExists(atPath: url.path) {
                return url
            }
            n += 1
        }
        return directory.appendingPathComponent("\(clean)-\(UUID().uuidString.prefix(8)).\(ext)")
    }
}

enum FileCreator {
    enum CreateError: Error, CustomStringConvertible {
        case notADirectory
        case templateNotFound
        case pathTraversal
        case ioFailure(underlying: String)

        var description: String {
            switch self {
            case .notADirectory: return "目标路径不是文件夹"
            case .templateNotFound: return "模板不存在"
            case .pathTraversal: return "目标路径非法"
            case .ioFailure(let e): return "写入失败：\(e)"
            }
        }
    }

    /// Create a text-template file with exclusive create (O_CREAT | O_EXCL semantics).
    static func createTextFile(template: Template, in directory: URL) throws -> URL {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDir), isDir.boolValue else {
            throw CreateError.notADirectory
        }
        let target = FileNameSanitizer.uniqueURL(
            baseName: template.defaultBaseName,
            ext: template.fileExtension,
            in: directory)
        // Exclusive create: fails if the file appeared between the check above and now.
        if !FileManager.default.createFile(atPath: target.path,
                                           contents: template.textContent.data(using: .utf8),
                                           attributes: [.posixPermissions: 0o644]) {
            throw CreateError.ioFailure(underlying: "文件可能已存在或目录不可写")
        }
        return target
    }
}
