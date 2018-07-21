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

    var appGroup = SidebarGroup("Application")
    var libGroup = SidebarGroup("Libraries")
    var cloGroup = SidebarGroup("Clojure")

    var showOnlyPublic = true

    lazy var groups = { return [appGroup, libGroup, cloGroup] }()

    override func viewDidLoad() {
        super.viewDidLoad()
        Notify.shared.register(receiver: self)
        loadNamespaces()
        showOnlyPublic = publicFilterButton.state == .on
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
            Net.getSource(from: Prefs().replUrl, forSymbol: sym)
        }
    }
}

// MARK: - ServerDataReceiver elegates

extension SidebarViewController: NamespaceDataReceiver {

    func receive(namespaces: [CLJNameSpace]) {
        cloGroup.namespaces = namespaces.filter { $0.name.hasPrefix("clojure.")}
        appGroup.namespaces = namespaces.filter { $0.name == "user" }
        libGroup.namespaces = namespaces.filter { $0.name != "user" && !$0.name.hasPrefix("clojure.")}

        outlineView.reloadData()
    }
}

// MARK: - NSOutlineViewDataSource delegate

extension SidebarViewController: NSOutlineViewDataSource {

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {

        switch item {

        case let group as SidebarGroup:
            return group.namespaces.count

        case let namespace as CLJNameSpace:
            if showOnlyPublic {
                return namespace.publics.count
            }
            return namespace.symbols.count

        default:
            return item == nil ? groups.count : 0
        }
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {

        switch item {

        case let group as SidebarGroup:
            return group.namespaces[index]

        case let namespace as CLJNameSpace:
            if showOnlyPublic {
                return namespace.publics[index]
            }
            return namespace.symbols[index]

        default:
            return groups[index]
        }
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {

        switch item {

        case _ as SidebarGroup:
            return true

        case let namespace as CLJNameSpace:
            if showOnlyPublic {
                return namespace.publics.count != 0
            }
            return namespace.symbols.count != 0

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
            return makeCell(type: .data, label: namespace.name, image: nil)

        case let symbol as CLJSymbol:
            let icon = symbol.isPrivate ? NSImage(named: NSImage.lockLockedTemplateName) : nil
            return makeCell(type: .data, label: symbol.name, image: icon)

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

    private func makeCell(type: CellType, label: String, image: NSImage?) -> NSTableCellView? {
        let view = outlineView.makeView(withIdentifier: type.rawValue, owner: self) as? NSTableCellView
        setLabel(inView: view, to: label)
        setImage(inView: view, to: image)
        return view
    }

    private enum CellType: RawRepresentable {

        case header, data

        typealias RawValue = NSUserInterfaceItemIdentifier

        init?(rawValue: NSUserInterfaceItemIdentifier) {
            if rawValue.rawValue == "header" {
                self = .header
            }
            if rawValue.rawValue == "data" {
                self = .data
            }
            return nil
        }

        var rawValue: NSUserInterfaceItemIdentifier {
            switch self {
            case .header:
                return NSUserInterfaceItemIdentifier(rawValue: "HeaderCell")
            case .data:
                return NSUserInterfaceItemIdentifier(rawValue: "DataCell")
            }
        }
    }
}


