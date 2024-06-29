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

import Yams

@testable import InContextCore

func withTemporarySourceDirectory(perform: (SourceDirectory) throws -> Void) throws {
    let directoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    defer {
        try! FileManager.default.removeItem(at: directoryURL)
    }
    let sourceDirectory = try SourceDirectory(rootURL: directoryURL)
    try perform(sourceDirectory)

    lazy var defaultSourceDirectory = {
        try! SourceDirectory(rootURL: directoryURL)
    }()
}

class SourceDirectory {

    enum Location {
        case root
        case content
    }

    let rootURL: URL
    let contentURL: URL

    lazy var site: Site = {
        try! Site(rootURL: rootURL)
    }()

    init(rootURL: URL) throws {
        self.rootURL = rootURL
        self.contentURL = rootURL.appendingPathComponent("content", isDirectory: true)
        try FileManager.default.createDirectory(at: contentURL, withIntermediateDirectories: true)
    }

    func url(for location: Location) -> URL {
        switch location {
        case .root:
            return rootURL
        case .content:
            return contentURL
        }
    }

    // TODO: Do I need to make it obvoius this outputs YAML?
    func add(_ path: String, location: Location = .root, contents: Codable) throws -> File {
        let rootURL = url(for: location)
        assert(!path.hasPrefix("/"), "Paths must be relative")
        let fileURL = URL(filePath: path, relativeTo: rootURL)
        let directoryURL = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let encoder = YAMLEncoder()
        let contents = try encoder.encode(contents)
        try contents.write(to: fileURL, atomically: true, encoding: .utf8)
        return try File(url: fileURL)
    }

    func add(_ path: String, location: Location = .root, contents: String) throws -> File {
        let rootURL = url(for: location)
        assert(!path.hasPrefix("/"), "Paths must be relative")
        let fileURL = URL(filePath: path, relativeTo: rootURL)
        let directoryURL = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try contents.write(to: fileURL, atomically: true, encoding: .utf8)
        return try File(url: fileURL)
    }

    func copy(_ sourceURL: URL, to path: String, location: Location = .root) throws -> File {
        let rootURL = url(for: location)
        let destinationURL = URL(filePath: path, relativeTo: rootURL)
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        return try File(url: destinationURL)
    }

}
