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

import XCTest
@testable import InContextCore

class IntegrationTests: XCTestCase {

    func testAltAndTitlePromotedFromMarkdownImage() async throws {
        try await withTemporarySourceDirectory { sourceDirectory in
            _ = try sourceDirectory.add("site.yaml", contents: """
version: 2
title: Example
url: http://example.com
steps:
  - when: '(.*/)?.*\\.markdown'
    then: markdown
    args:
        defaultCategory: general
        defaultTemplate: page.html
  - when: '(.*/)?.*\\.jpeg'
    then: image
    args:
        category: photos
        titleFromFilename: false
        defaultTemplate: photo.html
        inlineTemplate: image.html
""")

            _ = try sourceDirectory.add("templates/page.html", contents: "{{ document.render() }}")
            _ = try sourceDirectory.add("templates/photo.html", contents: "{{ document.render() }}")
            _ = try sourceDirectory.add("templates/image.html", contents: """
<img src="{{ document.image.url }}" alt="{{ tag.alt }}" title="{{ tag.title }}">
""")

            _ = try sourceDirectory.copy(try Bundle.module.throwingURL(forResource: "IMG_0581", withExtension: "jpeg"),
                                         to: "posts/photo.jpeg",
                                         location: .content)
            _ = try sourceDirectory.add("posts/post.markdown", location: .content, contents: """
![A cat sitting on a windowsill](photo.jpeg "My favourite cat photo")
""")

            let builder = try await Builder(site: sourceDirectory.site,
                                            tracker: NullTracker(),
                                            serializeImport: true,
                                            serializeRender: true)
            try await builder.build()

            let html = try String(contentsOf: sourceDirectory.site.filesURL.appendingPathComponent("posts/post/index.html"),
                                  encoding: .utf8)

            XCTAssertTrue(html.contains(#"alt="A cat sitting on a windowsill""#))
            XCTAssertTrue(html.contains(#"title="My favourite cat photo""#))
        }
    }

    func testAdmonitionRewritesBlockquote() async throws {
        try await withTemporarySourceDirectory { sourceDirectory in
            _ = try sourceDirectory.add("site.yaml", contents: """
version: 2
title: Example
url: http://example.com
steps:
  - when: '(.*/)?.*\\.markdown'
    then: markdown
    args:
        defaultCategory: general
        defaultTemplate: page.html
""")

            _ = try sourceDirectory.add("templates/page.html", contents: "{{ document.render() }}")

            _ = try sourceDirectory.add("posts/post.markdown", location: .content, contents: """
> [!NOTE]
> Useful information.
""")

            let builder = try await Builder(site: sourceDirectory.site,
                                            tracker: NullTracker(),
                                            serializeImport: true,
                                            serializeRender: true)
            try await builder.build()

            let html = try String(contentsOf: sourceDirectory.site.filesURL.appendingPathComponent("posts/post/index.html"),
                                  encoding: .utf8)

            XCTAssertTrue(html.contains(#"class="admonition admonition-note""#))
            XCTAssertTrue(html.contains("Useful information."))
            XCTAssertFalse(html.contains("<blockquote>"))
            XCTAssertFalse(html.contains("[!NOTE]"))
        }
    }

}
