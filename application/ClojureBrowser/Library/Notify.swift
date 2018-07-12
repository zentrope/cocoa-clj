//
//  Notify.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/11/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Foundation

class Notify {

    static var shared = Notify()

    // Unnecessary, but ¯\_(ツ)_/¯.
    private let sourceQ = DispatchQueue(label: "zentrope.notify.source")
    private let nameQ = DispatchQueue(label: "zentrope.notify.names")
    private let symbolQ = DispatchQueue(label: "zentrope.notify.symbols")

    private var sourceReceivers = [SourceDataReceiver]()
    private var namespaceReceivers = [NamespaceDataReceiver]()
    private var symbolReceivers = [SymbolsDataReceiver]()

    private init() {
    }

    // MARK: - Registration

    func register(sourceReceiver handler: SourceDataReceiver) {
        sourceQ.sync {
            sourceReceivers.append(handler)
        }
    }

    func register(namespaceReceiver handler: NamespaceDataReceiver) {
        nameQ.sync {
            namespaceReceivers.append(handler)
        }
    }

    func register(symbolsReceiver handler: SymbolsDataReceiver) {
        symbolQ.sync {
            symbolReceivers.append(handler)
        }
    }

    // MARK: - Unregistration

    func unregister(sourceReceiver handler: SourceDataReceiver) {
        sourceQ.sync {
            sourceReceivers = sourceReceivers.filter { $0 !== handler }
        }
    }

    func unregister(namespaceReceiver handler: NamespaceDataReceiver) {
        nameQ.sync {
            namespaceReceivers = namespaceReceivers.filter { $0 !== handler }
        }
    }

    func unregister(symbolsReceiver handler: SymbolsDataReceiver) {
        symbolQ.sync {
            symbolReceivers = symbolReceivers.filter { $0 !== handler }
        }
    }

    // MARK: - Delivery

    func deliverSource(source: CLJSource, forSymbol sym: CLJSymbol) {
        sourceReceivers.forEach { $0.receive(symbolSource: source, forSymbol: sym) }
    }

    func deliverNamespaces(namespaces nss: [CLJNameSpace]) {
        namespaceReceivers.forEach { $0.receive(namespaces: nss)}
    }

    func deliverSymbols(symbols syms: [CLJSymbol], inNamespace ns: CLJNameSpace) {
        symbolReceivers.forEach { $0.receive(symbols: syms, forNamespace: ns) }
    }
}
