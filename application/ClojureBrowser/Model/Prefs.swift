//
//  Prefs.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/7/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Foundation

fileprivate let defaultScheme = "http"
fileprivate let defaultHost = "localhost"
fileprivate let defaultPort = 60006
fileprivate let defaultPath = "repl"

struct Prefs {

    var scheme: String
    var host: String
    var port: Int
    var path: String

    init() {
        self.scheme = UserDefaults.standard.string(forKey: "scheme") ?? defaultScheme
        self.host = UserDefaults.standard.string(forKey: "host") ?? defaultHost
        self.port = UserDefaults.standard.integer(forKey: "port")
        self.path = UserDefaults.standard.string(forKey: "path") ?? defaultPath

        if self.port == 0 {
            self.port = defaultPort
        }
    }

    init(scheme: String?, host: String, port: Int?, path: String) {
        self.scheme = scheme ?? defaultScheme;
        self.host = host
        self.port = port ?? defaultPort
        self.path = path
    }

    func save() {
        UserDefaults.standard.set(scheme, forKey: "scheme")
        UserDefaults.standard.set(host, forKey: "host")
        UserDefaults.standard.set(port, forKey: "port")
        UserDefaults.standard.set(path, forKey: "path")
    }

    static func reset() {
        let prefs = Prefs(scheme: defaultScheme, host: defaultHost, port: defaultPort, path: defaultPath)
        prefs.save()
    }

    var replUrl: String {
        get {
            var u = URLComponents()
            u.host = host
            u.port = port
            u.path = path
            u.scheme = scheme

            guard let s = u.string else {
                let p = path.starts(with: "/") ? path : "/" + path
                return "\(scheme)://\(host):\(port)\(p)"
            }

            Log.info("returning url components version of url \(s)")
            return s
        }
    }
}
