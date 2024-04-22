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

class DateParserTests: XCTestCase {

    func testFormats() {
        XCTAssertEqual(DateParser().date(from: "2024-01-17T17:53:07-1000"),
                       Date(2024, 01, 17, 17, 53, 07, timeZone: TimeZone(-10)!))
        XCTAssertEqual(DateParser().date(from: "2001-10-02 01:54:02 +01:00"),
                       Date(2001, 10, 02, 01, 54, 02, timeZone: TimeZone(1)!))
        XCTAssertEqual(DateParser().date(from: "2023-03-31T19:00:13.118338+01:00"),
                       Date(2023, 03, 31, 19, 00, 13, 118, timeZone: TimeZone(1)!))
        XCTAssertEqual(DateParser().date(from: "2017-07-03 09:38:22.602694"),
                       Date(2017, 07, 03, 09, 38, 22, 602))

    }

}
