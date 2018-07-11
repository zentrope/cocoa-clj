//
//  Notify.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/11/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Foundation

struct Notify {
    // I'm guessing this makes sense just to centralize these implementations.

    static let SymbolSource = NSNotification.Name("symbol.source")

    static func aboutSource(source: CLJSource, forSymbol sym: CLJSymbol) {
        let data: [AnyHashable:Any] = ["source": source, "symbol": sym]
        NotificationCenter.default.post(name: SymbolSource, object: nil, userInfo: data)
    }

    static func hearAboutSource(_ observer: Any, selector aSelector: Selector) {
        NotificationCenter.default.addObserver(observer, selector: aSelector, name: SymbolSource, object: nil)
    }

}
