//
//  Namespace.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/8/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Foundation

struct Namespace {

    static func decodeNameSpace(jsonString: String) -> [CLJNameSpace] {
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()

        do {
            let namespaces = try decoder.decode([CLJNameSpace].self, from: jsonData)
            return namespaces
        }

        catch let error {
            Log.error("data \(jsonString)")
            Log.error(error.localizedDescription)
            return [CLJNameSpace]()
        }
    }
}

struct CLJNameSpace : Codable {
    var ns: String
    var symbols: [CLJSymbol]
}

struct CLJSymbol : Codable {

    enum DecodingKeys : String {
        case isPrivate = "private"
        case isMacro = "macro"
    }

    var name: String
    var ns: String
    var line: Int?
    var column: Int?
    var file: String?
    var isPrivate: Bool?
    var isMacro: Bool?
    var doc: String?
    var added: String?

    // TODO: arglists
}
