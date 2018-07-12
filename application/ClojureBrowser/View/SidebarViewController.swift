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
    @IBOutlet weak var searchField: NSSearchField!
    @IBOutlet weak var publicFilterButton: NSButton!

    // MARK: - Data

    var namespaces = [CLJNameSpace]()
    var symbols = [String: [CLJSymbol]]()
    var filteredNamespaces = [CLJNameSpace]()
    var filter = ""
    var showOnlyPublic = false

    // MARK: - Controller

    override func viewDidLoad() {
        super.viewDidLoad()
        Notify.shared.register(namespaceReceiver: self)
        Notify.shared.register(symbolsReceiver: self)
        loadNamespaces()
        filter = ""
        showOnlyPublic = publicFilterButton.state == NSControl.StateValue.on
    }

    override func viewWillDisappear() {
        Notify.shared.unregister(namespaceReceiver: self)
        Notify.shared.unregister(symbolsReceiver: self)
    }

    // MARK: - Implementation

    private func reset() {
        filter = ""
        self.searchField.stringValue = ""
        self.filteredNamespaces = self.filterNamespaces()
        self.symbols.removeAll()
        self.outlineView.reloadData()
    }

    private func filterNamespaces() -> [CLJNameSpace] {
        if namespaces.isEmpty {
            return self.namespaces
        }

        if filter.isEmpty {
            return self.namespaces
        }

        let term = filter.lowercased()
        return namespaces.filter({ ns in ns.name.contains(term) })
    }

    private func loadNamespaces() {
        Net.getNameSpaces(site: Prefs().replUrl)
    }

    private func loadSymbols(namespace: CLJNameSpace) {
        if self.symbols[namespace.name] != nil {
            return
        }
        Net.getSymbols(from: Prefs().replUrl, inNamespace: namespace)
    }

    func findSymbols(inNamespace name: String) -> [CLJSymbol] {
        guard let syms = symbols[name] else {
            return [CLJSymbol]()
        }

        if showOnlyPublic {
            return syms.filter({ s in !(s.isPrivate ?? false) })
        }
        return syms
    }

    // MARK: - Actions
    
    @IBAction func onSearchFieldAction(_ sender: NSSearchField) {
        self.filter = sender.stringValue
        self.filteredNamespaces = self.filterNamespaces()
        self.outlineView.reloadData()
    }

    @IBAction func refreshButtonClicked(_ sender: NSButton) {
        loadNamespaces()
    }

    @IBAction func togglePublicFlag(_ sender: NSButton) {
        showOnlyPublic = !showOnlyPublic
        outlineView.reloadData()
    }

    @IBAction func doubleClicked(_ sender: NSOutlineView) {
        let item = sender.item(atRow: sender.clickedRow)
        if let sym = item as? CLJSymbol {
            Net.getSource(from: Prefs().replUrl, forSymbol: sym)
        }
    }
}

extension SidebarViewController: NamespaceDataReceiver, SymbolsDataReceiver {

    func receive(symbols: [CLJSymbol], forNamespace ns: CLJNameSpace) {
        let pubs = symbols.filter({ s in !(s.isPrivate ?? false)})
        let privs = symbols.filter({ s in (s.isPrivate ?? false)})
        self.symbols[ns.name] = pubs + privs
        self.outlineView.reloadItem(ns, reloadChildren: true)
    }

    func receive(namespaces: [CLJNameSpace]) {
        self.namespaces = namespaces
        self.reset()
    }
}

extension SidebarViewController: NSOutlineViewDataSource {

    // MARK: - Outline datasource delegate

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {

        let nss = self.filteredNamespaces

        if item == nil {
            return nss.count
        }

        if let ns = item as? CLJNameSpace {
            return findSymbols(inNamespace: ns.name).count
        }

        return 0
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let ns = item as? CLJNameSpace {
            return findSymbols(inNamespace: ns.name)[index]
            //return symbols[ns.name]![index]
        }

        let nss = self.filteredNamespaces
        return nss[index]
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

        // TODO: Revise all this with better cell layouts

        var view: NSTableCellView?

        if let sym = item as? CLJSymbol {

            if sym.isPrivate ?? false {
                let identifier = NSUserInterfaceItemIdentifier(rawValue: "DataCell")

                view = outlineView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView
                if let imageThing = view?.imageView {
                    imageThing.image = NSImage(named: NSImage.lockLockedTemplateName)
                    imageThing.sizeToFit()
                }

            } else {

                let identifier = NSUserInterfaceItemIdentifier(rawValue: "HeaderCell")

                view = outlineView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView

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
