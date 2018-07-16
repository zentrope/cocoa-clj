//
//  ClojureData.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/8/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Foundation

struct ClojureData {

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

    static func decodeSymbols(jsonString: String) -> [CLJSymbol] {
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()

        do {
            let namespaces = try decoder.decode([CLJSymbol].self, from: jsonData)
            return namespaces
        }

        catch let error {
            Log.error("data \(jsonString)")
            Log.error(error.localizedDescription)
            return [CLJSymbol]()
        }
    }

    static func decodeSource(jsonString: String) -> CLJSource {
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()

        do {
            return try decoder.decode(CLJSource.self, from: jsonData)
        }

        catch let error {
            Log.error("data \(jsonString)")
            Log.error(error.localizedDescription)
            return CLJSource(source: error.localizedDescription)
        }
    }
}

struct CLJSource : Codable {
    var source: String
}

class CLJNameSpace : Codable {
    // Has to be a class if used in NSOutlineView
    var name: String
}

struct CLJSymbol : Codable {

    var name: String
    var ns: String

    var line: Int?
    var column: Int?
    var file: String?
    var doc: String?
    var added: String?
    var deprecated: String?

    var isPrivate: Bool?
    var isMacro: Bool?
    var isStatic: Bool?
    var isDynamic: Bool?

    enum CodingKeys : String, CodingKey {
        case name
        case ns

        case line
        case column
        case file
        case doc
        case deprecated

        case isPrivate = "private"
        case isMacro = "macro"
        case isStatic = "static"
        case isDynamic = "dynamic"
    }
}
