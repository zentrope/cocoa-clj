//
//  Repl.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/8/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Foundation

struct Repl {

    static func mkEval(expr: String) -> String {
        return encode(op: ReplOp(op: .eval, expr: expr))
    }

    static func mkPing() -> String {
        return encode(op: ReplOp(op: .ping, expr: nil))
    }

    static func mkGetNameSpaces() -> String {
        return encode(op: ReplOp(op: .nss, expr: nil))
    }

    static func encode(op: ReplOp) -> String {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(op)
        return String(data: data, encoding: .utf8)!
    }
}

enum Operation: String, Codable {
    case ping = "ping"
    case eval = "eval"
    case nss = "nss" // Get a list of namespaces
    case ns = "ns"   // Get the symbols in a namespace
    case source = "source"
}

struct ReplOp : Codable {

    var op: Operation
    var expr: String?
}
