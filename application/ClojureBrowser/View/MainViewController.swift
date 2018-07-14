//
//  MainViewController.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/2/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController {

    // MARK: - Instance data

    let defaultFont = NSFont.userFixedPitchFont(ofSize: 13.0)!
    let outputFont = NSFont.userFixedPitchFont(ofSize: 13.0)!

    // MARK: - Outlets

    @IBOutlet var outputView: TerminalTextView!

    // MARK: - View Controller Overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        Notify.shared.register(receiver: self)
        self.outputView.termDelegate = self
        Log.info("Welcome")
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()
        Notify.shared.unregister(receiver: self)
    }

    // MARK: - Evaluation

    func sendForEval(expr: String) {
        let prefs = Prefs()
        let site = prefs.replUrl

        Net.sendForEval(site: site, form: expr) { error, text in
            if let e = error {
                self.outputView.paragraph("error : \(e.localizedDescription) - \(site)")
                return
            }

            guard let t = text else {
                Log.error("no text available for \(site)")
                return
            }

            let packets = Nrepl.decode(t)
            let summary = Summary(packets)


            var output = "";

            if let out = summary.output {
                output.append(out)
            }

            if let err = summary.err {
                output.append(err)
            } else if let val = summary.value {
                output.append(val)
            }

            output = "\n\n" + output.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

            //print("out '\(output)'")
            // TODO: outputview.showCommandOutput(output)
            self.outputView.removeCursor()
            self.outputView.paragraph(output)
            self.outputView.newLine()
            self.outputView.prompt()
        }
    }
}

// MARK: - Terminal View Delegate

extension MainViewController: TerminalTextViewDelegate {

    func getPrompt() -> NSAttributedString {
        return NSAttributedString(string: "$ ")
    }

    func styleCommand(cmd: NSMutableAttributedString, range: NSRange, sender: TerminalTextView) {
        Syntax.shared.highlight(source: cmd, withFont: defaultFont, inRange: range)
    }

    func invokeCommand(cmd: String, sender: TerminalTextView) {
        Log.info("eval this form? '\(cmd)'")
        self.sendForEval(expr: cmd)
    }

}

// MARK: - Data receivers

extension MainViewController: SourceDataReceiver {


    func receive(symbolSource: CLJSource, forSymbol sym: CLJSymbol) {
        // TODO: outputview.showCommandOutput(output)
        outputView.removeCursor()
        outputView.paragraph(symbolSource.source)
        outputView.newLine()
        outputView.prompt()
    }

}
