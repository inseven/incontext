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
import UniformTypeIdentifiers

//import Tuxedo
import Stencil

class WithNode: NodeType {

    func render(_ context: Stencil.Context) throws -> String {
        return "missing 'with' implementation"
    }

    init(token: Token) {
        self.token = token
    }

    let token: Token?

    static func parse(_ parser: TokenParser, token: Token) throws -> NodeType {
        var components = token.components
        components.removeFirst()
        _ = try parser.parse(until(["endwith"]))
        _ = parser.nextToken() // Consumes the endwith
        return WithNode(token: token)
    }

}

class MacroNode: NodeType {

    func render(_ context: Stencil.Context) throws -> String {
        return "missing 'macro' implementation"
    }

    init(token: Token) {
        self.token = token
    }

    let token: Token?

    static func parse(_ parser: TokenParser, token: Token) throws -> NodeType {
        var components = token.components
        components.removeFirst()
        _ = try parser.parse(until(["endmacro"]))
        _ = parser.nextToken() // Consumes the endwith
        return MacroNode(token: token)
    }

}

class SetNode: NodeType {

    func render(_ context: Stencil.Context) throws -> String {
        return "missing 'set' implementation"
    }

    init(token: Token) {
        self.token = token
    }

    let token: Token?

    static func parse(_ parser: TokenParser, token: Token) throws -> NodeType {
        var components = token.components
        components.removeFirst()
        return SetNode(token: token)
    }

}

class GalleryNode: NodeType {

    func render(_ context: Stencil.Context) throws -> String {
        return "missing 'gallery' implementation"
    }

    init(token: Token) {
        self.token = token
    }

    let token: Token?

    static func parse(_ parser: TokenParser, token: Token) throws -> NodeType {
        var components = token.components
        components.removeFirst()
        return GalleryNode(token: token)
    }

}

class VideoNode: NodeType {

    func render(_ context: Stencil.Context) throws -> String {
        return "missing 'video' implementation"
    }

    init(token: Token) {
        self.token = token
    }

    let token: Token?

    static func parse(_ parser: TokenParser, token: Token) throws -> NodeType {
        var components = token.components
        components.removeFirst()
        return VideoNode(token: token)
    }

}

class TemplateNode: NodeType {

    func render(_ context: Stencil.Context) throws -> String {
        return "missing 'template' implementation"
    }

    init(token: Token) {
        self.token = token
    }

    let token: Token?

    static func parse(_ parser: TokenParser, token: Token) throws -> NodeType {
        var components = token.components
        components.removeFirst()
        return TemplateNode(token: token)
    }

}

class Builder {

    let site: Site
    let store: Store

    init(site: Site) throws {
        try FileManager.default.createDirectory(at: site.buildURL, withIntermediateDirectories: true)
        self.site = site
        self.store = try Store(databaseURL: site.storeURL)
    }

    func render(document: Document, environment: Environment) async throws {

        // TODO: Push this into the site?
        // TODO: Work out which file extension we need to use for our index file (this is currently based on the template).
        let destinationDirectoryURL = site.filesURL.appendingPathComponent(document.url)
        let destinationFileURL = destinationDirectoryURL.appendingPathComponent("index", conformingTo: .html)
        print("Rendering '\(document.url)' with template '\(document.template)'...")

        // Create the destination directory.
        try FileManager.default.createDirectory(at: destinationDirectoryURL, withIntermediateDirectories: true)

        // TODO: Render the template.
        // TODO: Guess the template mimetype.


        // TODO: Consider caching this and see if it's already cached.
        let html = try environment.renderTemplate(string: document.contents)
        let context: [String: Any] = [
            "site": [
                "title": "Jason Morley",
                "date_format": "MMMM dd, yyyy",
                "date_format_short": "%B %-d",
                "url": "https://jbmorley.co.uk"
            ],
            "page": [
                "title": document.metadata["title"],
                "content": "WELL THIS SUCKS",
                "html": html,
                "date": document.date,
                "query": { (name: String) -> [[String: Any]] in
                    return [[
                        "date": Date(),
                        "title": "Balls",
                        "url": URL(string: "https://www.google.com")!
                    ]]
                }
            ],
            "distant_past":  { (timezoneAware: Bool) in
                return Date.distantPast
            }
        ]
        let contents = try environment.renderTemplate(name: document.template, context: context)

        // TODO: This still requires image fixup.

        // Write the contents to a file.
        guard let data = contents.data(using: .utf8) else {
            throw InContextError.unsupportedEncoding
        }
        try data.write(to: destinationFileURL)
    }

    func build() async throws {
        try FileManager.default.createDirectory(at: site.filesURL, withIntermediateDirectories: true)

        let fileManager = FileManager.default
        let resourceKeys = Set<URLResourceKey>([.nameKey, .isDirectoryKey, .contentModificationDateKey])
        let directoryEnumerator = fileManager.enumerator(at: site.contentURL,
                                                         includingPropertiesForKeys: Array(resourceKeys),
                                                         options: [.skipsHiddenFiles, .producesRelativePathURLs])!

        let clock = ContinuousClock()
        let duration = try await clock.measure {
            try await withThrowingTaskGroup(of: [Document].self) { group in
                var count = 0
                for case let fileURL as URL in directoryEnumerator {

                    // Get the file metadata.
                    let isDirectory = try fileURL
                        .resourceValues(forKeys: [.isDirectoryKey])
                        .isDirectory!
                    let contentModificationDate = try fileURL
                        .resourceValues(forKeys: [.contentModificationDateKey])
                        .contentModificationDate!

                    // Ignore directories.
                    if isDirectory {
                        continue
                    }

                    // Get the importer for the file.
                    guard let importer = site.importer(for: fileURL) else {
                        print("Ignoring unsupported file '\(fileURL.relativePath)'.")
                        continue
                    }

                    // Schedule the import.
                    group.addTask {

                        // TODO: Consider moving this out into a separate function.
                        // TODO: Database access is serial and probably introduces contention.
                        // TODO: Templates are stored in cached data so input settings need to invalidate the cache.

                        // Check to see if the file already exists in the store and has a matching modification date.
                        if let status = try await self.store.status(for: fileURL.relativePath) {
                            if Calendar.current.isDate(status.contentModificationDate,
                                                       equalTo: contentModificationDate,
                                                       toGranularity: .nanosecond) {
                                return []

                                // TODO: Consider whether this would actually be a good time to read the cached documents.
                                //       Importing the documents at this point might be a little memory intensive.

                            }

                            // TODO: Clean up the existing intermediates if we know that the contents have changed.
                        }

                        print("Importing '\(fileURL.relativePath)'...")

                        // Import the file.
                        let file = File(url: fileURL, contentModificationDate: contentModificationDate)
                        let documents = try await importer.process(site: self.site, file: file)
                        let status = Status(fileURL: file.url,
                                            contentModificationDate: file.contentModificationDate,
                                            importer: importer.identifier,
                                            importerVersion: importer.version)
                        try await self.store.save(documents: documents, for: status)

                        // TODO: This should probably just return the relative paths so we can know which files to delete.
                        return documents
                    }
                    count += 1
//                    if count > 500 {
//                        break
//                    }
                }
                for try await _ in group {
//                    documents.append(contentsOf: documents)
                }
            }
            // TODO: Work out how to remove entries for deleted files.

//            let environment = site.environment()
//
//            @dynamicMemberLookup
//            struct Page {
//
//                var query: [String] {
//                    return ["Foo"]
//                }
//
//                var random = "Booooo"
//
//                subscript(dynamicMember member: String) -> Any? {
//                    return "FUDGE"
//                }
//
//            }
//
//            // Render the documents.
//            try await withThrowingTaskGroup(of: Void.self) { group in
//                for document in try await store.documents() {
//                    group.addTask {
//                        try await self.render(document: document, environment: environment)
//                    }
//                }
//                // TODO: Is this necessary?
//                for try await _ in group {}
//            }

        }
        print("Import took \(duration).")
    }

}
