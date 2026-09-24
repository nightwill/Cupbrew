import SwiftUI

/// Takes the place of the lists when there is no Homebrew to ask.
struct MissingBrewView: View {

    var body: some View {
        VStack(spacing: 6) {
            Text("Homebrew is not installed")
                .font(.system(size: 15, weight: .bold))
            Text("Please visit brew.sh to install Homebrew")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}
