// MIT License
//
// Copyright (c) 2016-2024 Jason Morley
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

import Yams

struct FrontmatterDocument {

    private static let frontmatterRegEx = /(?s)^(---\n)(?<metadata>.*?)(---)(\n(?<content>.*))?$/

    var date: Date? {
        return structuredMetadata.date
    }

    var title: String? {
        return structuredMetadata.title
    }

    var template: String? {
        return structuredMetadata.template
    }

    let rawMetadata: String
    let metadata: Dictionary<AnyHashable, Any>
    let content: String

    private let structuredMetadata: Metadata

    init(contents: String, generateHTML: Bool = false) throws {

        // Sometimes we see 'line separator' characters (Unicode 2028) in image and video descriptions (thanks Photos),
        // so we blanket replace these with new lines to be more forgiving.
        let contents = contents.replacingOccurrences(of: "\u{2028}", with: "\n")

        guard let match = contents.wholeMatch(of: Self.frontmatterRegEx) else {
            rawMetadata = ""
            structuredMetadata = Metadata()
            metadata = [:]
            content = generateHTML ? contents.html() : contents
            return
        }

        rawMetadata = String(match.metadata)
        structuredMetadata = (!rawMetadata.isEmpty ?
                              try YAMLDecoder().decode(Metadata.self, from: rawMetadata) : Metadata())
        metadata = try YAMLDecoder().decode(DictionaryWrapper.self, from: rawMetadata).dictionary

        let content = String(match.content ?? "")
        self.content = generateHTML ? content.html() : content
    }

    init(contentsOf url: URL, generateHTML: Bool = false) throws {
        let data = try Data(contentsOf: url)
        guard let contents = String(data: data, encoding: .utf8) else {
            throw InContextError.encodingError
        }
        try self.init(contents: contents, generateHTML: generateHTML)
    }

}
