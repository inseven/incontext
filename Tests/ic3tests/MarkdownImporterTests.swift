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
@testable import ic3

class MarkdownImporterTests: ContentTestCase {

    func testMarkdownTitleOverride() async throws {
        _ = try defaultSourceDirectory.add("site.yaml", contents: """
config:
    title: Example
build_steps:
  - task: process_files
    args:
      handlers:
        - when: '(.*/)?.*\\.markdown'
          then: import_markdown
""")
        let file = try defaultSourceDirectory.add("cheese/index.markdown", location: .content, contents: """
---
title: Fromage
---

These are the contents of the file.
""")
        let importer = MarkdownImporter()
        let result = try await importer.process(site: defaultSourceDirectory.site, file: file, settings: [:])
        XCTAssertEqual(result.documents.count, 1)
        XCTAssertEqual(result.documents.first!.metadata["title"] as? String, "Fromage")
    }

    func testMarkdownTitleFromFile() async throws {
        _ = try defaultSourceDirectory.add("site.yaml", contents: """
config:
    title: Example
build_steps:
  - task: process_files
    args:
      handlers:
        - when: '(.*/)?.*\\.markdown'
          then: import_markdown
""")
        let file = try defaultSourceDirectory.add("cheese/index.markdown", location: .content, contents: "Contents!")
        let importer = MarkdownImporter()
        let result = try await importer.process(site: defaultSourceDirectory.site, file: file, settings: [:])
        XCTAssertEqual(result.documents.count, 1)
        XCTAssertEqual(result.documents.first!.metadata["title"] as? String, "Cheese")
    }

}
