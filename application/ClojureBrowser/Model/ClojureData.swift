//
//  ClojureData.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/8/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Foundation

struct ClojureData {

    static func decodeNameSpaces(jsonString: String) -> [CLJNameSpace] {
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
    var name: String
    private var interns: [CLJSymbol]

    lazy var symbols: [CLJSymbol] = {
        let privs = interns.filter { $0.isPrivate }
        let pubs  = interns.filter { !$0.isPrivate }
        return pubs + privs
    }()

    lazy var publics: [CLJSymbol] = {
        return symbols.filter { !$0.isPrivate }
    }()

    enum CodingKeys: String, CodingKey {
        case name
        case interns = "symbols"
    }
}

class CLJSymbol : Codable {
    var ns: String
    var name: String
    var isPrivate: Bool
    var isMacro: Bool
    var isDynamic: Bool
    var isDeprecated: Bool

    enum CodingKeys : String, CodingKey {
        case name
        case ns
        case isPrivate = "private"
        case isMacro = "macro"
        case isDeprecated = "deprecated"
        case isDynamic = "dynamic"
    }
}
