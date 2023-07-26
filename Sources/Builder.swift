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

import Stencil

struct Bind<Head, Tail> {

    let head: Head
    let tail: Tail

}

struct Method {
    let name: String

    init(_ name: String) {
        self.name = name
    }
}

struct Argument<T> {
    let name: String
    let type: T.Type
}

// TODO: Bindable as a protocol?

extension Method {

    func argument<T>(_ argument: String, type: T.Type) -> Bind<Self, Argument<T>> {
        return Bind(head: self, tail: Argument(name: argument, type: type.self))
    }
}

extension Bind {

    func argument<Child>(_ argument: String, type: Child.Type) -> Bind<Self, Argument<Child>> {
        let child = Argument<Child>(name: argument, type: type.self)
        let binding = Bind<Self, Argument<Child>>(head: self, tail: child)
        return binding
    }

}


let foo = Method("Cheese")
let bar = Method("Fudge")
    .argument("str1", type: String.self)
let baz = Method("Blancmange")
    .argument("str1", type: String.self)
    .argument("dbl2", type: Double.self)


// TODO: This could return a tuple? That might be nicer?
// TODO: Are there named tuples?
extension BoundFunctionCall {

    func arguments(_ method: Method) throws -> ()? {
        guard void(method.name) else {
            return nil
        }
        return ()
    }

    func arguments<T>(_ method: Bind<Method, Argument<T>>) throws -> T? {
        guard let arguments = try self.argument(method.head.name,
                                                arg1: method.tail.name, type1: method.tail.type)
        else {
            return nil
        }
        return (arguments.1)
    }

    func arguments<Arg1, Arg2>(_ method: Bind<Bind<Method, Argument<Arg1>>, Argument<Arg2>>) throws -> (Arg1, Arg2)? {
        guard let arguments = try self.arguments(method.head.head.name,
                                                 arg1: method.head.tail.name, type1: method.head.tail.type,
                                                 arg2: method.tail.name, type2: method.tail.type)
        else {
            return nil
        }
        return (arguments.1, arguments.3)
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

    func render(document: Document, environment: Environment, documents: [Document]) async throws {

        // TODO: Push this into the site?
        // TODO: Work out which file extension we need to use for our index file (this is currently based on the template).
        // TODO: Guess the template mimetype.
        let destinationDirectoryURL = site.filesURL.appendingPathComponent(document.url)
        let destinationFileURL = destinationDirectoryURL.appendingPathComponent("index", conformingTo: .html)
        print("Rendering '\(document.url)' with template '\(document.template)'...")


        // TODO: Inline the config loaded from the settings file
        let store = self.store
        let context: [String: Any] = [
            "site": [
                "title": "Jason Morley",
                "date_format": "MMMM dd, yyyy",
                "date_format_short": "MMMM dd",
                "url": "https://jbmorley.co.uk",
                "posts": CallableBlock(Method("posts")) {
                    // TODO: Consider default values for callables.
                    // TODO: Consider wrapping these elsewhere.
                    return documents.map { DocumentContext(store: store, document: $0) }
                }
            ] as Dictionary<String, Any>,  // TODO: as [String: Any] is different?
            "generate_uuid": CallableBlock(Method("generate_uuid")) {
                return UUID().uuidString
            },
            "page": DocumentContext(store: store, document: document),
            "distant_past":  { (timezoneAware: Bool) in
                return Date.distantPast
            }
        ]
        let contents = try environment.renderTemplate(name: document.template, context: context)

        // TODO: Fixup images.
        // TODO: Template HTML.

        // Write the contents to a file.
        try FileManager.default.createDirectory(at: destinationDirectoryURL, withIntermediateDirectories: true)
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
                    guard let handler = try self.site.handler(for: fileURL) else {
                        print("Ignoring unsupported file '\(fileURL.relativePath)'.")
                        continue
                    }

                    // Schedule the import.
                    group.addTask {

                        // TODO: Consider moving this out into a separate function.
                        // TODO: Database access is serial and probably introduces contention.
                        // TODO: Templates are stored in cached data so input settings need to invalidate the cache.

                        // Cache metadata about the importer instance / handler.
                        let handlerFingerprint = try handler.fingerprint()

                        // Check to see if the file already exists in the store and has a matching modification date.
                        if let status = try await self.store.status(for: fileURL.relativePath) {

                            let fileModified = !Calendar.current.isDate(status.contentModificationDate,
                                                                        equalTo: contentModificationDate,
                                                                        toGranularity: .nanosecond)
                            let differentImporterVersion = status.fingerprint != handlerFingerprint

                            if !fileModified && !differentImporterVersion {
                                return []

                                // TODO: Consider whether this would actually be a good time to read the cached documents.
                                //       Importing the documents at this point might be a little memory intensive.

                            }

                            // Clean up the existing assets.
                            // TODO: We also need to do this for files that just don't exist anymore.
                            // TODO: This needs to be a utility.
                            let fileManager = FileManager.default
                            for asset in try await self.store.assets(for: fileURL.relativePath) {
                                print("Removing intermediate '\(asset.fileURL.relativePath)'...")
                                guard fileManager.fileExists(atPath: asset.fileURL.path) else {
                                    print("Skipping missing file...")
                                    continue
                                }
                                try FileManager.default.removeItem(at: asset.fileURL)
                            }
                            try await self.store.forgetAssets(for: fileURL.relativePath)


                            // TODO: Clean up the existing intermediates if we know that the contents have changed.
                        }

                        print("[\(handler.identifier)] Importing '\(fileURL.relativePath)'...")

                        // Import the file.
                        let file = File(url: fileURL, contentModificationDate: contentModificationDate)
                        let result = try await handler.process(site: self.site, file: file)
                        let status = Status(fileURL: file.url,
                                            contentModificationDate: file.contentModificationDate,
                                            importer: handler.identifier,
                                            fingerprint: handlerFingerprint)
                        try await self.store.save(documents: result.documents, assets: result.assets, status: status)

                        // TODO: This should probably just return the relative paths so we can know which files to delete.
                        return result.documents
                    }
                }
                for try await _ in group {
//                    documents.append(contentsOf: documents)
                }
            }
            // TODO: Work out how to remove entries for deleted files.

            let environment = site.environment()

            // Render the documents.
            // TODO: Generate the document contexts out here.
            let documents = try await store.documents()
            let serial = false  // TODO: Command line argument
            if serial {
                for document in try await store.documents() {
                    try await self.render(document: document, environment: environment, documents: documents)
                }
            } else {
                try await withThrowingTaskGroup(of: Void.self) { group in
                    for document in documents {
                        group.addTask {
                            try await self.render(document: document, environment: environment, documents: documents)
                        }
                    }
                    // TODO: Is this necessary?
                    for try await _ in group {}
                }
            }

        }
        print("Import took \(duration).")
    }

}
