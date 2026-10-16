// MIT License
//
// Copyright (c) 2026 Jason Morley
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

// Initially generated using AI (Claude Opus 5.5).

import Foundation

import Hummingbird
import XCTest
@testable import InContextCore

class LiveReloadMiddlewareTests: XCTestCase {

    typealias Middleware = LiveReloadMiddleware<BasicRequestContext>

    func testInjectBeforeClosingBody() {
        XCTAssertEqual(Middleware.inject(script: "<script></script>", into: "<html><body><p>Hello</p></body></html>"),
                       "<html><body><p>Hello</p><script></script></body></html>")
    }

    func testInjectBeforeLastClosingBody() {
        XCTAssertEqual(Middleware.inject(script: "<script></script>", into: "<body><pre></body></pre></BODY>"),
                       "<body><pre></body></pre><script></script></BODY>")
    }

    func testInjectWithoutClosingBody() {
        XCTAssertEqual(Middleware.inject(script: "<script></script>", into: "<p>Hello</p>"),
                       "<p>Hello</p><script></script>")
    }

    func testScriptEscapesETag() {
        XCTAssertTrue(Middleware.script(eTag: "W/\"abc\"").contains("const eTag = \"W\\/\\\"abc\\\"\";"))
    }

}
