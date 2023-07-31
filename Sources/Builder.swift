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

class Builder {

    let site: Site
    let store: Store
    let templateCache: TemplateCache
    let renderers: [TemplateLanguage: Renderer]

    init(site: Site) async throws {
        try FileManager.default.createDirectory(at: site.buildURL, withIntermediateDirectories: true)
        self.site = site
        self.store = try Store(databaseURL: site.storeURL)
        self.templateCache = try await TemplateCache(rootURL: site.templatesURL)
        self.renderers = [
            .identity: IdentityRenderer(),
            .stencil: StencilRenderer(templateCache: templateCache),
            .tilt: TiltRenderer(),
        ]
    }

    func needsRender(document: Document, renderStatus: RenderStatus?) async throws -> Bool {

        // TODO: Will the render change actually cascade correctly if the document was regenerated due to an injected
        //       settings change, but the mtime didn't change? Do we actually need to bake the fingerprint into the
        //       document and the render tracker?


        guard let renderStatus = renderStatus else {
            // Since there's no render status we assume the document has never been rendered.
            return true
        }

        // Check the document modification date.
        if renderStatus.contentModificationDate != document.contentModificationDate {
            // The document itself has changed.
            return true
        }

        // Check if any of the templates have changed.
        for templateStatus in renderStatus.templates {
            let modificationDate = templateCache.modificationDate(for: templateStatus.identifier)
            if templateStatus.modificationDate != modificationDate {
                return true
            }
        }

        // TODO: Check if any of the templates have changed.
        // Check the query result modification dates.
        for queryStatus in renderStatus.queries {
            // TODO: Content modification dates query _could_ be async.
            let contentModificationDates = try self.store.contentModificationDates(query: queryStatus.query)
            if queryStatus.contentModificationDates != contentModificationDates {
                return true
            }
        }

        // TODO: Ensure we delete render statuses for documents that no longer exist!
        return false
    }

    func render(document: Document,
                documents: [Document],
                renderStatus: RenderStatus?) async throws {

        // TODO: Check the mtime first; this is a really quick way to know we need to re-render.
        //       The whole goal is to do as few evaluations as necessary.

        if !(try await needsRender(document: document, renderStatus: renderStatus)) {
            return
        }

        // TODO: Push this into the site?
        // TODO: Work out which file extension we need to use for our index file (this is currently based on the template).
        // TODO: Guess the template mimetype.
        let destinationDirectoryURL = site.filesURL.appendingPathComponent(document.url)
        let destinationFileURL = destinationDirectoryURL.appendingPathComponent("index", conformingTo: .html)
        print("Rendering '\(document.url)' with template '\(document.template)'...")

        let tracker = QueryTracker(store: store)

        // TODO: Inline the config loaded from the settings file
        // TODO: Does this need to get extracted so it can easily be assembled for inner renders?
        let context: [String: Any] = [
            "site": [
                // TODO: Pull this out of the site configuration.
                // TODO: Should it be type safe?
                "title": "Jason Morley",
                "date_format": "MMMM dd, yyyy",
                "date_format_short": "MMMM dd",
                "url": "https://jbmorley.co.uk",
                "posts": Function { () throws -> [DocumentContext] in
                    return try tracker.documents(query: QueryDescription())
                        .map { DocumentContext(store: tracker, document: $0) }
                },
                "post": Function { (url: String) throws -> DocumentContext? in
                    return try tracker.documents(query: QueryDescription(url: url))
                        .map { DocumentContext(store: tracker, document: $0) }
                        .first
                },
            ] as Dictionary<String, Any>,  // TODO: as [String: Any] is different?
            "generate_uuid": Function {
                return UUID().uuidString
            },
            "page": DocumentContext(store: tracker, document: document),
            "distant_past":  { (timezoneAware: Bool) in
                return Date.distantPast
            }
        ]

        // Get the correct renderer.
        guard let renderer = renderers[document.template.language] else {
            throw InContextError.internalInconsistency("Failed to get renderer for language '\(document.template.language)'.")
        }

        let renderResult = try await renderer.render(document.template.name, context: context)

        // TODO: WE DEFINITELY NEED TO INJECT A TRACKING TEMPLATE CACHE INTO THIS SINCE OTHERWISE WE CAN'T FIGURE OUT
        //       WHEN THINGS CHANGE ACROSS TEMPLATES.

        // Generate the TemplateStatus tuples with the template content modification times.
        var templateStatuses: [TemplateStatus] = []

        let templateIdentifiersUsed: [TemplateIdentifier] = renderResult.templatesUsed.map { name in
            return TemplateIdentifier(.stencil, name)
        }

        for identifier in templateIdentifiersUsed {
            // TODO: Rename to content modification _date_
            guard let modificationDate = templateCache.modificationDate(for: identifier) else {
                throw InContextError.internalInconsistency("Failed to get content modification date for template '\(identifier)'.")
            }
            templateStatuses.append(TemplateStatus(identifier: identifier,
                                                   modificationDate: modificationDate))
        }

        let renderStatus = RenderStatus(contentModificationDate: document.contentModificationDate,
                                        queries: tracker.queries,
                                        templates: templateStatuses)
        try await store.save(renderStatus: renderStatus, for: document.url)

        // Write the contents to a file.
        try FileManager.default.createDirectory(at: destinationDirectoryURL, withIntermediateDirectories: true)
        guard let data = renderResult.content.data(using: .utf8) else {
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
                        if let status = try await self.store.status(for: fileURL.relativePath,
                                                                    contentURL: self.site.contentURL) {

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
                            for asset in try await self.store.assets(for: fileURL.relativePath,
                                                                     filesURL: self.site.filesURL) {
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

            // Preload the existing render statuses in one batch in the hope that it's faster.
            print("Loading render cache...")
            let renderStatuses = try await store.renderStatuses()
                .reduce(into: [String: RenderStatus](), { partialResult, renderStatus in
                    partialResult[renderStatus.0] = renderStatus.1
                })

            // Render the documents.
            // TODO: Generate the document contexts out here.
            let documents = try await store.documents()
            let serial = true  // TODO: Command line argument
            if serial {
                for document in try await store.documents() {
                    try await self.render(document: document,
                                          documents: documents,
                                          renderStatus: renderStatuses[document.url])
                }
            } else {
                try await withThrowingTaskGroup(of: Void.self) { group in
                    for document in documents {
                        group.addTask {
                            try await self.render(document: document,
                                                  documents: documents,
                                                  renderStatus: renderStatuses[document.url])
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
