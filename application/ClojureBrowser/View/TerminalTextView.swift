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

// MARK: - Main

class TerminalTextView: NSTextView {

    var keyboardEventMonitor: Any? = nil

    var cursorPosition: Int = 0 {
        willSet { cursorOff() }
        didSet { cursorOn() }
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

        self.delegate = self
        let clipboard = NSPasteboard.general
        clipboard.declareTypes([.string], owner: self)

        self.textContainerInset = NSSize(width: 10.0, height: 10.0)
        clear()
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
}

// MARK: - Keyboard readline-ish

extension TerminalTextView {

    private func handleKeyDown(with theEvent: NSEvent) -> KeyEventResult {

        let keyEvent = KeyEvent(event: theEvent)

        switch keyEvent.op() {

        case .enter:    enter()
        case .right:    forwardChar()
        case .left:     backwardChar()
        case .home:     beginningOfLine()
        case .end:      endOfLine()
        case .delete:   backspace()
        case .clear:    clear(); prompt()
        case .killLine: killLine()
        case .value:    insert(keyEvent.chs); dispatchStyleCommand()
        case .cut:      cutRegion()
        case .copy:     copyRegion()
        case .paste:    pasteRegion()

        case .up:       Log.info("Back history not implemented.")
        case .down:     Log.info("Forward history not implemented.")


        case .unknown: Log.info(keyEvent.describe()); return .unhandled

        }
        unselect()

        return .handled
    }

    private enum CursorToggle {
        case on, off
    }

    private func toggleCursor(_ status: CursorToggle) {
        let range = cmdRange()
        guard let storage = textStorage else { return }

        if range.location == 0 { return }
        let cursorRange = NSMakeRange(range.location + cursorPosition, 1)
        if (cursorRange.location >= storage.length) { return }

        // Use attributes (instead of selection) to avoid disappearing
        // the cursor if the user selects something in the buffer.

        switch status {

        case .on:
            storage.addAttribute(.backgroundColor, value: NSColor.selectedTextBackgroundColor, range: cursorRange)

        case .off:
            storage.addAttribute(.backgroundColor, value: NSColor.textBackgroundColor, range: cursorRange)
        }
    }

    private func cursorOn() {
        toggleCursor(.on)
    }

    private func cursorOff() {
        toggleCursor(.off)
    }

    private func enter() {
        cursorOff()
        dispatchInvokeCommand()
    }

    private func beginningOfLine() {
        cursorPosition = 0
    }

    private func endOfLine() {
        if let line = lastLine() {
            cursorPosition = line.count - 1
        }
    }

    private func backwardChar() {
        if !atBeginningOfLine() {
            cursorPosition -= 1
        }
    }

    private func forwardChar() {
        if !atEndOfLine() {
            cursorPosition += 1
        }
    }

    private func backspace() {
        if isEmpty() {
            return
        }

        if isSelected() {
            deleteRegion()
            return
        }

        if atBeginningOfLine() {
            return
        }

        let place = NSMakeRange(cmdRange().location + cursorPosition - 1, 1)
        setSelectedRange(place)
        deleteRegion()
    }

    private func deleteRegion() {
        let region = rangeOfSelectionInCmd()
        if region.location == NSNotFound { return }
        guard let storage = textStorage else { return }
        storage.mutableString.deleteCharacters(in: region)
    }

    private func cutRegion() {

        let selection = rangeOfSelectionInCmd()
        if selection.location == NSNotFound || selection.length == 0 { return }

        let active = cmdRange()

        if selection.location < active.location { return }
        guard let storage = textStorage else { return }

        cursorOff()
        let text = storage.mutableString.substring(with: selection)
        let clipboard = NSPasteboard.general
        clipboard.setString(text, forType: .string)

        deleteRegion()
        unselect()
    }

    private func copyRegion() {
        let range = super.selectedRange()
        if range.location == NSNotFound || range.length == 0 { return }
        guard let storage = textStorage else { return }

        let text = storage.mutableString.substring(with: range)
        let clipboard = NSPasteboard.general
        clipboard.setString(text, forType: .string)
    }

    private func pasteRegion() {
        let cb = NSPasteboard.general
        if let text = cb.string(forType: .string) {
            insert(text.trimmingCharacters(in: .whitespacesAndNewlines))
            dispatchStyleCommand()
        }
    }

    private func insert(_ chars: String) {
        if isSelected() {
            deleteRegion()
        }
        let range = cmdRange()
        guard let storage = self.textStorage else { return }
        storage.insert(NSAttributedString(string: chars), at: range.location + cursorPosition)
        cursorPosition = cursorPosition + chars.count
    }

    private func clear() {
        guard let storage = self.textStorage else { return }
        storage.mutableString.setString("")
        cursorPosition = 0
    }

    /// Kill from the current postion to the end of the line
    private func killLine() {
        if isEmpty() { return }
        let region = NSMakeRange(bufferPoint(), bufferSize() - bufferPoint() - 1)
        setSelectedRange(region)
        deleteRegion()
    }

    private func bufferPoint() -> Int {
        return cmdRange().location + cursorPosition
    }

    private func bufferSize() -> Int {
        return self.textStorage?.length ?? 0
    }

    private func prompt() {
        guard let storage = self.textStorage else { return }
        storage.append(NSAttributedString(string: "\n"))
        storage.append(dispatchGetPrompt())
        storage.append(NSAttributedString(string: " "))
        cursorPosition = 0
        dispatchStyleCommand()
        super.scrollToEndOfDocument(self)
    }

    private func newline(count: Int = 1) {
        guard let storage = self.textStorage else { return }
        let lineEndings = String(repeating: "\n", count: count)
        storage.append(NSAttributedString(string: lineEndings))
    }

    private func unselect() {
        super.setSelectedRange(NSMakeRange(0, 0))
    }

    private func isSelected() -> Bool {
        let selection = self.selectedRange()
        return selection.location != NSNotFound && selection.length != 0
    }

    private func isSelectedInCommand() -> Bool {
        return rangeOfSelectionInCmd().location != NSNotFound
    }

    private func rangeOfSelectionInCmd() -> NSRange {
        let notFound = NSMakeRange(NSNotFound, 0)
        let selection = self.selectedRange()
        if selection.location == NSNotFound || selection.length == 0 { return notFound }

        let active = cmdRange()

        if selection.location < active.location { return notFound }
        return selection
    }

    private func atBeginningOfLine() -> Bool {
        return cursorPosition == 0
    }

    private func atEndOfLine() -> Bool {
        let max = lastLine()?.count ?? 0
        return cursorPosition >= (max - 1)
    }

    private func isEmpty() -> Bool {
        return cmdRange().location == 0
    }

    private func cmdRange() -> NSRange {
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
                return NSMakeRange(match.range.location + promptSize, match.range.length - promptSize)
            } else {
                return empty
            }
        }

        catch {
            print(error)
            return empty
        }
    }

    private func lastLine() -> String? {
        guard let storage = self.textStorage else { return nil }
        let range = cmdRange()
        if range.length == 0 {
            return nil
        }
        return storage.mutableString.substring(with: range)
    }
}

// MARK: - Public API

extension TerminalTextView {

    /// Output the string to the buffer (as if the result of
    /// the previous command).
    ///
    /// - Parameters:
    ///     - output: The syntax highlighted string to display
    ///
    func display(_ output: NSAttributedString) {
        guard let storage = self.textStorage else { return }
        cursorOff()
        newline()
        if (output.length > 0) {
            newline()
            storage.append(output)
            newline()
        }
        prompt()
    }

}

// MARK: - Delegate dispatch commands

extension TerminalTextView {

    private func dispatchInvokeCommand() {
        guard let delegate = self.termDelegate else { return }

        if let cmd = lastLine() {
            let form = cmd.trimmingCharacters(in: .whitespacesAndNewlines)
            if !form.isEmpty {
                delegate.invokeCommand(cmd: form, sender: self)
                return
            }
        }
        prompt()
    }

    private func dispatchStyleCommand() {
        guard let delegate = self.termDelegate else { return }
        guard let storage = self.textStorage else { return }
        guard let cmd = lastLine() else { return }
        let cmdRange = self.cmdRange()
        let s = delegate.styleCommand(cmd: cmd, sender: self)
        storage.replaceCharacters(in: cmdRange, with: s)
        cursorOn()
    }

    private func dispatchGetPrompt() -> NSAttributedString {
        guard let delegate = self.termDelegate else { return NSAttributedString(string: "$ ")}
        return delegate.getPrompt()
    }
}

// MARK: - TextView delegate

extension TerminalTextView: NSTextViewDelegate {

    func textView(_ textView: NSTextView,
                  willChangeSelectionFromCharacterRange oldSelectedCharRange: NSRange,
                  toCharacterRange newSelectedCharRange: NSRange) -> NSRange {

        // Make sure the cursor position is always at the
        // beginning of the selected range if that range
        // is part of the command being edited.

        guard let term = textView as? TerminalTextView else {
            return newSelectedCharRange
        }

        if !term.isSelectedInCommand()  {
            return newSelectedCharRange
        }

        let selection = term.rangeOfSelectionInCmd()

        let active = term.cmdRange()

        if selection.location < active.location {
            return newSelectedCharRange
        }

        term.cursorPosition = selection.location - active.location
        return newSelectedCharRange

    }
}
