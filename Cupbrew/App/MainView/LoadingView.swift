import SwiftUI

/// Covers the window until the lists have been read for the first time.
struct LoadingView: View {

    var body: some View {
        VStack(spacing: 12) {
            Text("Loading")
                .font(.system(size: 15, weight: .bold))
            ProgressView()
                .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}
