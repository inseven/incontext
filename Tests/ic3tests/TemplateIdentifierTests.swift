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

class TemplateIdentifierTests: XCTestCase {

    func testEquality() {
        XCTAssertEqual(TemplateIdentifier(.tilt, "default.html"),
                       TemplateIdentifier(.tilt, "default.html"))
        XCTAssertNotEqual(TemplateIdentifier(.tilt, "page.html"),
                          TemplateIdentifier(.tilt, "default.html"))
    }

    func testConvenienceConstructors() {
        XCTAssertEqual(TemplateIdentifier(.tilt, "default.html"), .tilt("default.html"))    }

    func testInitRawValue() {

        // Scoped identifiers.
        XCTAssertEqual(TemplateIdentifier(rawValue: "tilt:default.html"), TemplateIdentifier(.tilt, "default.html"))
        XCTAssertEqual(TemplateIdentifier(rawValue: "tilt: default.html"), TemplateIdentifier(.tilt, "default.html"))
        XCTAssertEqual(TemplateIdentifier(rawValue: "tilt :default.html"), TemplateIdentifier(.tilt, "default.html"))
        XCTAssertEqual(TemplateIdentifier(rawValue: "tilt : default.html"), TemplateIdentifier(.tilt, "default.html"))

        // Legacy identifiers.
        XCTAssertEqual(TemplateIdentifier(rawValue: "default.html"), TemplateIdentifier(.tilt, "default.html"))
    }


    func testRawValue() {
        XCTAssertEqual(TemplateIdentifier(.tilt, "video.html").rawValue, "tilt:video.html")
    }

}

