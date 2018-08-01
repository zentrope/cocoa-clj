//
//  ReplRequest.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/8/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Foundation

struct ReplRequest {

    static func eval(expr: String) -> String {
        return encode(op: ReplData(op: .eval, expr: expr))
    }

    static func ping() -> String {
        return encode(op: ReplData(op: .ping))
    }

    static func getSymbols() -> String {
        return encode(op: ReplData(op: .symbols))
    }

    static func getSource(forSymbol sym: CLJSymbol) -> String {
        let ref = "\(sym.ns)/\(sym.name)"
        return encode(op: ReplData(op: .source, symbol: ref))
    }

    static private func encode(op: ReplData) -> String {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(op)
        return String(data: data, encoding: .utf8)!
    }
}

fileprivate enum ReplOp: String, Codable {
    case ping, eval, symbols, source
}

fileprivate struct ReplData : Codable {

    init(op: ReplOp) {
        self.op = op
    }

    init(op: ReplOp, expr: String) {
        self.op = op
        self.expr = expr
    }

    init(op: ReplOp, symbol: String) {
        self.op = op
        self.symbol = symbol
    }

    var op: ReplOp
    var expr: String?
    var symbol: String?
}
