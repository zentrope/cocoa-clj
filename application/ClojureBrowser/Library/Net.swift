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
        invokeRequest(to: site, withBody: ReplRequest.ping(), completion)
    }

    static func sendForEval(site: String, form: String) {
        invokeRequest(to: site, withBody: ReplRequest.eval(expr: form)) { error, text in
            if let e = error { Notify.shared.deliver(.errorData(e)); return }

            guard let t = text else { return }

            let packets = ReplResponse.decode(t)
            let summary = ReplResponse(packets)
            Notify.shared.deliver(.evalData(summary))
        }
    }

    static func getNameSpaces(site: String) {
        invokeRequest(to: site, withBody: ReplRequest.getNamespaces()) { error, text in
            if let e = error { Notify.shared.deliver(.errorData(e)); return }

            if let t = text {
                let nss = ClojureData.decodeNameSpaces(jsonString: t)
                Notify.shared.deliver(.namespaceData(nss))
            }
        }
    }

    static func getSource(from :String, forSymbol sym: CLJSymbol) {
        invokeRequest(to: from, withBody: ReplRequest.getSource(forSymbol: sym)) { error, text in
            if let e = error { Notify.shared.deliver(.errorData(e)); return }

            if let t = text {
                let source = ClojureData.decodeSource(jsonString: t)
                Notify.shared.deliver(.sourceData(source, sym))
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

