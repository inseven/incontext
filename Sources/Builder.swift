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
                "date_format_short": "MMMM dd",
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
                    guard let importer = try site.importer(for: fileURL) else {
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

                            // Clean up the existing assets.
                            // TODO: We also need to do this for files that just don't exist anymore.
                            // TODO: This needs to be a utility.
                            let fileManager = FileManager.default
                            for asset in try await self.store.assets(for: fileURL.relativePath) {
                                print("Removing intermediate '\(asset.fileURL)'...")
                                guard fileManager.fileExists(atPath: asset.fileURL.path) else {
                                    print("Skipping missing file...")
                                    continue
                                }
                                try FileManager.default.removeItem(at: asset.fileURL)
                            }
                            try await self.store.forgetAssets(for: fileURL.relativePath)


                            // TODO: Clean up the existing intermediates if we know that the contents have changed.
                        }

                        print("[\(importer.legacyIdentifier)] Importing '\(fileURL.relativePath)'...")

                        // Import the file.
                        let file = File(url: fileURL, contentModificationDate: contentModificationDate)
                        let result = try await importer.process(site: self.site, file: file)
                        let status = Status(fileURL: file.url,
                                            contentModificationDate: file.contentModificationDate,
                                            importer: importer.identifier,
                                            importerVersion: importer.version)
                        try await self.store.save(documents: result.documents, assets: result.assets, status: status)

                        // TODO: This should probably just return the relative paths so we can know which files to delete.
                        return result.documents
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
