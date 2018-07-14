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

    // MARK: - Instance data

    let lineSpacing = CGFloat(4.0)
    let defaultFont = NSFont.userFixedPitchFont(ofSize: 12.0)

    lazy var defaultStyle: NSMutableParagraphStyle = {
        let s = NSMutableParagraphStyle()
        s.lineSpacing = lineSpacing
        s.lineBreakMode = NSLineBreakMode.byTruncatingTail
        return s
    }()

    // MARK: - Superclass override

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
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


    // MARK: - Interaction management

    var keyboardEventMonitor: Any? = nil

    override var acceptsFirstResponder: Bool {
        return true
    }

    override func becomeFirstResponder() -> Bool {
        Log.info("terminal is becoming first responder")
        //clearBuffer()
        prompt()
        self.keyboardEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            return self.handleKeyDown(with: $0) == .handled ? nil : $0
        }
        return true
    }

    override func resignFirstResponder() -> Bool {
        Log.info("terminal is resigning first responder")
        if let mon = self.keyboardEventMonitor {
            NSEvent.removeMonitor(mon)
        }
        return true
    }

    private func setup() {
        print("set up")

        self.defaultParagraphStyle = defaultStyle
        self.textContainerInset = NSSize(width: 10.0, height: 10.0)

        if let s = self.textStorage {
            s.font = defaultFont
        }
        self.clearBuffer()
        self.prompt()
    }

    private func handleKeyDown(with theEvent: NSEvent) -> Handled {

        let chs = theEvent.characters ?? ""
        let key = Int(theEvent.keyCode)
        let flags = theEvent.modifierFlags.intersection(.deviceIndependentFlagsMask)

        if flags.contains(.command) { Log.info("COMMAND \(key)") }
        if flags.contains(.option) { Log.info( "OPTION \(key)") }
        if flags.contains(.control) { Log.info( "CONTROL \(key)") }
        if flags.contains(.function) { Log.info( "FUNCTION \(key)") }

        let modified = flags.contains(.command) || flags.contains(.option) ||
            flags.contains(.control) || flags.contains(.function)

        if flags.contains(.control) && (key == 8) {
            clearBuffer()
            prompt()
            return .handled
        }

        if modified {
            return .unhandled
        }

        if let code = KeyCodes(rawValue: key) {
            switch code {
            case .kcReturnKey:
                self.prompt()
            case .kcDeleteKey:
                self.backspace()
            }
            return .handled
        }

        self.append(chs)
        self.appendCursor()
        return .handled
    }

}

extension TerminalTextView {
    // MARK: - Buffer management
    
    func clearBuffer() {
        if let storage = self.textStorage {
            storage.beginEditing()
            storage.mutableString.setString("")
            storage.endEditing()
        }
    }

    func paragraph(_ line: String) {

        let source = NSMutableAttributedString(string: line)
        Syntax.shared.highlight(source: source, withFont: defaultFont!)
        source.addAttribute(.paragraphStyle, value: defaultStyle, range: NSMakeRange(0, source.length))

        guard let storage = self.textStorage else { return }

        storage.beginEditing()
        storage.append(source)
        storage.endEditing()

        self.scrollToEndOfDocument(self)
    }

    // MARK: - Terminal functions

    func lastChar(_ string: NSMutableString) -> NSRange {
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
        if attributedString().endsWithCursor() {
            storage.mutableString.deleteCharacters(in: lastChar(storage.mutableString))
        }
        storage.mutableString.append(char)
        storage.endEditing()

        self.scrollToEndOfDocument(self)
    }

    func prompt() {
        removeCursor()
        append("\n\n$ ")
        appendCursor()
    }
}

// Cursor should be a block of color, not an actual
// character appended to the buffer. Then we can track
// where it is, insert characters in the right place,
// and so on.

// Better yet, place the actual cursor for the view,
// if that's possible for an edit=false NSTextView
let cursor = "█"
let cursorSize = cursor.count

extension NSAttributedString {

    func endsWithCursor() -> Bool {
        return string.hasSuffix(cursor)
    }

}