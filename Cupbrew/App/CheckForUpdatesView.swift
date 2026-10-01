import Observation
import Sparkle
import SwiftUI

/// "Check for Updates…" in the app menu, where Cakebrew had it too.
///
/// The feed and the public key every update must be signed with are in
/// `Info.plist`; the private half stays in the release machine's Keychain.
struct CheckForUpdatesView: View {

    @State private var model: Model

    init(updater: SPUUpdater) {
        _model = State(initialValue: Model(updater: updater))
    }

    var body: some View {
        Button("Check for Updates…") { model.updater.checkForUpdates() }
            .disabled(!model.canCheck)
    }

    // Not private: @Observable conforms it in an extension outside this type.
    @MainActor
    @Observable
    final class Model {

        let updater: SPUUpdater

        /// False while a check is already under way.
        private(set) var canCheck = false

        @ObservationIgnored private var observation: NSKeyValueObservation?

        init(updater: SPUUpdater) {
            self.updater = updater
            observation = updater.observe(\.canCheckForUpdates, options: [.initial, .new]) { [weak self] updater, _ in
                let canCheck = updater.canCheckForUpdates
                MainActor.assumeIsolated { self?.canCheck = canCheck }
            }
        }
    }
}
