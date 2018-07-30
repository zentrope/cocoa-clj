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

    var textFilter: String = "" {
        didSet { Log.info("search is `\(textFilter)`") }
    }

    var numGroups: Int {
        get { return GroupType.count }
    }

    private var symbols = [OutlineSymbol]()
    private var cache = Cache()
    private var symbolFilter: SymbolFilter = .publicSymbols

    init() {
    }

    // MARK:- Mutating

    func reloadNamespaces(_ namespaces: [CLJNameSpace]) {
        cache.reset()
        symbols.removeAll()
        namespaces.forEach { ns in
            let group: GroupType = ns.name.hasPrefix("clojure.") ? .clojure :
                ns.name == "user" ? .favorites : .libraries;
            ns.symbols.forEach { sym in
                symbols.append(OutlineSymbol(aSymbol: sym, inGroup: group))
            }
        }
    }

    func setFilter(filter: SymbolFilter) {
        symbolFilter = filter
    }

    // MARK:- Subscripting

    func group(_ type: GroupType) -> OutlineGroup {
        if let saved = cache.lookup(data: type.rawValue, type) as? OutlineGroup {
            return saved
        }
        let g = OutlineGroup(aName: type.rawValue, aType: type)
        cache.save(value: g, data: type.rawValue, type)
        return g
    }

    func namespace(inGroup group: OutlineGroup, atIndex index: Int) -> OutlineNS {
        if let saved = cache.lookup(data: group.type, index) as? OutlineNS {
            return saved
        }

        let ns = namespaces(group.type)[index]
        cache.save(value: ns, data: group.type, index)
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
        let syms = symbols.filter { $0.namespace == ns }
        switch symbolFilter {
        case .publicSymbols:
            return syms.filter { !$0.symbol.isPrivate }
        default:
            return syms
        }
    }

    // MARK:- Favorites handling

    func isFavorited(_ name: String) -> Bool {
        return symbols.first(where: { $0.namespace == name && $0.group == .favorites}) != nil
    }

    func removeFromFaves(_ ns: OutlineNS) {
        symbols.filter({ $0.namespace == ns}).forEach { s in
            s.group = s.namespace.hasPrefix("clojure.") ? .clojure : .libraries
        }
    }

    func moveToFaves(_ name: String) {
        symbols.filter({ $0.namespace == name}).forEach { s in
            s.group = .favorites
        }
    }
}