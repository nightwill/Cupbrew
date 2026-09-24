import SwiftUI

/// The panel under the rows with what `brew info` says about the selection.
struct SelectedFormulaView: View {

    let browser: Browser

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Selected Formula Information")
                .bold()
            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 8, verticalSpacing: 3) {
                row("Description:", description)
                row("Location:", location)
                row("Version:", browser.info?.versions.stable)
                row("Dependencies:", dependencies)
                row("Conflicts:", conflicts)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func row(_ label: LocalizedStringResource, _ value: String?) -> some View {
        GridRow {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .gridColumnAlignment(.trailing)
            Text(value ?? "--")
                .font(.system(size: 11))
                .textSelection(.enabled)
                .lineLimit(2)
        }
    }

    private var description: String? {
        guard let info = browser.info else { return nil }
        return info.desc ?? String(localized: "No description provided.")
    }

    private var location: String? {
        guard let info = browser.info else { return nil }
        return browser.homebrew.cellar.flatMap(info.installPath(cellar:)) ?? String(localized: "Formula Not Installed.")
    }

    private var dependencies: String? {
        guard let info = browser.info else { return nil }
        return info.dependencies.isEmpty
            ? String(localized: "This formula has no dependencies!")
            : info.dependencies.joined(separator: "; ")
    }

    private var conflicts: String? {
        guard let info = browser.info else { return nil }
        return info.conflictsWith.isEmpty
            ? String(localized: "This formula has no known conflicts.")
            : info.conflictsWith.joined(separator: "; ")
    }
}
