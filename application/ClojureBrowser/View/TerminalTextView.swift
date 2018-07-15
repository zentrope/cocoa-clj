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

protocol TerminalTextViewDelegate {
    func getPrompt() -> NSAttributedString
    func getBanner() -> NSAttributedString
    func invokeCommand(cmd: String, sender: TerminalTextView)
    func styleCommand(cmd: String, sender: TerminalTextView) -> NSAttributedString
}

fileprivate let cursor = "█" // better to fmt a bg color
fileprivate let cursorSize = cursor.count
fileprivate let lineSpacing = CGFloat(4.0)

class TerminalTextView: NSTextView {

    // MARK: - Instance data

    var termDelegate: TerminalTextViewDelegate? {
        didSet {
            if let b = termDelegate?.getBanner() {
                display(b)
            }
        }
    }

    lazy var defaultStyle: NSMutableParagraphStyle = {
        let s = NSMutableParagraphStyle()
        s.lineSpacing = lineSpacing
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
        if let storage = textStorage {
            if storage.length < 1 {
                prompt()
            }
        }
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
        Log.info("set up")

        self.defaultParagraphStyle = defaultStyle
        self.textContainerInset = NSSize(width: 10.0, height: 10.0)

        clearBuffer()


//        clearBuffer()
//        prompt()
    }

    private func handleKeyDown(with theEvent: NSEvent) -> Handled {

        let chs = theEvent.characters ?? ""
        let key = Int(theEvent.keyCode)
        let flags = theEvent.modifierFlags.intersection(.deviceIndependentFlagsMask)

        // This is how you figure out what's what
        if flags.contains(.command) { Log.info("COMMAND \(key)") }
        if flags.contains(.option) { Log.info( "OPTION \(key)") }
        if flags.contains(.control) { Log.info( "CONTROL \(key)") }
        if flags.contains(.function) { Log.info( "FUNCTION \(key)") }

        let modified = flags.contains(.command) || flags.contains(.option) ||
            flags.contains(.control) || flags.contains(.function)

        // Command-K clears the buffer
        if flags.contains(.command) && (key == 40) {
            clearBuffer()
            prompt()
            return .handled
        }

        // If we're not using a modified key, return it to
        // the system so ⌘Q, ⌘, (and so on) works.
        if modified {
            return .unhandled
        }

        if let code = KeyCodes(rawValue: key) {
            switch code {
            case .kcReturnKey:
                dispatchInvokeCommand()
            case .kcDeleteKey:
                self.backspace()
            }
            return .handled
        }

        self.appendChars(chs)
        self.appendCursor()
        dispatchStyleCommand()
        return .handled
    }

}

// MARK: - Delegate dispatch commands

extension TerminalTextView {

    func dispatchInvokeCommand() {
        guard let delegate = self.termDelegate else { return }

        if let form = lastLine() {
            delegate.invokeCommand(cmd: form, sender: self)
            return
        }
        self.prompt()
    }

    func dispatchStyleCommand() {
        guard let delegate = self.termDelegate else { return }
        guard let storage = self.textStorage else { return }
        guard let cmd = lastLine() else { return }
        let cmdRange = self.cmdRange()

        let s = delegate.styleCommand(cmd: cmd, sender: self)
        storage.replaceCharacters(in: cmdRange, with: s)
    }

    func dispatchGetPrompt() -> NSAttributedString {
        guard let delegate = self.termDelegate else { return NSAttributedString(string: "$ ")}
        return delegate.getPrompt()
    }
}

// MARK: - Buffer management

extension TerminalTextView {

    func clearBuffer() {
        guard let storage = self.textStorage else { return }
        storage.beginEditing()
        storage.mutableString.setString("")
        storage.endEditing()
    }

    func display(_ output: NSAttributedString) {
        guard let storage = self.textStorage else { return }

        newline(number: 2)
        removeCursor()

        storage.beginEditing()
        storage.append(output)
        storage.endEditing()

        newline()
        prompt()
    }

    // MARK: - Terminal functions

    func lastChar(_ string: NSMutableString) -> NSRange {
        let len = string.length
        return NSMakeRange(len - cursorSize, cursorSize)
    }

    func appendCursor() {
        guard let storage = self.textStorage else { return }

        // optimization: create the cursor once
        let c = NSMutableAttributedString(string: cursor)
        c.addAttribute(.foregroundColor, value: NSColor.systemOrange, range: NSMakeRange(0, c.length))

        storage.beginEditing()
        storage.append(c)
        storage.endEditing()
        self.scrollToEndOfDocument(self)
    }

    func removeCursor() {
        if self.attributedString().length < cursorSize { return }
        guard let storage = self.textStorage else { return }


        storage.beginEditing()

        if attributedString().string.hasSuffix(cursor) {
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

    func appendChars(_ char: String) {
        guard let storage = self.textStorage else { return }

        storage.beginEditing()
        if attributedString().string.hasSuffix(cursor) {
            storage.mutableString.deleteCharacters(in: lastChar(storage.mutableString))
        }
        storage.mutableString.append(char)
        storage.endEditing()

        self.scrollToEndOfDocument(self)
    }

    func newline(number: Int = 1) {
        removeCursor()
        appendChars(String(repeating: "\n", count: number))
        appendCursor()
    }

    func prompt() {
        guard let storage = self.textStorage else { return }

        removeCursor()
        storage.beginEditing()
        storage.append(NSAttributedString(string: "\n"))
        storage.append(dispatchGetPrompt())
        storage.endEditing()
        appendCursor()
    }

    func cmdRange() -> NSRange {
        let empty = NSMakeRange(0, 0)
        guard let storage = self.textStorage else { return empty }
        let data = storage.string
        let range = NSMakeRange(0, data.count)
        let cmdRangePattern = "(?<=[\n]).*?\\z"

        // What if there's no prompt on the last line? Hm.
        let promptSize = dispatchGetPrompt().length

        do {
            let regex = try NSRegularExpression(pattern: cmdRangePattern, options: [])
            if let match = regex.firstMatch(in: data, options: [], range: range) {
                return NSMakeRange(match.range.location + promptSize, match.range.length - promptSize - cursorSize)
            } else {
                return empty
            }
        }

        catch {
            print(error)
            return empty
        }
    }

    func lastLine() -> String? {
        guard let storage = self.textStorage else { return nil }
        let range = cmdRange()
        if range.isEmpty {
            return nil
        }
        return storage.mutableString.substring(with: range)
    }
}

extension NSRange {

    var isEmpty : Bool {
        get {
            return self.length == 0
        }
    }
}
