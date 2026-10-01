import AppKit
import SwiftUI

/// Command output as the terminal would show it, kept scrolled to the end
/// while it grows.
///
/// A text view rather than `Text`: a log only grows, and `Text` lays the
/// whole of it out again for every piece added, which on a long upgrade
/// takes longer than the pieces take to arrive.
struct LogView: NSViewRepresentable {

    let text: String

    final class Coordinator {
        /// What the text view holds, to tell new output from a cleared log.
        var shown = ""
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else { return scrollView }
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = false
        textView.textContainerInset = NSSize(width: 6, height: 6)
        textView.backgroundColor = .textBackgroundColor
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView,
              let storage = textView.textStorage else { return }
        let coordinator = context.coordinator
        guard text != coordinator.shown else { return }

        let clipView = scrollView.contentView
        let isAtEnd = clipView.bounds.maxY >= textView.frame.maxY - 1
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: "Andale Mono", size: 12) ?? .monospacedSystemFont(ofSize: 12, weight: .regular),
            .foregroundColor: NSColor.textColor
        ]
        if text.utf8.starts(with: coordinator.shown.utf8) {
            let added = String(text.utf8.dropFirst(coordinator.shown.utf8.count)) ?? ""
            storage.append(NSAttributedString(string: added, attributes: attributes))
        } else {
            storage.setAttributedString(NSAttributedString(string: text, attributes: attributes))
        }
        coordinator.shown = text
        if isAtEnd { textView.scrollToEndOfDocument(nil) }
    }
}
