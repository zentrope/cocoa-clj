//
//  Notify.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/11/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Cocoa


enum Message {
    case sourceData(CLJSource, CLJSymbol)
    case namespaceData([CLJNameSpace])
    case evalData(ReplResponse)
    case errorData(Error)
    case changeNamespaceCommand(CLJNameSpace)
}

protocol MessageReceiver: class {
    func receive(message: Message)
}

struct Notify {
    static var shared = Notify()
    var controllers = [MessageReceiver]()

    mutating func register(receiver handler: MessageReceiver) {
        controllers.append(handler)
    }

    mutating func unregister(receiver handler: MessageReceiver) {
        controllers = controllers.filter { $0 !== handler }
    }

    func deliver(_ message: Message) {
        DispatchQueue.main.async { self.controllers.forEach { $0.receive(message: message)} }
    }
}
