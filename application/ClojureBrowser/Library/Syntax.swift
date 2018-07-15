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
        let keywordHint = Hint("(?<=[(]).+?(?=[ ])",        NSColor.systemBlue)
        let kwsHint     = Hint("[:]\\w+",                   NSColor.systemBrown)
        let parensHint  = Hint("[()\\[\\]{}]",              NSColor.systemGray)
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
            commentHint, // previous hints erased
            stringHint   // strings in comments still orange
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

    func highlight(source original: String, withFont face: NSFont) -> NSAttributedString {

        let source = NSMutableAttributedString(string: original)
        let range = NSMakeRange(0, source.length)
        source.setAttributes(nil, range: range)
        source.addAttribute(.foregroundColor, value: NSColor.textColor, range: range)
        source.addAttribute(.font, value: face, range: range)

        hints.forEach {
            apply(syntax: $0, to: source, range: range)
        }
        return source
    }

}
