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
@testable import incontext

class HandlerTests: XCTestCase {

    func testCaseSensitivity() throws {
        let handler: Handler<MarkdownImporter> = try .init(when: "photos.*\\.(jpg|jpeg|png|gif|tiff|heic)",
                                                           importer: MarkdownImporter(),
                                                           settings: .init(defaultCategory: "general",
                                                                           defaultTemplate: TemplateIdentifier("posts.html")))
        XCTAssertTrue(try handler.matches(relativePath: "photos/snapshots/image.heic"))
        XCTAssertTrue(try handler.matches(relativePath: "photos/snapshots/image.HEIC"))
    }

    func testFingerprint() throws {
        let handler1: Handler<MarkdownImporter> = try .init(when: "photos.*\\.(jpg|jpeg|png|gif|tiff|heic)",
                                                            importer: MarkdownImporter(),
                                                            settings: .init(defaultCategory: "general",
                                                                            defaultTemplate: TemplateIdentifier("posts.html")))

        let handler2: Handler<MarkdownImporter> = try .init(when: "photos.*\\.(jpg|jpeg|png|gif|tiff|heic)",
                                                            importer: MarkdownImporter(),
                                                            settings: .init(defaultCategory: "general",
                                                                            defaultTemplate: TemplateIdentifier("posts.html")))
        XCTAssertEqual(try handler1.fingerprint(), try handler2.fingerprint())

        let handler3: Handler<MarkdownImporter> = try .init(when: "photos.*\\.(jpg|jpeg|png|gif|tiff|heic)",
                                                            importer: MarkdownImporter(),
                                                            settings: .init(defaultCategory: "photos",
                                                                            defaultTemplate: TemplateIdentifier("posts.html")))
        XCTAssertNotEqual(try handler1.fingerprint(), try handler3.fingerprint())
    }

    func testFingerprintStability() throws {
        let handler: Handler<MarkdownImporter> = try .init(when: "photos.*\\.(jpg|jpeg|png|gif|tiff|heic)",
                                                           importer: MarkdownImporter(),
                                                           settings: .init(defaultCategory: "general",
                                                                           defaultTemplate: TemplateIdentifier("posts.html")))
        XCTAssertEqual(try handler.fingerprint(), "ffHqCBy7nf2pFz1nG0D2+A==")
    }

}
