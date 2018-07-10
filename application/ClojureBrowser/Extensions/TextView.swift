//
//  TextViewExtensions.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/7/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Cocoa

extension NSTextView {

    // MARK: - TextView Extensions

    func clearBuffer() {
        if let storage = self.textStorage {
            storage.beginEditing()
            storage.mutableString.setString("")
            storage.endEditing()
        }
    }

    func appendParagraph(_ line: String, usingFont font: NSFont?, andStyle style: NSMutableParagraphStyle) {

        guard let storage = self.textStorage else {
            return
        }

        storage.beginEditing()
        let prefix = storage.string.count > 0 ? "\n" : ""
        storage.mutableString.append(prefix + line)
        storage.font = font
        storage.foregroundColor = NSColor.textColor
        let range = self.attributedString().length

        storage.addAttribute(.paragraphStyle, value: style, range: NSMakeRange(0, range))

        storage.endEditing()

        self.scrollToEndOfDocument(self)
    }
}
