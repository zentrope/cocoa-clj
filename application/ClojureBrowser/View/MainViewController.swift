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
    let lineSpacing = CGFloat(4.0)

    lazy var defaultStyle: NSMutableParagraphStyle = {
        let s = NSMutableParagraphStyle()
        s.lineSpacing = lineSpacing
        return s
    }()

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
            terminal.display(pretty(msg, style: .error))
            return
        }

        guard let t = text else { return }

        let packets = Nrepl.decode(t)
        let summary = Summary(packets)

        terminal.display(pretty(result: summary))
    }
}

// MARK: - Formatting concerns

enum Style {
    case banner
    case clojure
    case error
    case output
    case prompt
    case standard
}

extension MainViewController {

    func pretty(result: Summary) -> NSAttributedString {
        let output = NSMutableAttributedString(string: "")

        if let out = result.output {
            output.append(pretty(out, style: .output))
        }
        if let err = result.err {
            output.append(pretty(err, style: .error))
        } else if let val = result.value {
            let trimmed = val.trimmingCharacters(in: .whitespacesAndNewlines)
            output.append(pretty(trimmed, style: .clojure))
        }

        return output
    }

    func pretty(_ string: String, style: Style) -> NSAttributedString {
        let s = NSMutableAttributedString(string: string)
        let r = NSMakeRange(0, s.length)
        s.addAttribute(.paragraphStyle, value: defaultStyle, range: r)
        s.addAttribute(.font, value: defaultFont, range: r)
        s.addAttribute(.backgroundColor, value: NSColor.textBackgroundColor, range: r)

        switch style {
        case .clojure:
            return Syntax.shared.highlight(source: string, withFont: outputFont)
        case .standard:
            s.addAttribute(.foregroundColor, value: NSColor.textColor, range: r)
        case .error:
            s.addAttribute(.foregroundColor, value: NSColor.systemRed, range: r)
        case .output:
            s.addAttribute(.foregroundColor, value: NSColor.systemGray, range: r)
        case .prompt:
            s.addAttribute(.foregroundColor, value: NSColor.systemPurple, range: r)
        case .banner:
            s.addAttribute(.foregroundColor, value: NSColor.systemGray, range: r)
        }
        return s
    }
}

// MARK: - Terminal delegate

extension MainViewController: TerminalTextViewDelegate {

    func getBanner() -> NSAttributedString {
        return pretty(";; Hello Clojure Browser\n", style: .banner)
    }

    func getPrompt() -> NSAttributedString {
        return pretty("$ ", style: .prompt)
    }

    func styleCommand(cmd: String, sender: TerminalTextView) -> NSAttributedString {
        return pretty(cmd, style: .clojure)
    }

    func invokeCommand(cmd: String, sender: TerminalTextView) {
        Log.info("eval this form? '\(cmd)'")
        Net.sendForEval(site: Prefs().replUrl, form: cmd, self.receiveEval)
    }

}

// MARK: - Data receivers

extension MainViewController: SourceDataReceiver {

    func receive(symbolSource src: CLJSource, forSymbol sym: CLJSymbol) {
        terminal.display(pretty(src.source, style: .clojure))
    }

}
