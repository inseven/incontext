//
//  File.swift
//  
//
//  Created by Jason Barrie Morley on 19/07/2023.
//

import Foundation

import XCTest
@testable import incontext

struct TestContext: EvaluationContext {

    func lookup(_ name: String) throws -> Any? {
        switch name {
        case "jump": return Function { () -> String in
            return "*boing*"
        }
        case "titlecase": return Function { (string: String) -> String in
            return string.toTitleCase()
        }
        case "echo": return Function { (string: String) -> String in
            return string
        }
        case "prefix": return Function { (str1: String, str2: String) -> String in
            return str1 + str2
        }
        default:
            throw InContextError.unknownSymbol(name)
        }
    }

}

// TODO: Move this into a separate file.
public func XCTAssertEqualAsync<T>(_ expression1: @autoclosure () async throws -> T,
                                   _ expression2: @autoclosure () async throws -> T,
                                   _ message: @autoclosure () -> String = "",
                                   file: StaticString = #filePath,
                                   line: UInt = #line) async where T : Equatable {
    do {
        let result1 = try await expression1()
        let result2 = try await expression2()
        XCTAssertEqual(result1, result2, file: file, line: line)
    } catch {
        XCTFail(message(), file: file, line: line)
    }
}

public func XCTAssertNotEqualAsync<T>(_ expression1: @autoclosure () async throws -> T,
                                      _ expression2: @autoclosure () async throws -> T,
                                      _ message: @autoclosure () -> String = "",
                                      file: StaticString = #filePath,
                                      line: UInt = #line) async where T : Equatable {
    do {
        let result1 = try await expression1()
        let result2 = try await expression2()
        XCTAssertNotEqual(result1, result2, file: file, line: line)
    } catch {
        XCTFail(message(), file: file, line: line)
    }
}

// TODO: Move this out.
func withTemporaryDirectory(perform: @escaping (URL) async throws -> Void) async throws {
    let fileManager = FileManager.default
    let url = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    defer {
        do {
            try fileManager.removeItem(at: url)
        } catch {
            print("Failed to delete temporary directory at '\(url.path)' with error \(error).")
            exit(EXIT_FAILURE)
        }
    }
    try await perform(url)
}
