import FinderSync
import os

/// Finder Sync Extension principal class.
/// Only builds the menu and hands off (template id + target dir) to the host via URL scheme.
class FinderSyncController: FIFinderSync {

    private static let log = Logger(subsystem: "com.xuruitian.FinderNew", category: "extension")

    override init() {
        super.init()
        Self.log.info("extension initialized")
        // Watch the whole filesystem tree (includes mounted volumes).
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    // MARK: - Menu

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        Self.log.info("building menu, kind=\(menuKind.rawValue)")
        let menu = NSMenu(title: "FinderNew")
        let enabled = Template.builtin().filter { $0.isEnabled }.sorted { $0.sortOrder < $1.sortOrder }
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
        let enabled = Template.builtin().filter { $0.isEnabled }.sorted { $0.sortOrder < $1.sortOrder }
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
