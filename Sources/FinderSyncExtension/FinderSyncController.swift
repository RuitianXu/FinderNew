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

    // MARK: - Menu

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        Self.log.info("building menu, kind=\(menuKind.rawValue)")
        let menu = NSMenu(title: "FinderNew")

        let templates: [Template]
        if let url = manifestURL, let loaded = try? TemplateStore.load(from: url) {
            templates = loaded
        } else {
            Self.log.error("template manifest missing or invalid")
            templates = []
        }

        let enabled = Template.enabledSorted(templates)
        for (index, template) in enabled.enumerated() {
            let item = NSMenuItem(title: template.displayName,
                                  action: #selector(createFromTemplate(_:)),
                                  keyEquivalent: "")
            // Finder drops representedObject on menu callbacks; tag survives.
            item.tag = index
            item.target = self
            menu.addItem(item)
        }
        return menu
    }

    // MARK: - Action

    @objc func createFromTemplate(_ sender: NSMenuItem) {
        Self.log.info("action fired, tag=\(sender.tag)")
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
