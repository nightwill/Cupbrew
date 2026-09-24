import SwiftUI

/// The Doctor and Update pages: one command, its button and its output.
struct ToolView: View {

    let title: LocalizedStringResource
    let buttonTitle: LocalizedStringResource
    let run: BrewRun
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 16))
                if run.isRunning {
                    ProgressView()
                        .controlSize(.small)
                }
                Spacer()
                Button("Clear Log") { run.clear() }
                    .disabled(run.isRunning || run.log.isEmpty)
                Button(buttonTitle, action: action)
                    .disabled(run.isRunning || !isEnabled)
            }
            LogView(text: run.log)
                .border(.separator)
        }
        .padding()
    }
}
