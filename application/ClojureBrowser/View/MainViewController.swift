//
//  MainViewController.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/2/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController {

    // MARK: - Outlets

    @IBOutlet var terminal: TerminalTextView!

    // MARK: - View Controller Overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        Notify.shared.register(receiver: self)
        self.terminal.termDelegate = self
        Log.info("Welcome")

        if let w = self.view.window {
            w.makeFirstResponder(terminal)
        } else {
            Log.info("Unable to make the terminal the first responder.")
        }
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()
        Notify.shared.unregister(receiver: self)
    }

    // MARK: - Evaluation

    func receiveEval(_ error: Error?, _ text: String?) {
        if let e = error {
            let msg = "error : \(e.localizedDescription) - \(Prefs().replUrl)"
            terminal.display(Style.apply(msg, style: .error))
            return
        }

        guard let t = text else { return }

        let packets = Nrepl.decode(t)
        let summary = Summary(packets)

        terminal.display(Style.apply(result: summary))
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
        Log.info("eval this form? '\(cmd)'")
        Net.sendForEval(site: Prefs().replUrl, form: cmd, self.receiveEval)
    }

}

// MARK: - Data receivers

extension MainViewController: SourceDataReceiver {

    func receive(symbolSource src: CLJSource, forSymbol sym: CLJSymbol) {
        terminal.display(Style.apply(src.source, style: .clojure))
    }

}
