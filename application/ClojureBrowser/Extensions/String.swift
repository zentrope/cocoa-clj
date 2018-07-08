//
//  String.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/7/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Foundation


extension String {

    static let manualLineBreak = "\u{2028}"

    func tighten() -> String {
        // Make structured data into a single paragraph with manual
        // line breaks
        return self.replacingOccurrences(of: "\n", with: String.manualLineBreak)
    }
}
