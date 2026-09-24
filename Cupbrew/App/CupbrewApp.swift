import SwiftUI

@main
struct CupbrewApp: App {

    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @State private var homebrew = Homebrew()

    var body: some Scene {
        Window(Text("Cupbrew"), id: "main") {
            MainView(homebrew: homebrew)
        }
        .defaultSize(width: 826, height: 480)
        .commands {
            CupbrewCommands()
        }
    }
}
