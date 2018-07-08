//
//  ReplOp.swift
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

    static func encode(op: ReplOp) -> String {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(op)
        return String(data: data, encoding: .utf8)!
    }
}

enum Operation: String, Codable {
    case eval = "eval"
    case allNS = "all-ns"
    case setNS = "set-ns"
    case source = "source"
}

struct ReplOp : Codable {

    var op: Operation
    var expr: String?
}
