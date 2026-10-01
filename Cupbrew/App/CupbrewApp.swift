import Sparkle
import SwiftUI

@main
struct CupbrewApp: App {

    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @State private var homebrew = Homebrew()
    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    var body: some Scene {
        Window(Text("Cupbrew"), id: "main") {
            MainView(homebrew: homebrew)
        }
        .defaultSize(width: 826, height: 480)
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
            CupbrewCommands()
        }
    }
}
