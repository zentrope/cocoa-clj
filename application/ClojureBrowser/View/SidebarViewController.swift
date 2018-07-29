//
//  SidebarViewController.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/8/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Cocoa


// MARK: - Main

class SidebarViewController: NSViewController {

    @IBOutlet weak var outlineView: NSOutlineView!
    @IBOutlet weak var searchField: NSSearchField!
    @IBOutlet weak var publicFilterButton: NSButton!
    @IBOutlet var contextMenu: NSMenu!

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

    var outlineState: OutlineState = OutlineState.shared

    let changeNsMenuItem = NSMenuItem(
        title: "Set namespace",
        action: #selector(changeNamespaceAction),
        keyEquivalent: "")

    let sourceMenuItem = NSMenuItem(
        title: "View source",
        action: #selector(displaySourceAction),
        keyEquivalent: "")

    let favMenuItem = NSMenuItem(
        title: "Favorite",
        action: #selector(favNamespaceAction),
        keyEquivalent: "")

    let unfavMenuItem = NSMenuItem(
        title: "Unfavorite",
        action: #selector(unfavNamespaceAction),
        keyEquivalent: "")

    override func viewDidLoad() {
        super.viewDidLoad()
        Notify.shared.register(receiver: self)
        loadNamespaces()
        showOnlyPublic = publicFilterButton.state == .on

        contextMenu.delegate = self

        outlineView.registerForDraggedTypes([NSPasteboard.PasteboardType.string])
    }

    override func viewWillDisappear() {
        Notify.shared.unregister(receiver: self)
    }

    private func loadNamespaces() {
        Net.getNameSpaces(site: Prefs.serverUrl)
    }

    private func removeFromFaves(_ namespace: CLJNameSpace) {
        outlineState.removeFromFaves(namespace)
        outlineView.reloadData()
    }

    private func moveToFavorites(_ namespace: String) {
        outlineState.moveToFavorites(namespace)
        outlineView.reloadData()
        outlineView.expandItem(outlineState.favGroup)
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

        switch item {
        case let sym as CLJSymbol:
            Net.getSource(from: Prefs.serverUrl, forSymbol: sym)

        default:
            if sender.isItemExpanded(item) {
                sender.collapseItem(item)
            } else {
                sender.expandItem(item)
            }
        }
    }
}

// MARK: - ServerDataReceiver elegates

extension SidebarViewController: MessageReceiver {

    func receive(message: Message) {
        switch message {
        case .namespaceData(let namespaces):
            outlineState.reloadNamespaces(namespaces)
            outlineView.reloadData()
            outlineView.expandItem(outlineState.favGroup)
            outlineView.expandItem(outlineState.libGroup)

        default:
            break
        }
    }
}

// MARK: - NSOutlineViewDataSource delegate

extension SidebarViewController: NSOutlineViewDataSource {

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {

        switch item {

        case let group as NamespaceGroup:
            return group.namespaces.count

        case let namespace as CLJNameSpace:
            return namespace.symbols(filter: symFilter).count

        default:
            return item == nil ? outlineState.groups.count : 0
        }
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {

        switch item {

        case let group as NamespaceGroup:
            return group.namespaces[index]

        case let namespace as CLJNameSpace:
            return namespace.symbols(filter: symFilter)[index]

        default:
            return outlineState.groups[index]
        }
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {

        switch item {

        case _ as NamespaceGroup:
            return true

        case let namespace as CLJNameSpace:
            return namespace.symbols(filter: symFilter).count != 0

        case _ as CLJSymbol:
            return false

        default:
            return false
        }
    }

    /// Dropped
    func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        let pb = info.draggingPasteboard
        if let ns = pb.string(forType: .string) {
            moveToFavorites(ns)
            return true
        }
        return false
    }

    /// Move dragged thing to pasteboard
    func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
        guard let namespace = item as? CLJNameSpace else {
            return nil
        }
        let pbItem = NSPasteboardItem()
        pbItem.setString(namespace.name, forType: .string)
        return pbItem
    }

    /// Can be dropped on?
    func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        if let group = item as? NamespaceGroup,
            group === outlineState.favGroup {
            return NSDragOperation.move
        }
        return []
    }
}

// MARK: - NSOutlineView delegate

extension SidebarViewController: NSOutlineViewDelegate {

    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        return item is NamespaceGroup
    }

    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        return 20.0
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {

        switch item {

        case let group as NamespaceGroup:
            return makeCell(type: .header, label: group.name, image: nil)

        case let namespace as CLJNameSpace:
            return makeCell(type: .namespace, label: namespace.name, image: NSImage(named: "Namespace"))

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

    @objc private func favNamespaceAction() {
        if let ns = outlineView.item(atRow: outlineView.clickedRow) as? CLJNameSpace {
            moveToFavorites(ns.name)
        }
    }

    @objc private func unfavNamespaceAction() {
        if let ns = outlineView.item(atRow: outlineView.clickedRow) as? CLJNameSpace {
            removeFromFaves(ns)
        }
    }

    func menuWillOpen(_ menu: NSMenu) {
        menu.removeAllItems()

        let item = outlineView.item(atRow: outlineView.clickedRow)
        switch item {

        case let ns as CLJNameSpace:
            if ns.name != "user" {
                if outlineState.isFavorited(ns.name) {
                    menu.addItem(unfavMenuItem)
                } else {
                    menu.addItem(favMenuItem)
                }
            }
            menu.addItem(changeNsMenuItem)

        case _ as CLJSymbol:
            menu.addItem(sourceMenuItem)

        default:
            break
        }
    }
}
