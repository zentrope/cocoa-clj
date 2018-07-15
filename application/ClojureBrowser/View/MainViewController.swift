//
//  MainViewController.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/2/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Cocoa

// MARK: - View Controller Overrides

class MainViewController: NSViewController {

    @IBOutlet var terminal: TerminalTextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        Notify.shared.register(receiver: self)
        self.terminal.termDelegate = self
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

// MARK: - Terminal delegate

extension MainViewController: TerminalTextViewDelegate {

    func getBanner() -> NSAttributedString {
        return Style.apply(";; Hello Clojure Browser\n", style: .banner)
    }

    func getPrompt() -> NSAttributedString {
        return Style.apply("$ ", style: .prompt)
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

extension MainViewController: SourceDataReceiver, EvalDataReceiver {

    func receive(symbolSource src: CLJSource, forSymbol sym: CLJSymbol) {
        terminal.display(Style.apply(src.source, style: .clojure))
    }

    func receive(summary: Summary) {
        terminal.display(Style.apply(result: summary))
    }

}
