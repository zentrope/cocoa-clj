//
//  Net.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/7/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Foundation

struct NetError: Error {
    var reason: String
}

struct Net {

    static let defaultTimeout = 3.0 // seconds

    // Test if we can reach the site at all. We don't care if the
    // request itself is reasonable (i.e., a 200 status code),
    // just that we could make a connection.

    private static func getSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForResource = Net.defaultTimeout
        return URLSession(configuration: config)
    }

    static func testConnection(with site: String, _ completion: @escaping (Bool, String?) -> Void) {
        let config = URLSessionConfiguration.ephemeral 
        config.timeoutIntervalForResource = Net.defaultTimeout
        let session = URLSession(configuration: config)

        guard let connUrl = URL(string: site) else {
            DispatchQueue.main.async {
                completion(false, "invalid url")
            }
            return
        }

        let task = session.dataTask(with: connUrl) { data, response, error in
            defer { session.finishTasksAndInvalidate() }
            if error != nil {
                DispatchQueue.main.async {
                    completion(false, error?.localizedDescription)
                }
                return
            }
            DispatchQueue.main.async {
                completion(true, nil)
            }
        }
        task.resume()
    }

    static func sendTo(site: String, form: String, _ completion: @escaping (Error?, String?) -> Void) {
        let session = getSession()

        guard let url = URL(string: site) else {
            DispatchQueue.main.async {
                completion(NetError(reason: "invalid url"), nil)
            }
            return
        }

        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = Repl.mkEval(expr: form).data(using: .utf8)
        request.httpMethod = "POST"

        let task = session.dataTask(with: request) { data, response, error in
            defer { session.finishTasksAndInvalidate() }
            if error != nil {
                DispatchQueue.main.async {
                    completion(error, nil)
                }
            }

            if let body = data,
                let text = String(data: body, encoding: .utf8) {
                DispatchQueue.main.async {
                    completion(nil, text)
                }
            }
        }
        task.resume()
    }

}
