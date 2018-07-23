//
//  Notify.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/11/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Cocoa

protocol SourceDataReceiver: class {
    func receive(symbolSource: CLJSource, forSymbol sym: CLJSymbol)
}

protocol NamespaceDataReceiver: class {
    func receive(namespaces: [CLJNameSpace])
}

protocol EvalDataReceiver: class {
    func receive(response: ReplResponse)
}

protocol ErrorDataReceiver: class {
    func receive(error: Error)
}

protocol SidebarCommandReceiver: class {
    func receive(command: SidebarCommand)
}

class Notify {

    static var shared = Notify()

    private let accessQ = DispatchQueue(label: "zentrope.notify.controller")
    private var controllers = [NSViewController]()

    private init() {
    }

    // MARK: - Registration

    func register(receiver handler: NSViewController) {
        accessQ.sync {
            controllers.append(handler)
        }
    }

    func unregister(receiver handler: NSViewController) {
        accessQ.sync {
            controllers = controllers.filter { $0 != handler }
        }
    }

    // MARK: - Delivery

    func deliverSource(source: CLJSource, forSymbol sym: CLJSymbol) {
        withSync { c in
            guard let handler = c as? SourceDataReceiver else { return }
            DispatchQueue.main.async { handler.receive(symbolSource: source, forSymbol: sym) }
        }
    }

    func deliverNamespaces(namespaces nss: [CLJNameSpace]) {
        withSync { c in
            guard let handler = c as? NamespaceDataReceiver else { return }
            DispatchQueue.main.async { handler.receive(namespaces: nss) }
        }
    }

    func deliverEval(summary sum: ReplResponse) {
        withSync { c in
            guard let handler = c as? EvalDataReceiver else { return }
            DispatchQueue.main.async { handler.receive(response: sum)}
        }
    }

    func deliverError(error err: Error) {
        Log.error(err.localizedDescription)
        withSync { c in
            guard let handler = c as? ErrorDataReceiver else { return }
            DispatchQueue.main.async { handler.receive(error: err)}
        }
    }

    func deliverCommand(command: SidebarCommand) {
        withSync { c in
            guard let handler = c as? SidebarCommandReceiver else { return }
            DispatchQueue.main.async { handler.receive(command: command) }
        }
    }

    private func withSync(closure: @escaping (_ c: NSViewController) -> ()) {
        accessQ.sync {
            controllers.forEach {
                closure($0)
            }
        }
    }

}
