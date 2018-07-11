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

    static func sendForEval(site: String, form: String, _ completion: @escaping completionHandler) {
        invokeRequest(to: site, withBody: Repl.mkEval(expr: form), completion)
    }

    static func getNameSpaces(site: String, _ completion: @escaping completionHandler) {
        invokeRequest(to: site, withBody: Repl.mkGetNameSpaces(), completion)
    }

    static func getSymbols(from: String, inNamespace ns: String, _ completion: @escaping completionHandler) {
        invokeRequest(to: from, withBody: Repl.mkGetSymbols(inNs: ns), completion)
    }

    static func getSource(from :String, forSymbol sym: String, _ completion: @escaping completionHandler) {
        invokeRequest(to: from, withBody: Repl.mkGetSource(forSymbol: sym), completion)
    }

    // MARK: - Implementation and Convenience

    private static func invokeRequest(to siteUrl: String, withBody payload: String, _ completion: completionHandler?) {
        let session = getSession()
        guard let url = findUrl(site: siteUrl, completion) else {
            return
        }
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
            DispatchQueue.main.async {
                completion?(NetError(reason: "invalid url"), nil)
            }
            return nil
        }
        return url
    }

    private static func invokeTask(session: URLSession, request: URLRequest, _ completion: completionHandler?) {
        let task = session.dataTask(with: request) { data, response, error in
            defer { session.finishTasksAndInvalidate() }
            if error != nil {
                DispatchQueue.main.async {
                    completion?(error, nil)
                }
            }

            if let body = data,
                let text = String(data: body, encoding: .utf8) {
                DispatchQueue.main.async {
                    completion?(nil, text)
                }
            }
        }
        task.resume()
    }
}

// MARK: - Support structs

struct NetError: Error {
    var reason: String
}

