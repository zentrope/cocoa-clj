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

    @IBOutlet var outputView: TerminalTextView!
    @IBOutlet weak var userInputTextField: NSTextField!

    // MARK: - View Controller Overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        Notify.shared.register(receiver: self)
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()
        Notify.shared.unregister(receiver: self)
    }

    override func viewDidAppear() {
        userInputTextField.sizeToFit()
        userInputTextField.display()

        if let win = self.view.window {
            win.makeFirstResponder(userInputTextField)
        }

        Log.info("Welcome")
    }
    
    // MARK: - Action Handlers

    @IBAction func onUserInput(_ sender: NSTextField) {
        let s = sender.stringValue.trimmingCharacters(in: CharacterSet.whitespaces)

        if (s.count > 0) {
            Log.info("Sending form '\(s)' to buffer.")
            sendForEval(expr: sender.stringValue)
        }
        sender.stringValue = ""
    }

    // MARK: - Evaluation

    var lastNs: String = "user"

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

            self.lastNs = summary.ns ?? self.lastNs

            output = output + "\(self.lastNs)> \(expr)\n"

            if let out = summary.output {
                output.append(out.tighten())
            }

            if let err = summary.err {
                output.append(err)
            } else if let val = summary.value {
                output.append(val.tighten())
            }

            self.outputView.paragraph(output)
        }
    }
}

extension MainViewController: SourceDataReceiver {

    func receive(symbolSource: CLJSource, forSymbol sym: CLJSymbol) {
        outputView.clearBuffer()
        outputView.paragraph(symbolSource.source)
        outputView.prompt()
    }

}
