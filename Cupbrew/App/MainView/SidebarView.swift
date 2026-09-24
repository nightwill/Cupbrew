import SwiftUI

struct SidebarView: View {

    let browser: Browser

    var body: some View {
        List(selection: selection) {
            Section("Formulae") {
                ForEach(SidebarItem.formulae, id: \.self, content: row)
            }
            Section("Tools") {
                ForEach(SidebarItem.tools, id: \.self, content: row)
            }
        }
        .listStyle(.sidebar)
        .disabled(!browser.isReady)
    }

    private func row(_ item: SidebarItem) -> some View {
        Label {
            Text(item.title)
        } icon: {
            Image(systemName: item.symbol)
        }
        .badge(browser.isReady ? browser.count(of: item) ?? 0 : 0)
    }

    private var selection: Binding<SidebarItem?> {
        Binding {
            browser.sidebar
        } set: { item in
            if let item { browser.select(item) }
        }
    }
}
