//
//  State.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/29/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Foundation

enum GroupType: String {
    case favorites
    case libraries
    case clojure

    static let count = 3
}

enum SymbolFilter {
    case allSymbols
    case publicSymbols
}

class OutlineSymbol {
    var symbol: CLJSymbol
    var namespace: String
    var group: GroupType

    init(aSymbol: CLJSymbol, inGroup: GroupType) {
        symbol = aSymbol
        namespace = aSymbol.ns
        group = inGroup
    }
}

class OutlineGroup {
    var name: String
    var type: GroupType

    init(aName: String, aType: GroupType) {
        name = aName.uppercased()
        type = aType
    }

    lazy var hashValue: Int = {
        var h = Hasher.init()
        h.combine(name)
        h.combine(type)
        return h.finalize()
    }()
}

typealias OutlineNS = String

class OutlineState {

    static var shared = OutlineState()

    let numGroups = GroupType.count

    private var symCache = Cache()
    private var cache = Cache()
    private var symbolFilter: SymbolFilter = .publicSymbols
    private var faves = Set<String>()

    var textFilter: String = "" {
        didSet { Log.info("search is `\(textFilter)`") }
    }

    private var _symbols = [OutlineSymbol]()

    private var symbols: [OutlineSymbol] {
        get {
            if let syms = symCache.lookup(data: symbolFilter, textFilter) as? [OutlineSymbol] {
                return syms
            }

            var syms = _symbols
            if symbolFilter == .publicSymbols {
                syms = syms.filter { !$0.symbol.isPrivate }
            }

            if !textFilter.isEmpty {
                syms = syms.filter { $0.symbol.name.contains(textFilter) }
            }

            symCache.save(value: syms, data: symbolFilter, textFilter)
            return syms
        }
        set {
            _symbols = newValue;
            symCache.reset()
        }
    }

    // MARK:- Mutating

    func reloadNamespaces(_ namespaces: [CLJNameSpace]) {
        cache.reset()
        var syms = [OutlineSymbol]()
        namespaces.forEach { ns in
            let group: GroupType = isFavorited(ns.name) ? .favorites :
                ns.name == "user" ? .favorites :
                ns.name.hasPrefix("clojure.") ? .clojure :
                .libraries
            ns.symbols.forEach { sym in
                syms.append(OutlineSymbol(aSymbol: sym, inGroup: group))
            }
        }

        syms.sort(by: { $0.symbol.name < $1.symbol.name })
        symbols = syms
    }

    func setFilter(filter: SymbolFilter) {
        symbolFilter = filter
    }

    func isTextFiltered() -> Bool {
        return !textFilter.isEmpty
    }

    // MARK:- Subscripting

    func favoritesGroup() -> OutlineGroup {
        return group(.favorites)
    }

    func groups() -> [OutlineGroup] {
        return [group(.favorites), group(.libraries), group(.clojure)]
    }

    func group(_ type: GroupType) -> OutlineGroup {
        if let saved = cache.lookup(data: type.rawValue, type) as? OutlineGroup {
            return saved
        }
        let g = OutlineGroup(aName: type.rawValue, aType: type)
        cache.save(value: g, data: type.rawValue, type)
        return g
    }

    func namespace(inGroup group: OutlineGroup, atIndex index: Int) -> OutlineNS {
        let ns = namespaces(group.type)[index]

        if let saved = cache.lookup(data: ns, group.type, index) as? OutlineNS {
            return saved
        }

        cache.save(value: ns, data: ns, group.type, index)
        return ns
    }

    func symbol(inNamespace ns: OutlineNS, atIndex index: Int) -> OutlineSymbol {
        return symbols(inNamespace: ns)[index]
    }

    func group(atIndex index: Int) -> OutlineGroup {
        switch index {
        case 0:
            return group(.favorites)

        case 1:
            return group(.libraries)

        default:
            return group(.clojure)
        }
    }

    // MARK:- Counting

    func count(itemsIn namespace: OutlineNS) -> Int {
        return symbols(inNamespace: namespace).count
    }

    func count(itemsIn group: OutlineGroup) -> Int {
        return namespaces(group.type).count
    }

    // MARK:- Convenience

    private func namespaces(_ type: GroupType) -> [OutlineNS] {
        let names = symbols.filter { $0.group == type }.map { $0.namespace }
        let uniques = Array(Set(names))
        return uniques.sorted(by: { $0 < $1})
    }

    private func symbols(inNamespace ns: String) -> [OutlineSymbol] {
        return symbols.filter { $0.namespace == ns }
    }

    // MARK:- Favorites

    func isFavorited(_ name: String) -> Bool {
        return faves.contains(name)
    }

    func removeFromFaves(_ name: OutlineNS) {
        faves.remove(name)
        symbols.filter({ $0.namespace == name}).forEach { s in
            s.group = s.namespace.hasPrefix("clojure.") ? .clojure : .libraries
        }
    }

    func moveToFaves(_ name: String) {
        faves.insert(name)
        symbols.filter({ $0.namespace == name}).forEach { s in
            s.group = .favorites
        }
    }
}
