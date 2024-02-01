// MIT License
//
// Copyright (c) 2023 Jason Morley
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

class BasenameDetailsTests: XCTestCase {

    func testPostNoDate() {
        let url = URL(filePath: "/posts/this-is-a-post.markdown")
        let details = url.basenameDetails()
        XCTAssertEqual(details.title, "This Is a Post")
        XCTAssertNil(details.date)
        XCTAssertEqual(url.siteURL, "/posts/this-is-a-post/")
        XCTAssertEqual(url.parentURL, "/posts/")
    }

    func testPostDate() {
        let url = URL(filePath: "/posts/2017-12-11-this-is-a-post.markdown")
        let details = url.basenameDetails()
        XCTAssertEqual(details.title, "This Is a Post")
        XCTAssertEqual(details.date, Date(2017, 12, 11, 0, 0))
        XCTAssertEqual(url.siteURL, "/posts/2017-12-11-this-is-a-post/")
        XCTAssertEqual(url.parentURL, "/posts/")
    }

    func testPostIndexNoDate() {
        let url = URL(filePath: "/posts/this-is-a-post/index.markdown")
        let details = url.basenameDetails()
        XCTAssertEqual(details.title, "This Is a Post")
        XCTAssertNil(details.date)
        XCTAssertEqual(url.siteURL, "/posts/this-is-a-post/")
        XCTAssertEqual(url.parentURL, "/posts/")
    }

    func testRootIndexNoTitle() {
        let rootURL = URL(filePath: "/tmp", directoryHint: .isDirectory)
        let url = URL(filePath: "index.markdown", relativeTo: rootURL)
        let details = url.basenameDetails()
        XCTAssertNil(details.date)
        XCTAssertNil(details.title)
        XCTAssertNil(details.scale)
    }

    func testScale() throws {
        let rootURL = URL(filePath: "/tmp", directoryHint: .isDirectory)
        let url = URL(filePath: "books@2x.png", relativeTo: rootURL)
        let details = url.basenameDetails()
        XCTAssertEqual(details.title, "Books")
        XCTAssertEqual(details.scale, 2)
        XCTAssertEqual(details.date, nil)
    }

    func testRootParent() throws {
        let rootURL = URL(filePath: "/Users/jbmorley/Projects/jbmorley.co.uk/content", directoryHint: .isDirectory)
        XCTAssertEqual(URL(filePath: "index.markdown", relativeTo: rootURL).parentURL, "/")
        XCTAssertEqual(URL(filePath: "about/index.markdown", relativeTo: rootURL).parentURL, "/")
    }

    // TODO: Remaining filename tests.

}
