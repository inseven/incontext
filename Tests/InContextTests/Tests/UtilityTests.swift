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

class UtilityTests: XCTestCase {

    func testStringPathDepth() {
        XCTAssertEqual("".pathDepth, 0)
        XCTAssertEqual("/".pathDepth, 0)
        XCTAssertEqual("/software/".pathDepth, 1)
        XCTAssertEqual("/software".pathDepth, 1)
        XCTAssertEqual("/software/incontext/".pathDepth, 2)
        XCTAssertEqual("software/incontext/".pathDepth, 2)
    }

    func testSafeIdentifier() {
        XCTAssertEqual("Header".safeIdentifier(), "header")
        XCTAssertEqual("Header 1".safeIdentifier(), "header-1")
        XCTAssertEqual("Multiple   Spaces".safeIdentifier(), "multiple-spaces")
        XCTAssertEqual("Tabs\tand\nNewlines".safeIdentifier(), "tabs-and-newlines")
        XCTAssertEqual("  Leading and trailing  ".safeIdentifier(), "leading-and-trailing")
        XCTAssertEqual("MixedCASE".safeIdentifier(), "mixedcase")
        XCTAssertEqual("".safeIdentifier(), "")
        XCTAssertEqual("<em>Header</em> 1".safeIdentifier(), "header-1")
        XCTAssertEqual("<a href=\"https://example.com\">Header</a>".safeIdentifier(), "header")
        XCTAssertEqual("Café".safeIdentifier(), "cafe")
        XCTAssertEqual("Rocket 🚀 Launch".safeIdentifier(), "rocket-launch")
        XCTAssertEqual("Fish & Chips".safeIdentifier(), "fish-chips")
        XCTAssertEqual("5 < 10".safeIdentifier(), "5-10")
        XCTAssertEqual("10 > 5".safeIdentifier(), "10-5")
        XCTAssertEqual("\"Quoted\" Header".safeIdentifier(), "quoted-header")
        XCTAssertEqual("It's a Test".safeIdentifier(), "its-a-test")
        XCTAssertEqual("AT&amp;T".safeIdentifier(), "att")
        XCTAssertEqual("Header\"><script>alert(1)</script>".safeIdentifier(), "header")
        XCTAssertEqual("<img src=x onerror=alert(1)>".safeIdentifier(), "")
    }

}
