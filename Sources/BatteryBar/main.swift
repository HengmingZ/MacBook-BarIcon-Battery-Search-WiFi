import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        self.statusBarController = StatusBarController()
        NSLog("[BatteryBar] BatteryBar started successfully.")
    }
}

if let bundleID = Bundle.main.bundleIdentifier,
   NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).contains(where: { $0 != NSRunningApplication.current }) {
    NSLog("[BatteryBar] Another instance is already running, exiting.")
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
