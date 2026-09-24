import SwiftUI

/// `brew info` or the dependents of a formula, next to its row.
struct FormulaPopoverView: View {

    let popover: FormulaPopover
    let brew: Brew?

    @State private var text: String?

    var body: some View {
        VStack(spacing: 8) {
            Text(popover.title)
                .font(.system(size: 16))
                .lineLimit(1)
                .truncationMode(.middle)
            if let text {
                LogView(text: text)
            } else {
                ProgressView()
                    .controlSize(.large)
                    .frame(maxHeight: .infinity)
            }
        }
        .padding()
        .frame(width: 450, height: 250)
        .task(id: popover.id) {
            guard let brew else { return }
            var output = ""
            await brew.run(popover.arguments) { output += $0 }
            text = output
        }
    }
}
