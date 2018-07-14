//
//  Syntax.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/13/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Foundation
import Cocoa

class Syntax {

    static let shared = Syntax()

    var hints = [Hint]()

    private init() {
        // Missing:
        //
        //  #_(some-form should be comment to end of form)
        //


        // Cheating: The first symbol in a form gets the keyword color
        let keywordHint = Hint("(?<=[(]).+?(?=[ ])",        NSColor.systemBlue)
        let kwsHint     = Hint("[:]\\w+",                   NSColor.systemBrown)
        let parensHint  = Hint("[()\\[\\]]",                NSColor.systemGray)
        let dynamicHint = Hint("[*]\\S+[*]",                NSColor.systemRed)
        let nsHint      = Hint("(?<=[(])([.]|\\w)+(?=[/])", NSColor.systemPurple)
        let commentHint = Hint("[;].+?[\\n]",               NSColor.systemGray)
        let stringHint  = Hint("[\"].+?(?>[^\\\\])[\"]",    NSColor.systemOrange)

        self.hints = [
            keywordHint,
            kwsHint,
            parensHint,
            dynamicHint,
            nsHint,
            // Order matters as these will erase any previous
            // attributes. So, CLJ code inside a comment should
            // look like a comment, not like code
            commentHint,
            stringHint
        ]
    }

    struct Hint {
        var pattern: String
        var color: NSColor

        init(_ aPattern: String, _ aColor: NSColor) {
            pattern = aPattern
            color = aColor
        }
    }

    private func mkRegex(pattern: String) -> NSRegularExpression? {
        return try? NSRegularExpression(pattern: pattern,
                                        options: [.dotMatchesLineSeparators, .caseInsensitive])
    }

    private func apply(syntax: Hint, to: NSMutableAttributedString, range: NSRange) {
        guard let regex = mkRegex(pattern: syntax.pattern) else { return }

        let matches = regex.matches(in: to.string, options: [], range: range)
        matches.forEach { m in
            to.removeAttribute(.foregroundColor, range: m.range)
            to.addAttribute(.foregroundColor, value: syntax.color, range: m.range)
        }
    }

    func highlight(source: NSMutableAttributedString, withFont face: NSFont) {

        let sourceRange = NSMakeRange(0, source.length)
        source.setAttributes(nil, range: sourceRange)
        source.addAttribute(.font, value: face, range: sourceRange)

        hints.forEach {
            apply(syntax: $0, to: source, range: sourceRange)
        }
    }
}
