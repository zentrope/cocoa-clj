//
//  Receivable.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/11/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Foundation

// Micro protocols so that ViewControllers don't have to implement all of them

protocol SourceDataReceiver: class {
    func receive(symbolSource: CLJSource, forSymbol sym: CLJSymbol)
}

protocol NamespaceDataReceiver: class {
    func receive(namespaces: [CLJNameSpace])
}

protocol SymbolsDataReceiver: class {
    func receive(symbols: [CLJSymbol], forNamespace ns: CLJNameSpace)
}
