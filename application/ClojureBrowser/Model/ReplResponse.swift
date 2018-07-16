//
//  ReplResponse.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/7/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Foundation

struct ReplResponse {

    var value: String?
    var ns: String?
    var output: String?
    var err: String?

    init(error: String) {
        err = error
    }

    init(_ packets: [ResponseData]) {
        for packet in packets {

            if let out = packet.out {
                self.output = self.output ?? "" + out
            }

            ns = packet.ns ?? ns
            value = packet.value ?? value
            err = packet.err ?? err
        }
    }

    static func decode(_ jsonString: String) -> [ResponseData] {

        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()

        do {
            let packets = try decoder.decode([ResponseData].self, from: jsonData)
            return packets
        }

        catch let error {
            Log.error("data \(jsonString)")
            Log.error(error.localizedDescription)
            return [ResponseData]()
        }
    }
}

struct ResponseData : Codable {

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

