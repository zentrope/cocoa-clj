//
//  PrefsViewController.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/7/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Cocoa

class PrefsViewController: NSViewController {

    // MARK: - outlets

    @IBOutlet weak var schemaPopup: NSPopUpButton!
    @IBOutlet weak var hostTextField: NSTextField!
    @IBOutlet weak var portTextField: NSTextField!
    @IBOutlet weak var pathTextField: NSTextField!
    @IBOutlet weak var descriptionLabel: NSTextField!
    @IBOutlet weak var testProgress: NSProgressIndicator!

    // MARK: - controller overrides

    override func viewDidLoad() {
        super.viewDidLoad()
        load()
    }

    // MARK: - implementation

    func load() {
        let prefs = Prefs()
        schemaPopup.selectItem(withTitle: prefs.scheme)
        hostTextField.stringValue = prefs.host
        portTextField.stringValue = String(prefs.port)
        pathTextField.stringValue = prefs.path
        descriptionLabel.stringValue = prefs.replUrl
    }

    func collect() -> Prefs {
        return Prefs(scheme: schemaPopup.titleOfSelectedItem,
                           host: hostTextField.stringValue,
                           port: Int(portTextField.stringValue),
                           path: pathTextField.stringValue)

    }

    func save() {
        Log.info("Saving preferences.")
        collect().save()
    }

    func reset() {
        Log.info("Resetting preferences.")
        Prefs.reset()
        load()
        descriptionLabel.textColor = NSColor.systemGray
    }

    func testSetup() {
        descriptionLabel.textColor = NSColor.systemGray
        testProgress.startAnimation(self)
        descriptionLabel.stringValue = collect().replUrl
    }

    func testSuccess() {
        descriptionLabel.textColor = NSColor.systemGreen
        descriptionLabel.stringValue = "Valid!"
        testProgress.stopAnimation(self)
    }

    func testFailure(reason: String?) {
        let desc = reason ?? "Failed for unknown reason."
        descriptionLabel.textColor = NSColor.systemRed
        descriptionLabel.stringValue = desc
        testProgress.stopAnimation(self)
    }

    // MARK: - action handlers

    @IBAction func okButtonClicked(_ sender: NSButton) {
        save()
        view.window?.close()
    }

    @IBAction func cancelButtonClicked(_ sender: NSButton) {
        view.window?.close()
    }

    @IBAction func resetButtonClicked(_ sender: NSButton) {
        reset()
    }

    @IBAction func testButtonClicked(_ sender: NSButton) {
        testSetup()
        let url = collect().replUrl
        Net.testConnection(with: url) { error, reason in
            guard let e = error else {
                self.testSuccess()
                return
            }
            self.testFailure(reason: e.localizedDescription)
        }
    }
}
