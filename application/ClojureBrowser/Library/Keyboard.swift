//
//  Keyboard.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/15/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Cocoa

enum KeyEventResult {
    case handled
    case unhandled
}

enum KeyOp {
    case enter, right, left, up, down, home, end, delete, clear, cut, copy, paste, unknown, value
}

struct KeyEvent {

    let kcLetterA    =   0
    let kcLetterX    =   7
    let kcLetterC    =   8
    let kcLetterV    =   9
    let kcLetterE    =  14
    let kcReturnKey  =  36
    let kcLetterK    =  40
    let kcDeleteKey  =  51
    let kcLeftArrow  = 123
    let kcRightArrow = 124
    let kcDownArrow  = 125
    let kcUpArrow    = 126

    var flags: NSEvent.ModifierFlags
    var key: Int
    var chs: String
    var event: NSEvent

    init(event theEvent: NSEvent) {
        event = theEvent
        chs = theEvent.characters ?? ""
        key = Int(theEvent.keyCode)
        flags = theEvent.modifierFlags.intersection([.command, .control, .function, .option])
    }

    func op() -> KeyOp {
        switch (key, flags) {
        case (kcReturnKey, let mods) where mods.isEmpty:
            return .enter
        case (kcRightArrow, let mods) where mods == [.command, .function]:
            return .end
        case (kcLetterE, let mods) where mods == [.control]:
            return .end
        case (kcLeftArrow, let mods) where mods == [.command, .function]:
            return .home
        case (kcLetterA, let mods) where mods == [.control]:
            return .home
        case (kcRightArrow, let mods) where mods == [.function]:
            return .right
        case (kcLeftArrow, let mods) where mods == [.function]:
            return .left
        case (kcUpArrow, let mods) where mods == [.function]:
            return .up
        case (kcDownArrow, let mods) where mods == [.function]:
            return .down
        case (kcLetterX, let mods) where mods == [.command]:
            return .cut
        case (kcLetterC, let mods) where mods == [.command]:
            return .copy
        case (kcLetterV, let mods) where mods == [.command]:
            return .paste
        case (kcLetterK, let mods) where mods == [.command]:
            return .clear
        case (kcDeleteKey, let mods) where mods.isEmpty:
            return .delete
        default:
            if flags.isEmpty { return .value }
            return .unknown
        }
    }

    func describe() -> String {
        return describe(self.flags)
    }

    func describe(_ flags: NSEvent.ModifierFlags) -> String {
        var d = [String]()
        if flags.contains(.command) { d.append("⌘")}
        if flags.contains(.option) { d.append("⌥")}
        if flags.contains(.control) { d.append("⌃")}
        if flags.contains(.function) { d.append("fn")}
        d.append(String(key))
        return d.joined(separator: "-")
    }
}
