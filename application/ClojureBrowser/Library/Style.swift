//
//  Style.swift
//  ClojureBrowser
//
//  Created by Keith Irwin on 7/15/18.
//  Copyright © 2018 Zentrope. All rights reserved.
//

import Cocoa

// MARK: - Style application

fileprivate let defaultFont = NSFont.userFixedPitchFont(ofSize: 11.0)!

enum StyleMode {
    case banner
    case clojure
    case error
    case output
    case prompt
    case standard
}

struct Style {

    static func apply(result: Summary) -> NSAttributedString {
        let output = NSMutableAttributedString(string: "")

        if let out = result.output {
            output.append(apply(out, style: .output))
        }
        if let err = result.err {
            output.append(apply(err, style: .error))
        } else if let val = result.value {
            let trimmed = val.trimmingCharacters(in: .whitespacesAndNewlines)
            output.append(apply(trimmed, style: .clojure))
        }

        return output
    }

    static func apply(_ string: String, style: StyleMode) -> NSAttributedString {
        let s = NSMutableAttributedString(string: string)
        let r = NSMakeRange(0, s.length)
        s.addAttribute(.font, value: defaultFont, range: r)
        s.addAttribute(.backgroundColor, value: NSColor.textBackgroundColor, range: r)

        switch style {
        case .clojure:
            return Syntax.highlight(source: string, withFont: defaultFont)
        case .standard:
            s.addAttribute(.foregroundColor, value: NSColor.textColor, range: r)
        case .error:
            s.addAttribute(.foregroundColor, value: NSColor.systemRed, range: r)
        case .output:
            s.addAttribute(.foregroundColor, value: NSColor.systemGray, range: r)
        case .prompt:
            s.addAttribute(.foregroundColor, value: NSColor.systemPurple, range: r)
        case .banner:
            s.addAttribute(.foregroundColor, value: NSColor.systemGray, range: r)
        }
        return s
    }

}

// MARK: - Syntax highlighting

struct Hint {
    var pattern: String
    var color: NSColor

    init(_ aPattern: String, _ aColor: NSColor) {
        pattern = aPattern
        color = aColor
    }
}

fileprivate let keywordHint = Hint("(?<=[(]).+?(?=[ ])",        NSColor.systemBlue)
fileprivate let kwsHint     = Hint("[:]\\S+",                   NSColor.systemBrown)
fileprivate let parensHint  = Hint("[()\\[\\]{}]",              NSColor.systemGray)
fileprivate let dynamicHint = Hint("[*]\\S+[*]",                NSColor.systemRed)
fileprivate let nsHint      = Hint("(?<=[(])([.]|\\w)+(?=[/])", NSColor.systemBrown)
fileprivate let commentHint = Hint("[;].+?[\\n]",               NSColor.systemGray)
fileprivate let stringHint  = Hint("[\"].+?(?>[^\\\\])[\"]",    NSColor.systemPurple)

fileprivate let clojureHints = [
    keywordHint,
    kwsHint,
    parensHint,
    dynamicHint,
    nsHint,
    commentHint, // previous hints erased
    stringHint   // strings in comments still orange
]

struct Syntax {

    static func highlight(source original: String, withFont face: NSFont) -> NSAttributedString {

        let source = NSMutableAttributedString(string: original)
        let range = NSMakeRange(0, source.length)
        source.setAttributes(nil, range: range)
        source.addAttribute(.foregroundColor, value: NSColor.textColor, range: range)
        source.addAttribute(.font, value: face, range: range)

        clojureHints.forEach {
            apply(syntax: $0, to: source, range: range)
        }
        return source
    }

    private static func mkRegex(pattern: String) -> NSRegularExpression? {
        return try? NSRegularExpression(pattern: pattern,
                                        options: [.dotMatchesLineSeparators, .caseInsensitive])
    }

    private static func apply(syntax: Hint, to: NSMutableAttributedString, range: NSRange) {
        guard let regex = mkRegex(pattern: syntax.pattern) else { return }

        let matches = regex.matches(in: to.string, options: [], range: range)
        matches.forEach { m in
            to.removeAttribute(.foregroundColor, range: m.range)
            to.addAttribute(.foregroundColor, value: syntax.color, range: m.range)
        }
    }
}
