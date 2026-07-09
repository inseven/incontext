// MIT License
//
// Copyright (c) 2016-2026 Jason Morley
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

import SwiftSoup

struct AdmonitionTransform: Transformer {

    private static let markerRegex = /^\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]\n?/

    func transform(renderTracker: RenderTracker, document: DocumentContext, content: SwiftSoup.Document) throws {
        for blockquote in try content.getElementsByTag("blockquote") {
            guard let paragraph = blockquote.children().first(where: { $0.tagName() == "p" }),
                  let textNode = paragraph.textNodes().first,
                  let match = textNode.text().prefixMatch(of: Self.markerRegex)
            else {
                continue
            }

            let type = String(match.output.1).lowercased()
            let remainder = String(textNode.text()[match.range.upperBound...])

            if remainder.isEmpty {
                try paragraph.remove()
            } else {
                _ = textNode.text(remainder)
            }

            try blockquote.tagName("div")
            try blockquote.addClass("admonition")
            try blockquote.addClass("admonition-\(type)")
        }
    }

}
