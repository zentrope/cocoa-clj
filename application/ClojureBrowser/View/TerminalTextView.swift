//
//  TerminalTextView.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/12/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Cocoa

protocol TerminalTextViewDelegate {
    func getPrompt() -> NSAttributedString
    func getBanner() -> NSAttributedString
    func invokeCommand(cmd: String, sender: TerminalTextView)
    func styleCommand(cmd: String, sender: TerminalTextView) -> NSAttributedString
}

fileprivate let cursor = "█" // better to fmt a bg color
fileprivate let cursorSize = cursor.count

// MARK: - Main

class TerminalTextView: NSTextView {

    var keyboardEventMonitor: Any? = nil

    var cursorPosition: Int = 0 {
        didSet {
            print("cursor-position: \(cursorPosition)")
        }
    }

    var termDelegate: TerminalTextViewDelegate? {
        didSet {
            if let b = termDelegate?.getBanner() {
                display(b)
            }
        }
    }

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

    override var acceptsFirstResponder: Bool {
        return true
    }

    override func becomeFirstResponder() -> Bool {
        Log.info("Terminal is active.")
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
        Log.info("Terminal is inactive.")
        if let mon = self.keyboardEventMonitor {
            NSEvent.removeMonitor(mon)
        }
        return true
    }

    private func setup() {
        self.textContainerInset = NSSize(width: 10.0, height: 10.0)
        clearBuffer()
    }

}

// MARK: - Keyboard interpreter

extension TerminalTextView {

    private func handleKeyDown(with theEvent: NSEvent) -> KeyEventResult {

        let keyID = KeyID(event: theEvent)

        switch keyID.op() {
        case .enter:
            dispatchInvokeCommand()
        case .right:
            print("right arrow")
        case .left:
            print("left arrow")
        case .home:
            print("home key")
        case .end:
            print("end key")
        case .delete:
            backspace()
        case .clear:
            clearBuffer()
            prompt()
        case .unknown:
            Log.info(keyID.describe())
            return .unhandled
        case .value:
            appendChars(keyID.chs)
            appendCursor()
            dispatchStyleCommand()
        }
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
        cursorPosition = storage.string.count
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

// MARK: - Keyboard interpreter

enum KeyEventResult {
    case handled
    case unhandled
}

enum KeyCodes: Int {
    case kcReturnKey = 36
    case kcLetterK = 40
    case kcDeleteKey = 51
    case kcRightArrow = 124
    case kcLeftArrow = 123

    static func match(_ key: KeyID, _ guess: KeyCodes, _ mods: NSEvent.ModifierFlags = []) -> Bool {
        return key.key == guess.rawValue && key.flags.contains(mods)
    }
}

enum KeyOp {
    case enter
    case right
    case left
    case home
    case end
    case delete
    case clear
    case unknown
    case value
}

class KeyID {

    var flags: NSEvent.ModifierFlags
    var key: Int
    var chs: String

    init(event: NSEvent) {
        chs = event.characters ?? ""
        key = Int(event.keyCode)
        flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
    }

    func op() -> KeyOp {
        if endKey() { return KeyOp.end }
        if homeKey() { return KeyOp.home }
        if deleteKey() { return KeyOp.delete }
        if returnKey() { return KeyOp.enter }
        if clearKey() { return KeyOp.clear }
        if leftKey() { return KeyOp.left }
        if rightKey() { return KeyOp.right }
        if modified() {
            return KeyOp.unknown
        }
        return KeyOp.value
    }

    func describe() -> String {
        var d = [String]()
        if flags.contains(.command) { d.append("COMMAND")}
        if flags.contains(.option) { d.append("OPTION")}
        if flags.contains(.control) { d.append("CONTROL")}
        if flags.contains(.function) { d.append("FUNCTION")}
        d.append(String(key))
        return d.joined(separator: "-")
    }

    private func modified() -> Bool {
        return flags.contains(.command) ||
            flags.contains(.option) ||
            flags.contains(.control) ||
            flags.contains(.function)
    }

    private func endKey() -> Bool {
        return KeyCodes.match(self, .kcRightArrow, [.command, .function])
    }

    private func homeKey() -> Bool {
        return KeyCodes.match(self, .kcLeftArrow, [.command, .function])
    }

    private func rightKey() -> Bool {
        return KeyCodes.match(self, .kcRightArrow, [.function])
    }

    private func leftKey() -> Bool {
        return KeyCodes.match(self, .kcLeftArrow, [.function])
    }

    private func clearKey() -> Bool {
        return KeyCodes.match(self, .kcLetterK, [.command])
    }

    private func returnKey() -> Bool {
        return KeyCodes.match(self, .kcReturnKey)
    }

    private func deleteKey() -> Bool {
        return KeyCodes.match(self, .kcDeleteKey)
    }
}

// MARK: - NSRange extension

extension NSRange {

    var isEmpty : Bool {
        get {
            return self.length == 0
        }
    }
}
