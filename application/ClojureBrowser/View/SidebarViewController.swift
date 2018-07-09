//
//  SidebarViewController.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/8/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Cocoa

class SidebarViewController: NSViewController {

    // MARK: - Outlets

    @IBOutlet weak var outlineView: NSOutlineView!

    // MARK: - Data

    var namespaces = [CLJNameSpace]()
    var symbols = [String: [CLJSymbol]]()

    // MARK: - View controller

    override func viewDidLoad() {
        super.viewDidLoad()

        let name = Notification.Name("refresh")
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(self.refresh), name: name, object: nil)

        // It's OK if this fails
        loadNamespaces()
    }

    @objc func refresh(notification: NSNotification) {
        loadNamespaces()
    }

    private func loadNamespaces() {
        Log.info("refreshing namespaces")
        Net.getNameSpaces(site: Prefs().replUrl) { error, text in
            if let e = error {
                Log.error(e.localizedDescription)
            }

            if let t = text {
                let nss = Namespace.decodeNameSpace(jsonString: t)
                Log.info("loaded \(nss.count) namespaces")
                self.namespaces = nss
                self.symbols.removeAll()
                self.outlineView.reloadData()
            }
        }
    }

    private func loadSymbols(namespace: CLJNameSpace) {
        if self.symbols[namespace.name] != nil {
            return
        }
        Net.getSymbols(from: Prefs().replUrl, inNamespace: namespace.name) { error, text in
            if let e = error {
                Log.error(e.localizedDescription)
            }

            if let t = text {
                let syms = Namespace.decodeSymbols(jsonString: t)
                Log.info("loaded \(syms.count) symbols for \(namespace.name)")

                for ns in self.namespaces {
                    if ns.name != namespace.name {
                        self.outlineView.collapseItem(ns)
                    }
                }

                let pubs = syms.filter({ s in !(s.isPrivate ?? false)})
                let privs = syms.filter({ s in (s.isPrivate ?? false)})
                self.symbols[namespace.name] = pubs + privs
                self.outlineView.reloadItem(namespace, reloadChildren: true)
            }

        }
    }

    // MARK: - Actions
    
    func refreshNamespaceButtonClick(_ sender: NSToolbarItem) {
        Log.info("REFRESHING NAMESPACES")
        loadNamespaces()
    }

//    @IBAction func doubleClickedItem(_ sender: NSOutlineView) {
//        let item = sender.item(atRow: sender.clickedRow)
//        let text = String(describing: item)
//        Log.info("double click \(text)")
//
//
//    }
//
//    @IBAction func clickedItem(_ sender: NSOutlineView) {
//        let item = sender.item(atRow: sender.clickedRow)
//        let text = String(describing: item)
//        Log.info("click \(text)")
//
//        if item is CLJNameSpace {
//            if sender.isItemExpanded(item) {
//                Log.info("- collapsing")
//                sender.collapseItem(item)
//            } else {
//                Log.info(" - expanding")
//                sender.expandItem(item)
//            }
//        }
//    }

}

extension SidebarViewController: NSOutlineViewDataSource {

    // MARK: - Outline dataource delegate

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return namespaces.count
        }

        if let ns = item as? CLJNameSpace {
            return symbols[ns.name]?.count ?? 0
        }

        return 0
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let ns = item as? CLJNameSpace {
            return symbols[ns.name]![index]
        }
        return namespaces[index]
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if item is CLJNameSpace {
            return true
        }
        return false
    }
}

extension SidebarViewController: NSOutlineViewDelegate {

    // MARK: - Outline view delegate

    func outlineViewItemDidExpand(_ notification: Notification) {
        if let ns = notification.userInfo?["NSObject"] as? CLJNameSpace {
            loadSymbols(namespace: ns)
        }
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {

        var view: NSTableCellView?

        if let sym = item as? CLJSymbol {

            let identifier = NSUserInterfaceItemIdentifier(rawValue: "DataCell")

            view = outlineView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView

            if let imageThing = view?.imageView {
                if sym.isPrivate ?? false {
                    imageThing.image = NSImage(named: NSImage.lockLockedTemplateName)
                    imageThing.sizeToFit()
                } else {
                    imageThing.image = nil
                }
            }

            if let textField = view?.textField {
                textField.stringValue = sym.name
                textField.sizeToFit()
            }
        }

        else if let ns = item as? CLJNameSpace {
            let identifier = NSUserInterfaceItemIdentifier(rawValue: "HeaderCell")

            view = outlineView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView

            if let textField = view?.textField {
                textField.stringValue = ns.name
                textField.sizeToFit()
            }
        }

        return view
    }
}
