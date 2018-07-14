//
//  Notify.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/11/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Foundation
import Cocoa

class Notify {

    static var shared = Notify()

    private let accessQ = DispatchQueue(label: "zentrope.notify.controller")
    private var controllers = [NSViewController]()

    private init() {
    }

    // MARK: - Registration

    func register(receiver handler: NSViewController) {
        accessQ.sync {
            controllers.append(handler)
        }
    }

    func unregister(receiver handler: NSViewController) {
        accessQ.sync {
            controllers = controllers.filter { $0 != handler }
        }
    }

    // MARK: - Delivery

    func deliverSource(source: CLJSource, forSymbol sym: CLJSymbol) {
        withSync { c in
            guard let handler = c as? SourceDataReceiver else { return }
            DispatchQueue.main.async { handler.receive(symbolSource: source, forSymbol: sym) }
        }
    }

    func deliverNamespaces(namespaces nss: [CLJNameSpace]) {
        withSync { c in
            guard let handler = c as? NamespaceDataReceiver else { return }
            DispatchQueue.main.async { handler.receive(namespaces: nss) }
        }
    }

    func deliverSymbols(symbols syms: [CLJSymbol], inNamespace ns: CLJNameSpace) {
        withSync { c in
            guard let handler = c as? SymbolsDataReceiver else { return }
            DispatchQueue.main.async { handler.receive(symbols: syms, forNamespace: ns) }
        }
    }

    private func withSync(closure: @escaping (_ c: NSViewController) -> ()) {
        // I don't think you can pass in a protocol type to filter with
        // here. A Swift limitation.
        accessQ.sync {
            controllers.forEach {
                closure($0)
            }
        }
    }

}