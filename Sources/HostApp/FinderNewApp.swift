import SwiftUI
import ServiceManagement

@main
struct FinderNewHostApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var model = HostModel.shared

    var body: some Scene {
        WindowGroup("FinderNew") {
            ContentView()
                .environmentObject(model)
                .frame(width: 460, height: 300)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as a background agent: no Dock icon, windows still reachable via `open -a FinderNew`.
        NSApp.setActivationPolicy(.accessory)

        // Register as a login item so the URL handler is always available after reboot.
        // Already-registered is not an error.
        switch SMAppService.mainApp.status {
        case .enabled:
            break
        default:
            do {
                try SMAppService.mainApp.register()
            } catch {
                NSLog("FinderNew: login item registration failed: \(error)")
            }
        }

        // Handle findernew://create?... whether the app was cold-launched by the URL or already running.
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL))
    }

    @objc func handleGetURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent reply: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: urlString) else { return }
        HostModel.shared.handleCreateRequest(url)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep running so the URL handler stays responsive even with the window closed.
        false
    }
}
