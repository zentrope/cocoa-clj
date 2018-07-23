//
//  MainViewController.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/2/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Cocoa

// MARK: - Main

class MainViewController: NSViewController {

    @IBOutlet var terminal: TerminalTextView!

    var currentNamespace = "user"

    override func viewDidLoad() {
        super.viewDidLoad()

        Notify.shared.register(receiver: self)
        terminal.termDelegate = self
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        if let w = self.view.window {
            w.makeFirstResponder(terminal)
        }
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        Notify.shared.unregister(receiver: self)
    }
}

// MARK: - TerminalTextView delegate

extension MainViewController: TerminalTextViewDelegate {

    func getBanner() -> NSAttributedString {
        return Style.apply(";;\n;; Hello Clojure Browser\n;;\n", style: .banner)
    }

    func getPrompt() -> NSAttributedString {
        let ns = Style.apply(currentNamespace, style: .namespace)
        let pointer = Style.apply(" > ", style: .prompt)
        let prompt = NSMutableAttributedString(attributedString: ns)
        prompt.append(pointer)
        return prompt
    }

    func styleCommand(cmd: String, sender: TerminalTextView) -> NSAttributedString {
        return Style.apply(cmd, style: .clojure)
    }

    func invokeCommand(cmd: String, sender: TerminalTextView) {
        Log.info("eval this form? `\(cmd)`")
        Net.sendForEval(site: Prefs().replUrl, form: cmd)
    }

}

// MARK: - Data delegates

extension MainViewController: SourceDataReceiver, EvalDataReceiver, ErrorDataReceiver, SidebarCommandReceiver {

    private func focusOnTerminal() {
        if let w = self.view.window {
            w.makeFirstResponder(terminal)
        }
    }

    func receive(symbolSource src: CLJSource, forSymbol sym: CLJSymbol) {
        terminal.command(Style.apply("(clojure.repl/source-fn '\(sym.ns)/\(sym.name))", style: .clojure))
        terminal.display(Style.apply(src.source, style: .clojure))
        focusOnTerminal()
    }

    func receive(response: ReplResponse) {
        currentNamespace = response.ns ?? currentNamespace
        terminal.display(Style.apply(result: response))
    }

    func receive(error err: Error) {
        let msg = Style.apply(err.localizedDescription, style: .error)
        terminal.display(msg)
    }

    func receive(command: SidebarCommand) {
        switch command {
        case .changeNamespace(let ns):
            let form = "(in-ns '\(ns.name))"
            terminal.command(Style.apply(form, style: .clojure))
            invokeCommand(cmd: form, sender: terminal)
            focusOnTerminal()
        }
    }
}
