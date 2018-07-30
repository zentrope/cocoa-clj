//
//  Cache.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/29/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Foundation

class Cache {

    var cache = [Int:Any]()

    func save(value: Any, data: AnyHashable...) {
        let key = makeKey(data: data)
        cache[key] = value
    }

    func lookup(data: AnyHashable...) -> Any? {
        let key = makeKey(data: data)
        return cache[key]
    }

    func reset() {
        cache = [Int:Any]()
    }

    private func makeKey(data: AnyHashable...) -> Int {
        var h = Hasher()
        data.forEach { h.combine($0) }
        return h.finalize()
    }
}

