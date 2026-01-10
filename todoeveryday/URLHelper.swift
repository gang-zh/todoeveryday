//
//  URLHelper.swift
//  todoeveryday
//
//  Created by Gang Zhang on 1/7/26.
//

import Foundation
import SwiftUI
import AppKit

extension String {
    // MARK: - Shared URL Detection

    /// Detects URLs in the string and returns matching ranges
    /// Uses NSDataDetector for reliable URL detection
    private func detectURLRanges() -> [NSTextCheckingResult] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return []
        }
        return detector.matches(in: self, options: [], range: NSRange(location: 0, length: utf16.count))
    }

    // MARK: - SwiftUI AttributedString

    func detectURLs() -> AttributedString {
        var attributedString = AttributedString(self)

        for match in detectURLRanges().reversed() {
            guard let url = match.url else { continue }

            let startIndex = attributedString.index(attributedString.startIndex, offsetByCharacters: match.range.location)
            let endIndex = attributedString.index(startIndex, offsetByCharacters: match.range.length)
            let attributedRange = startIndex..<endIndex

            attributedString[attributedRange].link = url
            attributedString[attributedRange].foregroundColor = .blue
            attributedString[attributedRange].underlineStyle = .single
        }

        return attributedString
    }

    // MARK: - AppKit NSAttributedString

    func toNSAttributedString(isCompleted: Bool, isOverdue: Bool) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: self)

        // Set default text color
        let textColor: NSColor = isCompleted ? .secondaryLabelColor : (isOverdue ? .systemRed : .labelColor)
        attributedString.addAttribute(.foregroundColor, value: textColor, range: NSRange(location: 0, length: attributedString.length))

        // Style detected URLs
        let linkColor: NSColor = isCompleted ? .secondaryLabelColor : .systemBlue
        for match in detectURLRanges() {
            guard let url = match.url else { continue }
            attributedString.addAttribute(.link, value: url, range: match.range)
            attributedString.addAttribute(.foregroundColor, value: linkColor, range: match.range)
            attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: match.range)
            attributedString.addAttribute(.cursor, value: NSCursor.pointingHand, range: match.range)
        }

        return attributedString
    }
}

// Custom TextView that supports clickable links with proper cursor
struct ClickableTextView: NSViewRepresentable {
    let text: String
    let isCompleted: Bool
    let isOverdue: Bool
    let isStrikethrough: Bool
    let onEditTitle: () -> Void
    let onSetDeadline: () -> Void
    let onRemoveDeadline: (() -> Void)?
    let onEditDescription: () -> Void
    let onDelete: () -> Void
    let hasDeadline: Bool

    func makeNSView(context: Context) -> CustomTextView {
        let textView = CustomTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        textView.onEditTitle = onEditTitle
        textView.onSetDeadline = onSetDeadline
        textView.onRemoveDeadline = onRemoveDeadline
        textView.onEditDescription = onEditDescription
        textView.onDelete = onDelete
        textView.hasDeadline = hasDeadline
        return textView
    }

    func updateNSView(_ nsView: CustomTextView, context: Context) {
        let attributedString = text.toNSAttributedString(isCompleted: isCompleted, isOverdue: isOverdue)
        let mutableAttrString = NSMutableAttributedString(attributedString: attributedString)

        if isStrikethrough {
            mutableAttrString.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: mutableAttrString.length))
        }

        nsView.textStorage?.setAttributedString(mutableAttrString)
        nsView.onEditTitle = onEditTitle
        nsView.onSetDeadline = onSetDeadline
        nsView.onRemoveDeadline = onRemoveDeadline
        nsView.onEditDescription = onEditDescription
        nsView.onDelete = onDelete
        nsView.hasDeadline = hasDeadline
    }
}

// Custom NSTextView subclass with context menu support
class CustomTextView: NSTextView {
    var onEditTitle: (() -> Void)?
    var onSetDeadline: (() -> Void)?
    var onRemoveDeadline: (() -> Void)?
    var onEditDescription: (() -> Void)?
    var onDelete: (() -> Void)?
    var hasDeadline: Bool = false

    override func menu(for event: NSEvent) -> NSMenu? {
        let menu = NSMenu()

        let editItem = NSMenuItem(title: "Edit Title", action: #selector(editTitleAction), keyEquivalent: "")
        editItem.image = NSImage(systemSymbolName: "pencil", accessibilityDescription: nil)
        menu.addItem(editItem)

        let descriptionItem = NSMenuItem(title: "Edit Description", action: #selector(editDescriptionAction), keyEquivalent: "")
        descriptionItem.image = NSImage(systemSymbolName: "doc.text", accessibilityDescription: nil)
        menu.addItem(descriptionItem)

        menu.addItem(.separator())

        let deadlineItem = NSMenuItem(
            title: hasDeadline ? "Edit Deadline" : "Set Deadline",
            action: #selector(setDeadlineAction),
            keyEquivalent: ""
        )
        deadlineItem.image = NSImage(systemSymbolName: "calendar", accessibilityDescription: nil)
        menu.addItem(deadlineItem)

        if hasDeadline {
            let removeDeadlineItem = NSMenuItem(title: "Remove Deadline", action: #selector(removeDeadlineAction), keyEquivalent: "")
            removeDeadlineItem.image = NSImage(systemSymbolName: "calendar.badge.minus", accessibilityDescription: nil)
            menu.addItem(removeDeadlineItem)
        }

        menu.addItem(.separator())

        let deleteItem = NSMenuItem(title: "Delete", action: #selector(deleteAction), keyEquivalent: "")
        deleteItem.image = NSImage(systemSymbolName: "trash", accessibilityDescription: nil)
        menu.addItem(deleteItem)

        return menu
    }

    @objc private func editTitleAction() {
        onEditTitle?()
    }

    @objc private func editDescriptionAction() {
        onEditDescription?()
    }

    @objc private func setDeadlineAction() {
        onSetDeadline?()
    }

    @objc private func removeDeadlineAction() {
        onRemoveDeadline?()
    }

    @objc private func deleteAction() {
        onDelete?()
    }
}
