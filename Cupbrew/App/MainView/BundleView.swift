import SwiftUI

/// The sheet a Brewfile is written or read in.
struct BundleView: View {

    let job: BundleJob
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 12) {
            Text("Homebrew Bundle")
                .font(.headline)

            switch job.kind {
            case .export: exportStatus
            case .import: importLog
            }

            HStack {
                if !job.isFinished {
                    ProgressView()
                        .controlSize(.small)
                }
                Spacer()
                Button("Close") { dismiss() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!job.isFinished)
            }
        }
        .padding()
        .frame(minWidth: 360, idealWidth: 420, minHeight: 272)
        .interactiveDismissDisabled(!job.isFinished)
    }

    @ViewBuilder private var exportStatus: some View {
        VStack(spacing: 8) {
            Spacer()
            if !job.isFinished {
                Text("Exporting File")
                    .font(.title3)
                Text("Please wait while the file is generated.")
                    .foregroundStyle(.secondary)
            } else if let error = job.error {
                Label("Export Failed", systemImage: "xmark.octagon.fill")
                    .font(.title3)
                    .foregroundStyle(.red)
                Text(error)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .textSelection(.enabled)
            } else {
                Label("Export Successful", systemImage: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder private var importLog: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Importing File")
                .font(.title3)
            if !job.isFinished {
                Text("Please wait while the file is imported.")
                    .foregroundStyle(.secondary)
            }
            LogView(text: job.run.log)
                .border(.separator)
        }
    }
}
