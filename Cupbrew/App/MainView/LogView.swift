import SwiftUI

/// Command output as the terminal would show it, kept scrolled to the end
/// while it grows.
struct LogView: View {

    let text: String

    var body: some View {
        ScrollView {
            Text(text)
                // swiftlint:disable:next non_localized_string
                .font(.custom("Andale Mono", size: 12))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6)
        }
        .defaultScrollAnchor(.bottom, for: .sizeChanges)
        .background(Color(nsColor: .textBackgroundColor))
    }
}
