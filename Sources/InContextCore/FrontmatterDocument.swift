// MIT License
//
// Copyright (c) 2023 Jason Barrie Morley
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

// TODO: Remove Yaml
import Yams

struct FrontmatterDocument {

    private static let frontmatterRegEx = /(?s)^(---\n)(?<metadata>.*?)(---)(\n(?<content>.*))?$/

    let rawMetadata: String
    let frontmatter: Frontmatter
    let content: String

    init(contents: String, generateHTML: Bool = false) throws {

        // Sometimes we see 'line separator' characters (Unicode 2028) in image and video descriptions (thanks Photos),
        // so we blanket replace these with new lines to be more forgiving.
        let contents = contents.replacingOccurrences(of: "\u{2028}", with: "\n")

        guard let match = contents.wholeMatch(of: Self.frontmatterRegEx) else {
            rawMetadata = ""
            frontmatter = Frontmatter()
            content = generateHTML ? contents.html() : contents
            return
        }
        rawMetadata = String(match.metadata)
        frontmatter = (!rawMetadata.isEmpty ?
                       try YAMLDecoder().decode(Frontmatter.self, from: rawMetadata) : Frontmatter())
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
