//
//  TerminalTextView.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/12/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Cocoa

enum KeyCodes: Int {
    case kcReturnKey = 36
    case kcDeleteKey = 51
}

enum Handled {
    case handled
    case unhandled
}

class TerminalTextView: NSTextView {

    let paragraphSpacing = CGFloat(13.0 * 1.5)
    let defaultFont = NSFont.userFixedPitchFont(ofSize: 11.0)

    lazy var defaultStyle: NSMutableParagraphStyle = {
        let s = NSMutableParagraphStyle()
        s.paragraphSpacing = paragraphSpacing
        s.lineBreakMode = NSLineBreakMode.byTruncatingTail
        return s
    }()

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }


    override init(frame: NSRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
    }

    override init(frame: NSRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

//    override var acceptsFirstResponder: Bool {
//        return true
//    }
//
//    override func becomeFirstResponder() -> Bool {
//        return true
//    }
//
//    override func resignFirstResponder() -> Bool {
//        return true
//    }

    // MARK: - Interaction management

    func setup() {
        print("set up")

        self.defaultParagraphStyle = defaultStyle
        self.textContainerInset = NSSize(width: 10.0, height: 10.0)

//        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
//            // This takes over for the entire window. None of the other widgets
//            // will get any keyboard input.
//            return self.handleKeyDown(with: $0) == .handled ? nil : $0
//        }

        self.append("\n$ ")
        self.appendCursor()
    }

    func handleKeyDown(with theEvent: NSEvent) -> Handled {
//        guard let locWindow = self.view.window,
//            NSApplication.shared.keyWindow === locWindow else { return }

        let chs = theEvent.characters ?? ""
        let key = Int(theEvent.keyCode)
        let flags = theEvent.modifierFlags.intersection(.deviceIndependentFlagsMask)

        if flags.contains(.command) { print("COMMAND") }
        if flags.contains(.option) { print( "OPTION") }
        if flags.contains(.control) { print( "CONTROL") }
        if flags.contains(.function) { print( "FUNCTION") }

        if flags.isSuperset(of: [.shift]) {
            print("SHIFT")
        }

        if let code = KeyCodes(rawValue: key) {
            switch code {
            case .kcReturnKey:
                self.append("\n$ ")
                self.appendCursor()
            case .kcDeleteKey:
                self.backspace()
            }
            return .handled
        }

        self.append(chs)
        self.appendCursor()
        return .handled
    }

    // MARK: - Buffer management
    
    func clearBuffer() {
        if let storage = self.textStorage {
            storage.beginEditing()
            storage.mutableString.setString("")
            storage.endEditing()
        }
    }

    func paragraph(_ line: String) {

        guard let storage = self.textStorage else { return }

        storage.beginEditing()
        let prefix = storage.string.count > 0 ? "\n" : ""
        storage.mutableString.append(prefix + line)
        storage.font = defaultFont
        storage.foregroundColor = NSColor.textColor
        let range = self.attributedString().length

        storage.addAttribute(.paragraphStyle, value: defaultStyle, range: NSMakeRange(0, range))

        storage.endEditing()

        self.scrollToEndOfDocument(self)
    }

    // MARK: - Terminal functions

    func lastChar(_ string: NSMutableString) -> NSRange {
        //guard let storage = self.textStorage else { return NSMakeRange(0, 0) }
        let len = string.length
        return NSMakeRange(len - cursorSize, cursorSize)
    }

    func appendCursor() {
        guard let storage = self.textStorage else { return }
        storage.beginEditing()
        storage.mutableString.append(cursor)
        let range = lastChar(storage.mutableString)
        storage.addAttribute(.foregroundColor, value: NSColor.systemOrange, range: range)
        storage.endEditing()
        self.scrollToEndOfDocument(self)
    }

    func removeCursor() {
        if self.attributedString().length < cursorSize { return }
        guard let storage = self.textStorage else { return }
        storage.beginEditing()
        if attributedString().endsWithCursor() {
            storage.mutableString.deleteCharacters(in: lastChar(storage.mutableString))
        }
        storage.endEditing()
        self.scrollToEndOfDocument(self)
    }

    func backspace() {
        removeCursor()

        if self.attributedString().length < 1 { return }

        guard let storage = self.textStorage else { return }
        storage.beginEditing()
        storage.mutableString.deleteCharacters(in: lastChar(storage.mutableString))
        storage.endEditing()

        appendCursor()
        self.scrollToEndOfDocument(self)
    }

    func append(_ char: String) {
        guard let storage = self.textStorage else { return }

        storage.beginEditing()
        storage.font = defaultFont
        storage.foregroundColor = NSColor.textColor

        if attributedString().endsWithCursor() {
            storage.mutableString.deleteCharacters(in: lastChar(storage.mutableString))
        }

        storage.mutableString.append(char)
        let range = self.attributedString().length
        storage.addAttribute(.paragraphStyle, value: defaultStyle, range: NSMakeRange(0, range))


        storage.endEditing()

        self.scrollToEndOfDocument(self)
    }

    func prompt() {
        append("\n$ ")
        appendCursor()
    }
}

// Cursor should be a block of color, not an actual
// character appended to the buffer. Then we can track
// where it is, insert characters in the right place,
// and so on.

let cursor = "█"
let cursorSize = cursor.count

extension NSAttributedString {

    func endsWithCursor() -> Bool {
        return string.hasSuffix(cursor)
    }

}
