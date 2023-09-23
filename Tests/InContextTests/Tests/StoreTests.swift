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

class StoreTests: XCTestCase {

    let directoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)

    override func setUp() {
        super.setUp()
        try! FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    override func tearDown() {
        super.tearDown()
        try! FileManager.default.removeItem(at: directoryURL)
    }

    func store() throws -> Store {
        return try Store(databaseURL: directoryURL.appendingPathComponent("store.sqlite"))
    }

    func testEmptyStore() throws {
        let store = try store()
        let documents = try store.documents(query: QueryDescription())
        XCTAssertEqual(documents.count, 0)
    }

    func testSaveSingleDocument() async throws {
        let store = try store()
        try await store.save(Document(url: "/", parent: "/"))
        let documents = try store.documents()
        XCTAssertEqual(documents.count, 1)
    }

    func testDepth() async throws {
        let store = try store()
        try await store.save(Document(url: "/", parent: "/"))
        try await store.save(Document(url: "/projects/", parent: "/"))
        try await store.save(Document(url: "/software/", parent: "/"))
        try await store.save(Document(url: "/projects/anytime-nixie", parent: "/projects/"))

        XCTAssertEqual(try store.documents().count, 4)

        XCTAssertEqual(try store.documents(query: QueryDescription(maximumDepth: 0)).count, 1)
        XCTAssertEqual(try store.documents(query: QueryDescription(maximumDepth: 1)).count, 3)

        XCTAssertEqual(try store.documents(query: QueryDescription(minimumDepth: 0)).count, 4)
        XCTAssertEqual(try store.documents(query: QueryDescription(minimumDepth: 1)).count, 3)

        XCTAssertEqual(try store.documents(query: QueryDescription(minimumDepth: 0, maximumDepth: 1)).count, 3)
        XCTAssertEqual(try store.documents(query: QueryDescription(minimumDepth: 1, maximumDepth: 1)).count, 2)
    }

    func testParent() async throws {
        let store = try store()
        try await store.save(Document(url: "/", parent: "/"))
        try await store.save(Document(url: "/projects/", parent: "/"))
        try await store.save(Document(url: "/software/", parent: "/"))
        try await store.save(Document(url: "/projects/anytime-nixie/", parent: "/projects/"))
        try await store.save(Document(url: "/projects/anytime-nixie/gallery/", parent: "/projects/anytime-nixie/"))
        try await store.save(Document(url: "/software/windows/inmodem/", parent: "/software/"))

        XCTAssertEqual(try store.documents().count, 6)

        XCTAssertEqual(Set(try store.urls(query: QueryDescription(parent: "/"))),
                       Set(["/",
                            "/projects/",
                            "/software/",
                            "/projects/anytime-nixie/",
                            "/projects/anytime-nixie/gallery/",
                            "/software/windows/inmodem/"]))

        XCTAssertEqual(Set(try store.urls(query: QueryDescription(parent: "/projects/"))),
                       Set(["/projects/anytime-nixie/",
                            "/projects/anytime-nixie/gallery/"]))

        XCTAssertEqual(Set(try store.urls(query: QueryDescription(descendantsOf: "/projects/", maximumDepth: 1))),
                       Set(["/projects/anytime-nixie/"]))

        XCTAssertEqual(Set(try store.urls(query: QueryDescription(descendantsOf: "/projects/", maximumDepth: 2))),
                       Set(["/projects/anytime-nixie/",
                            "/projects/anytime-nixie/gallery/"]))

        XCTAssertEqual(Set(try store.urls(query: QueryDescription(descendantsOf: "/software/", maximumDepth: 1))),
                       Set([]))

        XCTAssertEqual(Set(try store.urls(query: QueryDescription(descendantsOf: "/software/", maximumDepth: 2))),
                       Set(["/software/windows/inmodem/"]))
    }

}


extension Store {

    func urls(query: QueryDescription = QueryDescription()) throws -> [String] {
        return try documents(query: query).map { $0.url }
    }

}
