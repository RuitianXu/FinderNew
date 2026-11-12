import Foundation

public enum FileNameSanitizer {
    /// Remove illegal path characters; keep dotfile names like ".env".
    public static func sanitize(_ name: String) -> String {
        var name = name
        for illegal in ["/", "\0", ":"] {
            name = name.replacingOccurrences(of: illegal, with: "-")
        }
        name = name.trimmingCharacters(in: .whitespaces)
        if name.isEmpty { name = "未命名" }
        return name
    }

    /// Returns an unused candidate URL; the caller must still create exclusively.
    public static func uniqueURL(baseName: String, ext: String, in directory: URL) -> URL {
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

public enum FileCreator {
    public enum CreateError: Error, CustomStringConvertible, Equatable {
        case notADirectory
        case templateNotFound
        case pathTraversal
        case fileTemplateMissing
        case ioFailure(underlying: String)

        public var description: String {
            switch self {
            case .notADirectory: return "目标路径不是文件夹"
            case .templateNotFound: return "模板不存在"
            case .pathTraversal: return "目标路径非法"
            case .fileTemplateMissing: return "文件模板副本丢失，请在设置中重新导入"
            case .ioFailure(let e): return "写入失败：\(e)"
            }
        }
    }

    /// Default initial content for builtin text templates when none is stored.
    public static func defaultTextContent(for template: Template) -> String {
        switch template.fileExtension {
        case "md": return "# 未命名\n"
        case "py": return "#!/usr/bin/env python3\n"
        case "html":
            return "<!DOCTYPE html>\n<html lang=\"zh\">\n<head>\n  <meta charset=\"UTF-8\">\n  <title>Untitled</title>\n</head>\n<body>\n</body>\n</html>\n"
        default: return ""
        }
    }

    /// Create a text-template file atomically exclusive (open O_CREAT|O_EXCL); never overwrites,
    /// safe under concurrency: on EEXIST the next candidate name is retried.
    public static func createTextFile(template: Template, content: String, in directory: URL) throws -> URL {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDir), isDir.boolValue else {
            throw CreateError.notADirectory
        }
        let clean = FileNameSanitizer.sanitize(template.defaultBaseName)
        let ext = template.fileExtension
        let data = Data(content.utf8)

        for n in 1...10_000 {
            let name = n == 1 ? "\(clean).\(ext)" : "\(clean) \(n).\(ext)"
            let path = directory.appendingPathComponent(name).path
            let fd = open(path, O_CREAT | O_EXCL | O_WRONLY, 0o644)
            if fd == -1 {
                if errno == EEXIST { continue }   // raced or taken: next candidate
                throw CreateError.ioFailure(underlying: String(cString: strerror(errno)))
            }
            defer { close(fd) }
            do {
                // The O_EXCL open already guarantees we own this file exclusively.
                try data.write(to: URL(fileURLWithPath: path))
            } catch {
                throw CreateError.ioFailure(underlying: error.localizedDescription)
            }
            return URL(fileURLWithPath: path)
        }
        throw CreateError.ioFailure(underlying: "无法生成唯一文件名")
    }

    /// Create a file from a full-file template via same-directory temp copy + rename.
    /// Rename target is created exclusively, so an existing file is never clobbered.
    public static func createFileFromTemplate(template: Template, templateFileURL: URL, in directory: URL) throws -> URL {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDir), isDir.boolValue else {
            throw CreateError.notADirectory
        }
        guard FileManager.default.fileExists(atPath: templateFileURL.path) else {
            throw CreateError.fileTemplateMissing
        }
        let clean = FileNameSanitizer.sanitize(template.defaultBaseName)
        let ext = template.fileExtension
        for n in 1...10_000 {
            let name = n == 1 ? "\(clean).\(ext)" : "\(clean) \(n).\(ext)"
            let target = directory.appendingPathComponent(name)
            let tmp = directory.appendingPathComponent(".\(UUID().uuidString).tmp")
            defer { try? FileManager.default.removeItem(at: tmp) }
            do {
                try FileManager.default.copyItem(at: templateFileURL, to: tmp)
                // rename(2) semantics: fails if target exists (no overwrite), atomic publish.
                try FileManager.default.moveItem(at: tmp, to: target)
                return target
            } catch let error as NSError where error.code == NSFileWriteFileExistsError {
                continue   // raced: try next candidate
            } catch {
                throw CreateError.ioFailure(underlying: error.localizedDescription)
            }
        }
        throw CreateError.ioFailure(underlying: "无法生成唯一文件名")
    }
}
