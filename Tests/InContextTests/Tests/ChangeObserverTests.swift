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

class ChangeObserverTests: XCTestCase {

    // Waits for the observer to signal a change, failing the test if none arrives in time.
    private func expectChange(_ observer: ChangeObserver,
                              within timeout: Double = 10,
                              file: StaticString = #filePath,
                              line: UInt = #line) async throws {
        let signalled = try await withThrowingTaskGroup(of: Bool.self) { group in
            group.addTask {
                try await observer.wait()
                return true
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                return false
            }
            let result = try await group.next() ?? false
            group.cancelAll()
            return result
        }
        XCTAssertTrue(signalled, "Timed out waiting for a change notification.", file: file, line: line)
    }

    func testObservesFileCreation() async throws {
        try await withTemporaryDirectory { directoryURL in
            let observer = try ChangeObserver(fileURLs: [directoryURL])
            try "Hello, World!".write(to: directoryURL.appendingPathComponent("file.txt"),
                                      atomically: true,
                                      encoding: .utf8)
            try await expectChange(observer)
        }
    }

    func testObservesChangeInExistingSubdirectory() async throws {
        try await withTemporaryDirectory { directoryURL in
            let nestedURL = directoryURL
                .appendingPathComponent("a")
                .appendingPathComponent("b")
            try FileManager.default.createDirectory(at: nestedURL, withIntermediateDirectories: true)

            let observer = try ChangeObserver(fileURLs: [directoryURL])
            try "Hello, World!".write(to: nestedURL.appendingPathComponent("file.txt"),
                                      atomically: true,
                                      encoding: .utf8)
            try await expectChange(observer)
        }
    }

    func testObservesChangeInNewSubdirectory() async throws {
        try await withTemporaryDirectory { directoryURL in
            let observer = try ChangeObserver(fileURLs: [directoryURL])

            let nestedURL = directoryURL.appendingPathComponent("new")
            try FileManager.default.createDirectory(at: nestedURL, withIntermediateDirectories: true)

            // Consume the pulse for the directory creation itself and give the observer a moment to
            // register its watch on the new directory.
            try await expectChange(observer)
            try await Task.sleep(nanoseconds: 500_000_000)

            try "Hello, World!".write(to: nestedURL.appendingPathComponent("file.txt"),
                                      atomically: true,
                                      encoding: .utf8)
            try await expectChange(observer)
        }
    }

    func testObservesSecondRoot() async throws {
        try await withTemporaryDirectory { directoryURL in
            let firstURL = directoryURL.appendingPathComponent("first", isDirectory: true)
            let secondURL = directoryURL.appendingPathComponent("second", isDirectory: true)
            try FileManager.default.createDirectory(at: firstURL, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: secondURL, withIntermediateDirectories: true)

            let observer = try ChangeObserver(fileURLs: [firstURL, secondURL])
            try "Hello, World!".write(to: secondURL.appendingPathComponent("file.txt"),
                                      atomically: true,
                                      encoding: .utf8)
            try await expectChange(observer)
        }
    }

}
