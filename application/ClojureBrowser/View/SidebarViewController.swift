//
//  SidebarViewController.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/8/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Cocoa

class SidebarGroup {
    var name: String
    var namespaces: [CLJNameSpace]

    init(_ aName: String) {
        name = aName
        namespaces = [CLJNameSpace]()
    }
}

// MARK: - Main

class SidebarViewController: NSViewController {

    @IBOutlet weak var outlineView: NSOutlineView!
    @IBOutlet weak var searchField: NSSearchField!
    @IBOutlet weak var publicFilterButton: NSButton!
    @IBOutlet var contextMenu: NSMenu!

    var appGroup = SidebarGroup("Application")
    var libGroup = SidebarGroup("Libraries")
    var cloGroup = SidebarGroup("Clojure")

    var symFilter: CLJSymFilter = .publics
    var showOnlyPublic = true {
        didSet {
            if showOnlyPublic {
                symFilter = .publics
            } else {
                symFilter = .all
            }
        }
    }

    lazy var groups = { return [appGroup, libGroup, cloGroup] }()

    let changeNsMenuItem = NSMenuItem(title: "",
        action: #selector(changeNamespaceAction),
        keyEquivalent: "")

    let sourceMenuItem = NSMenuItem(title: "",
        action: #selector(displaySourceAction),
        keyEquivalent: "")

    override func viewDidLoad() {
        super.viewDidLoad()
        Notify.shared.register(receiver: self)
        loadNamespaces()
        showOnlyPublic = publicFilterButton.state == .on

        contextMenu.delegate = self
    }

    override func viewWillDisappear() {
        Notify.shared.unregister(receiver: self)
    }

    private func loadNamespaces() {
        Net.getNameSpaces(site: Prefs.serverUrl)
    }

    @IBAction func onSearchFieldAction(_ sender: NSSearchField) {
        Log.warn("Search/filter not implemented.")
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
            Net.getSource(from: Prefs.serverUrl, forSymbol: sym)
        }
    }
}

// MARK: - ServerDataReceiver elegates

extension SidebarViewController: MessageReceiver {

    func receive(message: Message) {
        switch message {
        case .namespaceData(let namespaces):
            cloGroup.namespaces = namespaces.filter { $0.name.hasPrefix("clojure.")}
            appGroup.namespaces = namespaces.filter { $0.name == "user" }
            libGroup.namespaces = namespaces.filter { $0.name != "user" && !$0.name.hasPrefix("clojure.")}

            outlineView.reloadData()

        default:
            break
        }
    }
}

// MARK: - NSOutlineViewDataSource delegate

extension SidebarViewController: NSOutlineViewDataSource {

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {

        switch item {

        case let group as SidebarGroup:
            return group.namespaces.count

        case let namespace as CLJNameSpace:
            return namespace.symbols(filter: symFilter).count

        default:
            return item == nil ? groups.count : 0
        }
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {

        switch item {

        case let group as SidebarGroup:
            return group.namespaces[index]

        case let namespace as CLJNameSpace:
            return namespace.symbols(filter: symFilter)[index]

        default:
            return groups[index]
        }
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {

        switch item {

        case _ as SidebarGroup:
            return true

        case let namespace as CLJNameSpace:
            return namespace.symbols(filter: symFilter).count != 0

        case _ as CLJSymbol:
            return false

        default:
            return false
        }
    }
}

// MARK: - NSOutlineView delegate

extension SidebarViewController: NSOutlineViewDelegate {

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {

        switch item {

        case let group as SidebarGroup:
            return makeCell(type: .header, label: group.name, image: nil)

        case let namespace as CLJNameSpace:
            return makeCell(type: .namespace, label: namespace.name, image: nil)

        case let symbol as CLJSymbol:
            let symbolView = makeSymbolCell(label: symbol.name)
            if symbol.isPrivate {
                setImage(inView: symbolView, to: NSImage(named: "Private"))
            }
            if symbol.isMacro {
                setIcon(inView: symbolView, to: NSImage(named: "Macro"))
            } else if symbol.isDeprecated {
                setIcon(inView: symbolView, to: NSImage(named: "Deprecated"))
            } else if symbol.isDynamic {
                setIcon(inView: symbolView, to: NSImage(named: "Dynamic"))
            } else {
                setIcon(inView: symbolView, to: NSImage(named: "Function"))
            }
            return symbolView

        default:
            break
        }
        return nil
    }

    private func setLabel(inView view: NSTableCellView?, to text: String) {
        if let textField = view?.textField {
            textField.stringValue = text
            textField.sizeToFit()
        }
    }

    private func setImage(inView view: NSTableCellView?, to image: NSImage?) {
        if let imageView = view?.imageView {
            imageView.image = image
            imageView.sizeToFit()
        }
    }

    private func setIcon(inView view: SymbolCellView?, to image: NSImage?) {
        if let imageView = view?.iconView {
            imageView.image = image
            imageView.sizeToFit()
        }
    }

    private func makeCell(type: CellType, label: String, image: NSImage?) -> NSTableCellView? {
        let view = outlineView.makeView(withIdentifier: type.rawValue, owner: self) as? NSTableCellView
        setLabel(inView: view, to: label)
        setImage(inView: view, to: image)
        return view
    }

    private func makeSymbolCell(label: String) -> SymbolCellView? {
        let view = outlineView.makeView(withIdentifier: CellType.symbol.rawValue, owner: self) as? SymbolCellView
        setLabel(inView: view, to: label)
        setImage(inView: view, to: nil)
        setIcon(inView: view, to: nil)
        return view
    }

    private enum CellType: RawRepresentable {

        case header, namespace, symbol

        typealias RawValue = NSUserInterfaceItemIdentifier

        init?(rawValue: NSUserInterfaceItemIdentifier) {
            if rawValue.rawValue == "header" {
                self = .header
            }
            if rawValue.rawValue == "namespace" {
                self = .namespace
            }
            if rawValue.rawValue == "symbol" {
                self = .symbol
            }
            return nil
        }

        var rawValue: NSUserInterfaceItemIdentifier {
            switch self {
            case .header:
                return NSUserInterfaceItemIdentifier(rawValue: "HeaderCell")
            case .namespace:
                return NSUserInterfaceItemIdentifier(rawValue: "NamespaceCell")
            case .symbol:
                return NSUserInterfaceItemIdentifier(rawValue: "SymbolCell")
            }
        }
    }
}

// MARK: - NSMenu delegate

extension SidebarViewController: NSMenuDelegate {

    @objc private func displaySourceAction() {
        if let sym = outlineView.item(atRow: outlineView.clickedRow) as? CLJSymbol {
            Net.getSource(from: Prefs.serverUrl, forSymbol: sym)
        }
    }

    @objc private func changeNamespaceAction() {
        if let ns = outlineView.item(atRow: outlineView.clickedRow) as? CLJNameSpace {
            Notify.shared.deliver(.changeNamespaceCommand(ns))
        }
    }

    func menuWillOpen(_ menu: NSMenu) {
        menu.removeAllItems()

        let item = outlineView.item(atRow: outlineView.clickedRow)
        switch item {

        case let ns as CLJNameSpace:
            changeNsMenuItem.title = "Set namesapce to \(ns.name)"
            menu.addItem(changeNsMenuItem)

        case let sym as CLJSymbol:
            sourceMenuItem.title = "Display source for \(sym.name)"
            menu.addItem(sourceMenuItem)

        default:
            break
        }
    }
}
