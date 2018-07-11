//
//  ViewController.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/2/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController {

    // MARK: - Outlets

    @IBOutlet var outputView: NSTextView!
    @IBOutlet weak var userInputTextField: NSTextField!


    // MARK: - Instance data

    let paragraphSpacing = CGFloat(13.0 * 1.5)
    let defaultFont = NSFont.userFixedPitchFont(ofSize: 11.0)

    lazy var defaultStyle: NSMutableParagraphStyle = {
        let s = NSMutableParagraphStyle()
        s.paragraphSpacing = paragraphSpacing
        s.lineBreakMode = NSLineBreakMode.byTruncatingTail
        return s
    }()

    // MARK: - View Controller Overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        outputView.defaultParagraphStyle = defaultStyle
        outputView.textContainerInset = NSSize(width: 10.0, height: 10.0)

        Notify.hearAboutSource(self, selector: #selector(self.handleSourceUpdate))
    }

    @objc func handleSourceUpdate(notification: NSNotification) {
        let payload = notification.userInfo
        if let text = payload?["source"] as? CLJSource {
            clearBuffer()
            appendParagraph(text.source.tighten())
        }
    }

    override func viewDidAppear() {
        userInputTextField.sizeToFit()
        userInputTextField.display()

        if let win = self.view.window {
            win.makeFirstResponder(userInputTextField)
        }

        Log.info("Welcome 🙈🙉🙊")
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    // MARK: - Buffer Management

    func appendParagraph(_ line: String) {
        outputView.appendParagraph(line, usingFont: defaultFont, andStyle: defaultStyle)
    }

    func clearBuffer() {
        outputView.clearBuffer()
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
                self.appendParagraph("error : \(e.localizedDescription) - \(site)")
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

            self.appendParagraph(output)
        }
    }
}

