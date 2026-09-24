import SwiftUI

/// The sheet for picking the options a formula is installed with.
struct FormulaOptionsView: View {

    let name: String
    let browser: Browser

    @Environment(\.dismiss) private var dismiss
    @State private var options: [FormulaInfo.Option]?
    @State private var chosen: Set<String> = []
    @State private var highlighted: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Picking Options for Formula:")
                Text(name)
                    .bold()
            }
            .font(.system(size: 15))

            Table(options ?? [], selection: $highlighted) {
                TableColumn("") { option in
                    Toggle("", isOn: binding(for: option.option))
                        .labelsHidden()
                        .help(option.description)
                }
                .width(18)
                TableColumn("Options") { option in
                    Text(option.option)
                        .help(option.description)
                }
            }
            .overlay {
                if options == nil { ProgressView() }
            }

            Text(highlightedDescription ?? String(localized: "Description for selected option."))
                .foregroundStyle(highlightedDescription == nil ? .secondary : .primary)
                .frame(maxWidth: .infinity, minHeight: 36, alignment: .topLeading)
                .padding(6)
                .background(.quaternary, in: .rect(cornerRadius: 4))
                .textSelection(.enabled)

            HStack {
                Text(options?.isEmpty == true
                     ? String(localized: "This formula has no installation options available.")
                     : String(localized: "Click on option for details."))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Install") {
                    let picked = (options ?? []).map(\.option).filter(chosen.contains)
                    dismiss()
                    browser.install(name, options: picked)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(options == nil)
            }
        }
        .padding()
        .frame(minWidth: 480, minHeight: 315)
        .task {
            guard let brew = browser.homebrew.brew else { return }
            let json = await brew.output(["info", "--json=v2", "--formula", name])
            options = FormulaInfo(json: json)?.options ?? []
        }
    }

    private var highlightedDescription: String? {
        options?.first { $0.option == highlighted }?.description
    }

    private func binding(for option: String) -> Binding<Bool> {
        Binding {
            chosen.contains(option)
        } set: { isOn in
            if isOn { chosen.insert(option) } else { chosen.remove(option) }
        }
    }
}
