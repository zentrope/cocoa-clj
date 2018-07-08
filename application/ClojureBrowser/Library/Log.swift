//
//  Log.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/7/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Foundation

struct Log {
    // Just re-inventing JVM style programming, here, but mainly
    // to learn.

    static var logFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f
    }()

    enum Level: String {
        case info =  "info "
        case error = "error"
        case warn =  "warn "
    }

    static func nowStr() -> String {
        return logFormatter.string(from: Date())
    }

    static func log(level: Level, usingFormat: String, withArgs: [CVarArg]) {
        let header = "🌲 \(nowStr()) | \(level.rawValue) |"
        let body = String(format: usingFormat, arguments: withArgs)
        print("\(header) \(body)")
    }

    static func info(_ template: String, _ args: CVarArg...) {
        log(level: .info, usingFormat: template, withArgs: args)
    }

    static func warn(_ template: String, _ args: CVarArg...) {
        log(level: .warn, usingFormat: template, withArgs: args)
    }

    static func error(_ template: String, _ args: CVarArg...) {
        log(level: .error, usingFormat: template, withArgs: args)
    }

}
