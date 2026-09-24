import AppKit
import UserNotifications

/// Tells the user a long command is over while they are looking elsewhere:
/// a bounce in the Dock, a dot on the icon and a notification.
@MainActor
enum Attention {

    static func taskFinished(_ subtitle: String) {
        NSApp.requestUserAttention(.informationalRequest)
        if !NSApp.isActive {
            NSApp.dockTile.badgeLabel = "●"
        }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Task Finished")
        content.subtitle = subtitle
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        Task {
            let center = UNUserNotificationCenter.current()
            guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true else { return }
            try? await center.add(request)
        }
    }

    /// The user is back: whatever was waiting for them has been seen.
    static func clear() {
        NSApp.dockTile.badgeLabel = nil
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}
