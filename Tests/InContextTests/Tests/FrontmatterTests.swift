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

import XCTest
@testable import InContextCore

class FrontmatterTests: XCTestCase {

    func testParseMarkdown() throws {
        let document = try FrontmatterDocument(contents: """
---
template: tags.html
title: Tags
category: pages
queries:
  posts:
    include:
    - general
---
Here's some **Markdown** content
""", generateHTML: true)

        XCTAssertEqual(document.content, "<p>Here's some <strong>Markdown</strong> content</p>\n")
        XCTAssertEqual(document.frontmatter,
                       Frontmatter(category: "pages",
                                   template: TemplateIdentifier("tags.html"),
                                   title: "Tags",
                                   queries: ["posts": QueryDescription(includeCategories: ["general"])],
                                   metadata: [:]))
    }

    func testEmptyFrontmatter() throws {
        let document = try FrontmatterDocument(contents: "**strong**")
        XCTAssertEqual(document.content, "**strong**")
        XCTAssertEqual(document.frontmatter, Frontmatter())
    }

    func testEmptyFrontmatterParseHTML() throws {
        let document = try FrontmatterDocument(contents: "**strong**", generateHTML: true)
        XCTAssertEqual(document.content, "<p><strong>strong</strong></p>\n")
        XCTAssertEqual(document.frontmatter, Frontmatter())
    }

}
