//
//  Nrepl.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/7/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Foundation

struct Nrepl {

    static func decode(_ jsonString: String) -> [NreplResponse] {

        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()

        do {
            let packets = try decoder.decode([NreplResponse].self, from: jsonData)
            return packets
        }

        catch let error {
            Log.error("data \(jsonString)")
            Log.error(error.localizedDescription)
            return [NreplResponse]()
        }
    }
}

struct Summary {

    var value: String?
    var ns: String?
    var output: String?
    var err: String?

    init(_ packets: [NreplResponse]) {
        for packet in packets {
            print(packet)

            if let out = packet.out {
                self.output = self.output ?? "" + out
            }

            ns = packet.ns ?? ns
            value = packet.value ?? value
            err = packet.err ?? err
        }
    }
}

struct NreplResponse : Codable {

    enum DecodingKeys : String {
        case rootEx = "root-ex"
    }

    var id: String
    var session: String
    var value: String?
    var err: String?
    var ex: String?
    var rootEx: String?
    var out: String?
    var ns: String?
    var status: [String]?
}

