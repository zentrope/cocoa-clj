//
//  Cache.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/29/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Foundation

/// Stores data based on provided arguments kinda like
/// memoize functions.
class Cache {

    var cache = [Int:Any]()

    func save(value: Any, data: AnyHashable...) {
        var h = Hasher()
        for d in data {
            h.combine(d)
        }
        let key = h.finalize()
        cache[key] = value
    }

    func lookup(data: AnyHashable...) -> Any? {
        var h = Hasher()
        for d in data {
            h.combine(d)
        }
        let key = h.finalize()

        return cache[key]
    }

    func reset() {
        cache = [Int:Any]()
    }
}

