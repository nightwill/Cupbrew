import SwiftUI

/// The sheet a command that changes the formulae runs in.
struct OperationView: View {

    let operation: Operation
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(operation.title)
                Text(operation.subject)
                    .lineLimit(2)
                    .truncationMode(.middle)
            }
            .font(.system(size: 15))

            LogView(text: operation.run.log)
                .border(.separator)

            HStack {
                if operation.run.isRunning {
                    ProgressView()
                        .controlSize(.small)
                }
                Spacer()
                Button("OK") { dismiss() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(operation.run.isRunning)
            }
        }
        .padding()
        .frame(minWidth: 386, idealWidth: 480, minHeight: 271, idealHeight: 340)
        .interactiveDismissDisabled(operation.run.isRunning)
    }
}
