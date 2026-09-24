import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        Attention.clear()
    }

    func applicationWillTerminate(_ notification: Notification) {
        Brew.terminateAll()
    }
}
