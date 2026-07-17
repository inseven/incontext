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
import Lua
import CLua
@testable import InContextCore

class LuaArgumentTests: XCTestCase {

    func testNormalizesLuaIntegerTableValues() throws {
        let L = LuaState(libraries: [])
        defer { L.close() }
        L.push(["maximumDepth": 1])
        let raw: [AnyHashable: Any] = try XCTUnwrap(L.tovalue(1))

        let dictionary = try XCTUnwrap(unwrapLuaValue(raw) as? [String: Any])
        let maximumDepth: Int? = try dictionary.optionalValue(for: "maximumDepth")
        XCTAssertEqual(maximumDepth, 1)
    }

    func testNormalizesLuaStringTableValues() throws {
        let L = LuaState(libraries: [])
        defer { L.close() }
        L.push(["sort": "ascending"])
        let raw: [AnyHashable: Any] = try XCTUnwrap(L.tovalue(1))

        let dictionary = try XCTUnwrap(unwrapLuaValue(raw) as? [String: Any])
        let sort: String? = try dictionary.optionalValue(for: "sort")
        XCTAssertEqual(sort, "ascending")
    }

    func testNormalizesEmptyTable() throws {
        let L = LuaState(libraries: [])
        defer { L.close() }
        L.push([:] as [String: Int])
        let raw: [AnyHashable: Any] = try XCTUnwrap(L.tovalue(1))

        let dictionary = unwrapLuaValue(raw) as? [String: Any]
        XCTAssertNotNil(dictionary)
        XCTAssertEqual(dictionary?.isEmpty, true)
    }

    func testNormalizesNestedTables() throws {
        let L = LuaState(libraries: [])
        defer { L.close() }
        L.push(["query": ["maximumDepth": 2]])
        let raw: [AnyHashable: Any] = try XCTUnwrap(L.tovalue(1))

        let dictionary = try XCTUnwrap(unwrapLuaValue(raw) as? [String: Any])
        let nested = try XCTUnwrap(dictionary["query"] as? [AnyHashable: Any] as? [String: Any])
        let maximumDepth: Int? = try nested.optionalValue(for: "maximumDepth")
        XCTAssertEqual(maximumDepth, 2)
    }

}
