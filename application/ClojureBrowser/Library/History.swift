//
//  History.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/17/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Foundation

struct History {

    let max = 50 // oldest
    var buffer = ArraySlice<String>()
    var pointer = 0 // newest

    /// Get the previous entry to the one at hand (.i.e., up arrow).
    mutating func getPrev() -> String? {
        let newPtr = pointer + 1
        if newPtr >= buffer.count {
            return nil
        }
        pointer = newPtr
        return buffer[pointer]
    }

    /// Get the next (more recent) entry (i.e., down arrow).
    mutating func getNext() -> String? {
        let newPtr = pointer - 1 > 0 ? pointer - 1 : 0
        if newPtr >= buffer.count {
            pointer = 0
            return nil
        }
        pointer = newPtr
        return buffer[pointer]
    }

    /// Set the current history with a new value.
    mutating func set(_ cmd: String) {
        let newCmd = cmd.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if buffer.count == 0 {
            buffer.insert(cmd, at: 0)
        } else {
            buffer[0] = newCmd
        }
        pointer = 0
    }

    /// Add a new history item, pushing the rest back
    mutating func new() {
        if (buffer.count == 0) || !buffer[0].isEmpty {
            buffer.insert("", at: 0)
        }
        pointer = 0
        truncate()
    }

    mutating private func truncate() {
        if buffer.count > max {
            buffer = buffer[0...max]
        }
    }
}
