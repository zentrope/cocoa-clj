//
//  TerminalTextView.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/12/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Cocoa

// MARK: - Delegate protocol

protocol TerminalTextViewDelegate {
    func getPrompt() -> NSAttributedString
    func getBanner() -> NSAttributedString
    func invokeCommand(cmd: String, sender: TerminalTextView)
    func styleCommand(cmd: String, sender: TerminalTextView) -> NSAttributedString
}

// MARK: - Main

class TerminalTextView: NSTextView {

    private var history = History()
    private var keyboardEventMonitor: Any? = nil

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

        self.isEditable = true
        self.isAutomaticQuoteSubstitutionEnabled = false
        self.isAutomaticTextCompletionEnabled = false
        self.isAutomaticTextReplacementEnabled = false
        self.isAutomaticDashSubstitutionEnabled = false
        self.smartInsertDeleteEnabled = false

        self.delegate = self
        self.textContainerInset = NSSize(width: 10.0, height: 10.0)

        NSPasteboard.general.declareTypes([.string], owner: self)
    }

    override var acceptsFirstResponder: Bool {
        return true
    }

    override func becomeFirstResponder() -> Bool {
        if (textStorage?.length ?? 0) < 1 {
            prompt()
        }
        self.keyboardEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            return self.handleKeyDown(with: $0) ? nil : $0
        }
        self.updateInsertionPointStateAndRestartTimer(true)
        return true
    }

    override func resignFirstResponder() -> Bool {
        if let mon = self.keyboardEventMonitor {
            NSEvent.removeMonitor(mon)
        }
        return true
    }

    private func handleKeyDown(with theEvent: NSEvent) -> Bool {

        let kcReturnKey  =  36
        let kcDelete =      51
        let kcDownArrow  = 125
        let kcUpArrow    = 126

        let key = Int(theEvent.keyCode)
        let flags = theEvent.modifierFlags.intersection([.function])

        if flags.isEmpty && key == kcReturnKey {
            history.set(getCommandText() ?? "")
            history.new("")
            dispatchInvokeCommand()
            return true
        }

        if flags.isEmpty && key == kcDelete {
            // Don't allow the user to backspace over the prompt.
            return selectedRange().length == 0 && ((selectedRange().location - 1) < cmdRange().location)
        }

        if flags == [.function] && key == kcDownArrow {
            Log.warn("History not implemented.")
        }

        if flags == [.function] && key == kcUpArrow {
            Log.warn("History not implemented.")
        }

        return false
    }

    private func forwardHistory() {
        if let newCmd = history.getNext() {
            print(newCmd)
            replaceCommand(newCmd)
        }
    }

    private func backwardHistory() {
        if let newCmd = history.getPrev() {
            replaceCommand(newCmd)
        }
    }

    private func prompt() {
        guard let storage = self.textStorage else { return }
        storage.append(NSAttributedString(string: "\n"))
        storage.append(dispatchGetPrompt())
        dispatchStyleCommand()
        setSelectedRange(NSMakeRange(storage.length - 1, 0))
        scrollToEndOfDocument(self)
    }

    private func newline(count: Int = 1) {
        guard let storage = self.textStorage else { return }
        let lineEndings = String(repeating: "\n", count: count)
        storage.append(NSAttributedString(string: lineEndings))
    }

    private func replaceCommand(_ cmd: String) {
        guard let storage = self.textStorage else { return }
        let cmdRange = self.cmdRange()
        storage.replaceCharacters(in: cmdRange, with: cmd.trimmingCharacters(in: .whitespacesAndNewlines))
        dispatchStyleCommand()
    }

    private func getCommandText() -> String? {
        guard let data = textStorage?.string else { return nil }
        let prompt = dispatchGetPrompt().string
        if let range = data.range(of: prompt, options: .backwards, range: nil, locale: nil) {
            return String(data[range.upperBound..<data.endIndex])
        }
        return nil
    }

    private func cmdRange() -> NSRange {

        let empty = NSMakeRange(0, 0)
        guard let storage = self.textStorage else { return empty }
        let data = storage.string
        let prompt = dispatchGetPrompt().string

        guard let guess = data.range(of: prompt, options: .backwards, range: nil, locale: nil) else {
            return empty
        }

        let length = data.distance(from: guess.upperBound, to: data.endIndex)
        let location = guess.upperBound.encodedOffset

        return NSMakeRange(location, length)
    }

    func display(_ output: NSAttributedString) {
        newline()
        if (output.length > 0) {
            newline()
            textStorage?.append(output)
            newline()
        }
        prompt()
    }
}

// MARK: - Delegate dispatch commands

extension TerminalTextView {

    private func dispatchInvokeCommand() {
        guard let delegate = self.termDelegate else { return }

        if let cmd = getCommandText() {
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
        guard let cmd = getCommandText() else { return }
        let cmdRange = self.cmdRange()
        let s = delegate.styleCommand(cmd: cmd, sender: self)
        preservingCursor {
            storage.replaceCharacters(in: cmdRange, with: s)
        }
    }

    private func preservingCursor(_ closure: () -> ()) {
        let cursor = selectedRange()
        closure()
        setSelectedRange(cursor)
    }

    private func dispatchGetPrompt() -> NSAttributedString {
        return termDelegate?.getPrompt() ?? NSAttributedString(string: "$ ")
    }
}

// MARK: - TextView delegate

extension TerminalTextView: NSTextViewDelegate {

    func textDidChange(_ notification: Notification) {
        dispatchStyleCommand()
    }

    func textView(_ textView: NSTextView, willChangeSelectionFromCharacterRange oldSelectedCharRange: NSRange, toCharacterRange newSelectedCharRange: NSRange) -> NSRange {

        let command = cmdRange()

        if newSelectedCharRange.length == 0 {
            if newSelectedCharRange.location < command.location {
                return NSMakeRange(command.location, 0)
            }
            return newSelectedCharRange
        }

        let intersection = NSIntersectionRange(command, newSelectedCharRange)
        if intersection.length > 0 {
            return intersection
        } else {
            return newSelectedCharRange
        }
    }
}
