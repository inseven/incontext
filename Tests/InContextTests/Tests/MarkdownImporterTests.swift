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

import XCTest
@testable import InContextCore

class MarkdownImporterTests: ContentTestCase {

    func testMarkdownTitleOverride() async throws {
        _ = try defaultSourceDirectory.add("site.yaml", contents: """
version: 2
title: Example
url: http://example.com
steps:
  - when: '(.*/)?.*\\.markdown'
    then: markdown
    args:
        defaultCategory: general
        defaultTemplate: posts.html
""")
        let file = try defaultSourceDirectory.add("cheese/index.markdown", location: .content, contents: """
---
title: Fromage
---

These are the contents of the file.
""")
        let importer = MarkdownImporter()
        let result = try await importer.process(file: file,
                                                settings: .init(defaultCategory: "general",
                                                                defaultTemplate: TemplateIdentifier("posts.html")),
                                                outputURL: defaultSourceDirectory.site.filesURL)
        XCTAssertNotNil(result.document)
        XCTAssertEqual(result.document!.metadata["title"] as? String, "Fromage")
    }

    func testMarkdownTitleFromFile() async throws {
        _ = try defaultSourceDirectory.add("site.yaml", contents: """
version: 2
title: Example
url: http://example.com
steps:
  - when: '(.*/)?.*\\.markdown'
    then: markdown
    args:
        defaultCategory: general
        defaultTemplate: posts.html
""")
        let file = try defaultSourceDirectory.add("cheese/index.markdown", location: .content, contents: "Contents!")
        let importer = MarkdownImporter()
        let result = try await importer.process(file: file,
                                                settings: .init(defaultCategory: "general",
                                                                defaultTemplate: TemplateIdentifier("posts.html")),
                                                outputURL: defaultSourceDirectory.site.filesURL)
        XCTAssertNotNil(result.document)
        XCTAssertEqual(result.document!.metadata["title"] as? String, "Cheese")
    }

}
