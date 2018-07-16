//
//  Net.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/7/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Foundation

struct Net {

    static let defaultTimeout = 3.0 // seconds
    typealias completionHandler = (Error?, String?) -> Void

    // MARK: - API

    static func testConnection(with site: String, _ completion: @escaping completionHandler) {
        invokeRequest(to: site, withBody: Repl.mkPing(), completion)
    }

    static func sendForEval(site: String, form: String) {
        invokeRequest(to: site, withBody: Repl.mkEval(expr: form)) { error, text in
            if let e = error { Notify.shared.deliverError(error: e); return }

            guard let t = text else { return }

            let packets = Nrepl.decode(t)
            let summary = Summary(packets)
            Notify.shared.deliverEval(summary: summary)
        }
    }

    static func getNameSpaces(site: String) {
        invokeRequest(to: site, withBody: Repl.mkGetNameSpaces()) { error, text in
            if let e = error { Notify.shared.deliverError(error: e); return }

            if let t = text {
                let nss = Namespace.decodeNameSpace(jsonString: t)
                Notify.shared.deliverNamespaces(namespaces: nss)
            }
        }
    }

    static func getSymbols(from: String, inNamespace ns: CLJNameSpace) {
        invokeRequest(to: from, withBody: Repl.mkGetSymbols(inNs: ns)) { error, text in
            if let e = error { Notify.shared.deliverError(error: e); return }

            if let t = text {
                let syms = Namespace.decodeSymbols(jsonString: t)
                Notify.shared.deliverSymbols(symbols: syms, inNamespace: ns)
            }
        }
    }

    static func getSource(from :String, forSymbol sym: CLJSymbol) {
        invokeRequest(to: from, withBody: Repl.mkGetSource(forSymbol: sym)) { error, text in
            if let e = error { Notify.shared.deliverError(error: e); return }

            if let t = text {
                let source = Namespace.decodeSource(jsonString: t)
                Notify.shared.deliverSource(source: source, forSymbol: sym)
            }
        }
    }

    // MARK: - Implementation and convenience

    private static func invokeRequest(to siteUrl: String, withBody payload: String, _ completion: completionHandler?) {
        let session = getSession()
        guard let url = findUrl(site: siteUrl, completion) else { return }
        let request = mkPost(url: url, payload: payload)
        invokeTask(session: session, request: request, completion)
    }

    private static func getSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForResource = Net.defaultTimeout
        return URLSession(configuration: config)
    }

    private static func mkPost(url: URL, payload: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = payload.data(using: .utf8)
        request.httpMethod = "POST"
        return request
    }

    private static func findUrl(site: String, _ completion: completionHandler?) -> URL? {
        guard let url = URL(string: site) else {
            DispatchQueue.main.async { completion?(NetError(reason: "invalid url"), nil) }
            return nil
        }
        return url
    }

    private static func invokeTask(session: URLSession, request: URLRequest, _ completion: completionHandler?) {
        let task = session.dataTask(with: request) { data, response, error in
            defer { session.finishTasksAndInvalidate() }
            if error != nil {
                DispatchQueue.main.async { completion?(error, nil) }
            }

            if let body = data,
                let text = String(data: body, encoding: .utf8) {
                DispatchQueue.main.async { completion?(nil, text) }
            }
        }
        task.resume()
    }
}

// MARK: - Support structs

struct NetError: Error {
    var reason: String
}

