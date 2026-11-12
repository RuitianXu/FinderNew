import FinderSync
import os

/// Finder Sync Extension principal class.
/// Only builds the menu from the bundled template manifest and hands off
/// (template id + target dir) to the host via URL scheme.
class FinderSyncController: FIFinderSync {

    private static let log = Logger(subsystem: "com.xuruitian.FinderNew", category: "extension")

    override init() {
        super.init()
        Self.log.info("extension initialized")
        // Watch the whole filesystem tree (includes mounted volumes).
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    /// Manifest lives in the host app bundle Resources; the extension bundle is embedded at
    /// <Host>.app/Contents/PlugIns/<Ext>.appex, so the host bundle is two levels up.
    private var manifestURL: URL? {
        let extBundle = Bundle(for: FinderSyncController.self).bundleURL
        let manifest = extBundle
            .deletingLastPathComponent()            // PlugIns
            .deletingLastPathComponent()            // Contents
            .appendingPathComponent("Resources/templates.json")
        return FileManager.default.fileExists(atPath: manifest.path) ? manifest : nil
    }

    // Tag conventions: >= 0 selects a template by index; negative tags are built-in actions.
    private enum ActionTag {
        static let copyFolderPath = -1
        static let copyItemPaths = -2
    }

    // MARK: - Menu

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        Self.log.info("building menu, kind=\(menuKind.rawValue)")
        let menu = NSMenu(title: "FinderNew")

        switch menuKind {
        case .contextualMenuForContainer, .toolbarItemMenu:
            menu.addItem(makeItem(title: "复制文件夹路径", tag: ActionTag.copyFolderPath))
        case .contextualMenuForItems:
            menu.addItem(makeItem(title: "复制文件路径", tag: ActionTag.copyItemPaths))
        default:
            break
        }

        let templateItems = templateMenuItems()
        if !templateItems.isEmpty && !menu.items.isEmpty {
            menu.addItem(.separator())
        }
        templateItems.forEach { menu.addItem($0) }
        return menu
    }

    private func makeItem(title: String, tag: Int) -> NSMenuItem {
        let item = NSMenuItem(title: title,
                              action: #selector(handleMenuAction(_:)),
                              keyEquivalent: "")
        // Finder drops representedObject on menu callbacks; tag survives.
        item.tag = tag
        item.target = self
        return item
    }

    private func templateMenuItems() -> [NSMenuItem] {
        let templates: [Template]
        if let url = manifestURL, let loaded = try? TemplateStore.load(from: url) {
            templates = loaded
        } else {
            Self.log.error("template manifest missing or invalid")
            templates = []
        }
        let enabled = Template.enabledSorted(templates)
        return enabled.enumerated().map { index, template in
            makeItem(title: template.displayName, tag: index)
        }
    }

    // MARK: - Actions

    @objc func handleMenuAction(_ sender: NSMenuItem) {
        switch sender.tag {
        case ActionTag.copyFolderPath:
            copyToClipboard(paths: [FIFinderSyncController.default().targetedURL()?.path])
        case ActionTag.copyItemPaths:
            let urls = FIFinderSyncController.default().selectedItemURLs() ?? []
            copyToClipboard(paths: urls.map { $0.path })
        case let tag where tag >= 0:
            createFromTemplate(sender)
        default:
            Self.log.error("unknown tag: \(sender.tag)")
        }
    }

    private func copyToClipboard(paths: [String?]) {
        let valid = paths.compactMap { $0 }
        guard !valid.isEmpty else {
            Self.log.error("no path available to copy")
            return
        }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(valid.joined(separator: "\n"), forType: .string)
        Self.log.info("copied \(valid.count) path(s)")
    }

    // MARK: - Action

    @objc func createFromTemplate(_ sender: NSMenuItem) {
        Self.log.info("create action fired, tag=\(sender.tag)")
        guard let url = manifestURL, let templates = try? TemplateStore.load(from: url) else {
            Self.log.error("manifest unavailable at action time")
            return
        }
        let enabled = Template.enabledSorted(templates)
        guard enabled.indices.contains(sender.tag) else {
            Self.log.error("tag out of range: \(sender.tag)")
            return
        }
        let templateID = enabled[sender.tag].id.uuidString

        guard let target = FIFinderSyncController.default().targetedURL() else {
            Self.log.error("targetedURL nil")
            return
        }
        Self.log.info("target=\(target.path, privacy: .public)")

        var comps = URLComponents()
        comps.scheme = "findernew"
        comps.host = "create"
        comps.queryItems = [
            URLQueryItem(name: "template", value: templateID),
            URLQueryItem(name: "dir", value: target.absoluteString),
        ]
        guard let url = comps.url else {
            Self.log.error("failed to build URL")
            return
        }
        NSWorkspace.shared.open(url, configuration: NSWorkspace.OpenConfiguration()) { app, error in
            if let error {
                Self.log.error("open failed: \(error.localizedDescription, privacy: .public)")
            } else {
                Self.log.info("opened host: \(app?.localizedName ?? "?", privacy: .public)")
            }
        }
    }
}
