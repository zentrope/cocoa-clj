//
//  State.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/29/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Foundation

struct OutlineState {

    static var shared = OutlineState()

    var favGroup: NamespaceGroup
    var libGroup: NamespaceGroup
    var cloGroup: NamespaceGroup
    var groups: [NamespaceGroup]

    private var favorites = Set<String>()

    init() {
        let faves = NamespaceGroup("Favorites")
        let libs = NamespaceGroup("Libraries")
        let core = NamespaceGroup("Clojure")
        let all = [faves, libs, core]

        favGroup = faves
        libGroup = libs
        cloGroup = core
        groups = all
    }

    mutating func reloadNamespaces(_ namespaces: [CLJNameSpace]) {
        cloGroup.namespaces = namespaces.filter { $0.name.hasPrefix("clojure.")}
        favGroup.namespaces = namespaces.filter { $0.name == "user" }
        libGroup.namespaces = namespaces.filter { $0.name != "user" && !$0.name.hasPrefix("clojure.")}
    }

    func isFavorited(_ name: String) -> Bool {
        return favorites.contains(name)
    }

    private func syncFavorites() {
        favorites.forEach {
            if let mover = libGroup.extract(name: $0) {
                favGroup.append(ns: mover)
            } else if let mover = cloGroup.extract(name: $0) {
                favGroup.append(ns: mover)
            }
        }
    }

    mutating func removeFromFaves(_ namespace: CLJNameSpace) {
        if namespace.name.hasPrefix("clojure.") {
            cloGroup.append(ns: namespace)
        } else {
            libGroup.append(ns: namespace)
        }

        let _ = favorites.remove(namespace.name)
        let _ = favGroup.extract(name: namespace.name)
        syncFavorites()
    }

    mutating func moveToFavorites(_ namespace: String) {
        favorites.insert(namespace)
        syncFavorites()
    }

}

class NamespaceGroup {

    var name: String
    var namespaces: [CLJNameSpace]

    init(_ aName: String) {
        name = aName
        namespaces = [CLJNameSpace]()
    }

    func append(ns: CLJNameSpace) {
        namespaces.append(ns)
        namespaces = namespaces.sorted(by: {$0.name < $1.name} )
    }

    func extract(name: String) -> CLJNameSpace? {
        if let found = namespaces.first(where: { $0.name == name}) {
            namespaces = namespaces.filter { $0 !== found }
            return found
        }
        return nil
    }
}
