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
    let concurrentRenders: Bool
    let store: Store
    let templateCache: TemplateCache
    let renderManager: RenderManager

    init(site: Site, concurrentRenders: Bool) async throws {
        try FileManager.default.createDirectory(at: site.buildURL, withIntermediateDirectories: true)
        self.site = site
        self.concurrentRenders = concurrentRenders
        self.store = try Store(databaseURL: site.storeURL)
        self.templateCache = try await TemplateCache(rootURL: site.templatesURL)  // TODO: Does this need to exist here?
        self.renderManager = RenderManager(templateCache: templateCache, concurrent: concurrentRenders)
    }

    // TODO: Perhaps this can get pushed into the RenderManager?
    func needsRender(document: Document, renderStatus: RenderStatus?) async throws -> Bool {

        // TODO: Will the render change actually cascade correctly if the document was regenerated due to an injected
        //       settings change, but the mtime didn't change? Do we actually need to bake the fingerprint into the
        //       document and the render tracker?
        //       This will _only_ happen if we correctly delete the render cache at injest time. I'm not actually sure
        //       if that is the right choice though; perhaps it is better to treat them as fairly independent stages?
        //       Deleting the render cache feels like it's an optimisation which should improve performance.
        //       It would be good to be able to run the import and render phases separately for integration testing
        //       purposes to check that the correct side effects have happened.

        guard let renderStatus = renderStatus else {
            // Since there's no render status we assume the document has never been rendered.
            return true
        }

        // Check the document modification date.
        if renderStatus.contentModificationDate != document.contentModificationDate {
            // The document itself has changed.
            return true
        }

        // Check to see if any of the renderers have changed.
        for renderer in renderStatus.renderers {
            let currentRenderer = try renderManager.renderer(for: renderer.language)
            if renderer.version != currentRenderer.version {
                // One of the renderers used has been updated.
                return true
            }
        }

        // Check if any of the templates have changed, or if the renderer version used has changed.
        for templateStatus in renderStatus.templates {
            let modificationDate = templateCache.modificationDate(for: templateStatus.identifier)
            if templateStatus.modificationDate != modificationDate {
                return true
            }
        }

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

        // TODO: Push this into the site?
        // TODO: Work out which file extension we need to use for our index file (this is currently based on the template).
        // TODO: Guess the template mimetype.
        let destinationDirectoryURL = site.filesURL.appendingPathComponent(document.url)

        let destinationFileURL = destinationDirectoryURL
            .appendingPathComponent("index")
            .appendingPathExtension(document.template.pathExtension)
        print("Rendering '\(document.url)' with template '\(document.template)'...")

        let queryTracker = QueryTracker(store: store)

        // TODO: Inline the config loaded from the settings file
        // TODO: Does this need to get extracted so it can easily be assembled for inner renders?
        let context: [String: Any] = [
            // TODO: Consider separating the store and the site metadata.
            "site": [
                // TODO: Pull this out of the site configuration.
                // TODO: Should it be type safe?
                "title": "Jason Morley",
                "date_format": "MMMM d, yyyy",
                "date_format_short": "MMMM d",
                "url": "https://jbmorley.co.uk",
                "posts": Function { () throws -> [DocumentContext] in
                    return try queryTracker.documentContexts(query: QueryDescription())
                },
                "post": Function { (url: String) throws -> DocumentContext? in
                    return try queryTracker.documentContexts(query: QueryDescription(url: url)).first
                },
                "query": Function { (definition: [AnyHashable: Any]) throws -> [DocumentContext] in
                    let query = try QueryDescription(definition: definition)
                    return try queryTracker.documentContexts(query: query)
                }
            ] as Dictionary<String, Any>,  // TODO: as [String: Any] is different?
            "generate_uuid": Function {
                return UUID().uuidString
            },
            "titlecase": Function { (string: String) -> String in
                return string.toTitleCase()
            },
            "page": DocumentContext(store: queryTracker, document: document),
            "distant_past": Function { (timezoneAware: Bool) in
                return Date.distantPast
            },
            "markdown": Function { (string: String) -> String in
                // TODO: Actually process the markdown
                return string
            },
            "iso_8601_format": "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
            "date": Function { (string: String) -> Date in
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                guard let date = dateFormatter.date(from: string) else {
                    throw InContextError.internalInconsistency("Unable to construct date from string '\(string)'.")
                }
                return date
            },
            "base64": Function { (string: String) -> String in
                guard let data = string.data(using: .utf8) else {
                    throw InContextError.internalInconsistency("Unable to encode string as UTF-8 data.")
                }
                return data.base64EncodedString()
            },
        ]

        // TODO: Consolidate RenderTracker and QueryTracker
        //       RenderTracker(for document: Document)?
        let renderTracker = RenderTracker()
        let content = try await renderManager.render(renderTracker: renderTracker,
                                                     template: document.template,
                                                     context: context)
        let renderStatus = RenderStatus(contentModificationDate: document.contentModificationDate,
                                        queries: queryTracker.queries,
                                        renderers: renderTracker.renderers(),
                                        templates: renderTracker.statuses())
        try await store.save(renderStatus: renderStatus, for: document.url)

        // Write the contents to a file.
        try FileManager.default.createDirectory(at: destinationDirectoryURL, withIntermediateDirectories: true)
        guard let data = content.data(using: .utf8) else {
            throw InContextError.encodingError
        }
        try data.write(to: destinationFileURL)
    }

    func importContent() async throws {

        let fileManager = FileManager.default

        let resourceKeys = Set<URLResourceKey>([.nameKey, .isDirectoryKey, .contentModificationDateKey])
        let directoryEnumerator = fileManager.enumerator(at: site.contentURL,
                                                         includingPropertiesForKeys: Array(resourceKeys),
                                                         options: [.skipsHiddenFiles, .producesRelativePathURLs])!

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

                // Get the handler for the file.
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
                    do {
                        let result = try await handler.process(site: self.site, file: file)
                        let status = Status(fileURL: file.url,
                                            contentModificationDate: file.contentModificationDate,
                                            importer: handler.identifier,
                                            fingerprint: handlerFingerprint)
                        try await self.store.save(documents: result.documents, assets: result.assets, status: status)
                        return result.documents
                    } catch {
                        throw InContextError.importError(fileURL, error)
                    }
                }
            }
            for try await _ in group {}
        }
        // TODO: Work out how to remove entries for deleted files.
    }

    func renderContent() async throws {

        // Preload the existing render statuses in one batch in the hope that it's faster.
        print("Loading render cache...")
        let renderStatuses = try await store.renderStatuses()
            .reduce(into: [String: RenderStatus](), { partialResult, renderStatus in
                partialResult[renderStatus.0] = renderStatus.1
            })

        print("Getting documents...")
        let documents = try await store.documents()

        // TODO: It should be possible to check whether we need to re-render asynchronously as it doesn't do
        //       anything complicated other than hit the database.

        print("Checking for changes...")
        let updates = try await withThrowingTaskGroup(of: (Document?).self) { group in
            for document in documents {
                group.addTask {
                    if try await self.needsRender(document: document, renderStatus: renderStatuses[document.url]) {
                        return document
                    } else {
                        return nil
                    }
                }
            }
            var result: [Document] = []
            for try await document in group {
                guard let document else {
                    continue
                }
                result.append(document)
            }
            return result
        }

        // Render the documents that need updates.
        print("Rendering \(updates.count) documents...")
        if !concurrentRenders {
            for document in updates {
                try await self.render(document: document,
                                      documents: documents,
                                      renderStatus: renderStatuses[document.url])
            }
        } else {
            try await withThrowingTaskGroup(of: Void.self) { group in
                for document in updates {
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

    func prepare() throws {
        try FileManager.default.createDirectory(at: site.filesURL, withIntermediateDirectories: true)
    }

    func build(watch: Bool = false) async throws {
        try prepare()

        // Prepare to watch for changes in case we've been asked to watch.
        // We create the change observer here (already started) to ensure we don't miss any changes that happen during
        // our initial build.
        let changeObserver = try ChangeObserver(fileURLs: [
            site.contentURL,
            site.templatesURL
        ])

        let clock = ContinuousClock()
        let duration = try await clock.measure {
            try await importContent()
            try await renderContent()
        }
        print("Import took \(duration).")

        // Check to see if we should watch for changes.
        guard watch else {
            return
        }

        // Watch for changes and rebuild.
        while true {
            try changeObserver.wait()
            try await importContent()
            try await renderContent()
            print("Done")
        }

    }

}
