//
//  MainWindowController.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/9/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController {
    // This controller exists to work with Toolbar Items

    @IBAction func refreshButtonClicked(_ sender: NSToolbarItem) {
        Log.info("refresh button clicked")

        NotificationCenter.default.post(name: NSNotification.Name("refresh"), object: nil)
    }

    override func windowDidLoad() {
        super.windowDidLoad()
    }

}
