//
//  AppDelegate.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/2/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var cutMenuItem: NSMenuItem!
    @IBOutlet weak var copyMenuItem: NSMenuItem!
    @IBOutlet weak var pasteMenuItem: NSMenuItem!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        setCutCopyPaste(cut: false, copy: false, paste: false)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

extension AppDelegate: TerminalCutCopyPasteDelegate {

    func setCutCopyPaste(cut: Bool, copy: Bool, paste: Bool) {
        setCutMenu(on: cut)
        setCopyMenu(on: copy)
        setPasteMenu(on: paste)
    }

    func setCutMenu(on: Bool) {
        cutMenuItem.isEnabled = on
    }

    func setCopyMenu(on: Bool) {
        copyMenuItem.isEnabled = on
    }

    func setPasteMenu(on: Bool) {
        pasteMenuItem.isEnabled = on
    }


}
