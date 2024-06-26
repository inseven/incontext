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

import SwiftSoup

public class Builder {

    static func context(for site: Site, document: Document, renderTracker: RenderTracker) -> [String: Any] {

        let generateUUID = Function {
            return UUID().uuidString
        }

        let titlecase = Function { (string: String) -> String in
            return string.toTitleCase()
        }

        // TODO: Can I do this without performing yet another query? Can I pass the DocumentContext back?
        // TODO: As long as we also cache the render status with this query, we can cache the render output per URL.
        // TODO: Maybe this should just take a string and let the template to do the lookup and render.
        let thumbnail = Function { (url: String) -> String? in
            guard let document = try renderTracker.documentContexts(query: QueryDescription(url: url)).first else {
                return nil
            }
            let html = try document.render()
            let dom = try SwiftSoup.parse(html)
            if let openGraphImage = try dom.select("meta[property=og:image]").first() {
                // Use the Open Graph image tag if it exists.
                return try openGraphImage.attr("content")
            } else if let img = try dom.select("img[src]").first() {
                // Select the first image tag with source.
                return try img.attr("src")
            }
            return nil
        }

        // TODO: Consider separating the store and the site metadata.
        return [
            "site": [
                "title": site.title,
                "url": site.url.absoluteString,
                "metadata": site.metadata,
                "date_format": "MMMM d, yyyy",
                "date_format_short": "MMMM d",
                "documents": Function { () throws -> [DocumentContext] in
                    return try renderTracker.documentContexts(query: QueryDescription())
                },
                "post": Function { (url: String) throws -> DocumentContext? in
                    return try renderTracker.documentContexts(query: QueryDescription(url: url)).first
                },
                "query": Function { (definition: [AnyHashable: Any]) throws -> [DocumentContext] in
                    let query = try QueryDescription(definition: definition)
                    return try renderTracker.documentContexts(query: query)
                }
            ] as [String: Any],
            "document": DocumentContext(renderTracker: renderTracker, document: document),
            "markdown": Function { (string: String) -> String in
                return string.html()
            },
            "iso_8601_format": "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
            "rfc_3339_format": "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
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
            "incontext": [
                "generateUUID": generateUUID,
                "titlecase": titlecase,
                "thumbnail": thumbnail,
            ] as [String: Any]
        ]
    }

    let site: Site
    let tracker: Tracker
    let serializeImport: Bool
    let serializeRender: Bool
    let store: Store
    let templateCache: TemplateCache
    let renderManager: RenderManager

    // TODO: Probably shouldn't await the template cache
    public init(site: Site,
                tracker: Tracker,
                serializeImport: Bool,
                serializeRender: Bool) async throws {
        try FileManager.default.createDirectory(at: site.buildURL, withIntermediateDirectories: true)
        self.site = site
        self.tracker = tracker
        self.serializeImport = serializeImport
        self.serializeRender = serializeRender
        self.store = try Store(databaseURL: site.storeURL)
        self.templateCache = try await TemplateCache(rootURL: site.templatesURL)  // TODO: Does this need to exist here?
        self.renderManager = RenderManager(templateCache: templateCache, extensionsURL: site.extensionsURL)
    }

    // TODO: Perhaps this can get pushed into the RenderManager?
    func needsRender(document: Document, renderStatus: RenderStatus?) async throws -> Bool {

        guard let renderStatus = renderStatus else {
            // Since there's no render status we assume the document has never been rendered.
            return true
        }

        // Check the document modification date.
        if renderStatus.documentFingerprint != document.fingerprint {
            // The document itself has changed.
            return true
        }

        // Check to see if any of the renderers have changed.
        for renderer in renderStatus.renderers {
            if renderer.version != renderManager.rendererVersion {
                // One of the renderers used has been updated.
                return true
            }
        }

        // Check if any of the templates have changed, or if the renderer version used has changed.
        for templateStatus in renderStatus.templates {
            let modificationDate = try templateCache.modificationDate(for: templateStatus.identifier)
            if templateStatus.modificationDate != modificationDate {
                return true
            }
        }

        // Check the query result modification dates.
        for queryStatus in renderStatus.queries {
            let fingerprints = try self.store.fingerprints(query: queryStatus.query)
            if queryStatus.fingerprints != fingerprints {
                return true
            }
        }

        // TODO: Ensure we delete render statuses for documents that no longer exist!
        return false
    }

    func render(session: Session,
                document: Document,
                documents: [Document],
                renderStatus: RenderStatus?) async throws {

        let destinationDirectoryURL = site.filesURL.appendingPathComponent(document.url)
        let destinationFileURL = destinationDirectoryURL
            .appendingPathComponent("index")
            .appendingPathExtension(document.template.pathExtension)

        try await session.withTask("Rendering '\(document.url)' with template '\(document.template)'...") { _ in
            // Render the document using its top-level template.
            // This is tracked using our document-specific `RenderTracker` instance to allow us to track dependencies
            // (queries and templates) and see if they've changed on future incremental builds.
            let renderTracker = RenderTracker(site: site, store: store, renderManager: renderManager)
            let content = try renderTracker.render(document)
            let renderStatus = renderTracker.renderStatus(for: document)
            try await store.save(renderStatus: renderStatus, for: document.url)

            // Write the contents to a file.
            try FileManager.default.createDirectory(at: destinationDirectoryURL, withIntermediateDirectories: true)
            guard let data = content.data(using: .utf8) else {
                throw InContextError.encodingError
            }
            try data.write(to: destinationFileURL)
        }
    }

    func importContent(session: Session) async throws {

        let fileManager = FileManager.default

        let task = session.startTask("Scanning files...")

        // Specify the enumeration resource keys. Unhelpfully, Linux doesn't support loading the modification times
        // during enumeration so we guard against that here and load the modification times differently.
        // Ideally we would extract this code into a shared enumerator that works identically across platforms to avoid
        // cross platform considerations bleeding into the application logic.
        var resourceKeys = Set<URLResourceKey>([.nameKey, .isDirectoryKey])
#if !os(Linux)
        resourceKeys.insert(.contentModificationDateKey)
#endif

        // Linux also has issues with creating relative paths (which we should probably drop anyhow because they're
        // horribly confusing), so we don't ask for these unless we know the platform supports them.
        var options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles]
#if !os(Linux)
        options.insert(.producesRelativePathURLs)
#endif

        let directoryEnumerator = fileManager.enumerator(at: site.contentURL,
                                                         includingPropertiesForKeys: Array(resourceKeys),
                                                         options: options)!
        task.success()

        let fileURLs = try await withTaskRunner(of: URL.self, concurrent: !serializeImport) { tasks in
            for case let enumeratorFileURL as URL in directoryEnumerator {

                // The enumerator won't create relative paths on Linux so we do some extra fix-up.
#if !os(Linux)
                let fileURL = enumeratorFileURL
#else
                let fileURL = enumeratorFileURL.relative(to: site.contentURL)
#endif

                // Get the file metadata.
                let isDirectory = try fileURL
                    .resourceValues(forKeys: [.isDirectoryKey])
                    .isDirectory!

#if !os(Linux)
                let contentModificationDate = try fileURL
                    .resourceValues(forKeys: [.contentModificationDateKey])
                    .contentModificationDate!
#else
                let attr = try FileManager.default.attributesOfItem(atPath: fileURL.path)
                let contentModificationDate = attr[FileAttributeKey.modificationDate] as! Date
#endif

                // Ignore directories.
                if isDirectory {
                    continue
                }

                let task = session.startTask("Importing '\(fileURL.relativePath)'...")

                // Get the handler for the file.
                guard let handler = try self.site.handler(for: fileURL) else {
                    task.warning("Ignoring unsupported file '\(fileURL.relativePath)'.")
                    task.success(.skipped)
                    continue
                }

                // Schedule the import.

                tasks.add {

                    // TODO: Consider moving this out into a separate function.
                    // TODO: Database access is serial and probably introduces contention.
                    // TODO: Templates are stored in cached data so input settings need to invalidate the cache.

                    // Cache metadata about the importer instance / handler.
                    let handlerFingerprint = try handler.fingerprint()

                    // Check to see if the file already exists in the store and has a matching modification date.
                    if let status = try await self.store.status(for: fileURL.relativePath,
                                                                contentURL: self.site.contentURL) {

                        let fileModified = (status.contentModificationDate.millisecondsSinceReferenceDate !=
                                            contentModificationDate.millisecondsSinceReferenceDate)
                        let differentImporterVersion = status.fingerprint != handlerFingerprint

                        if !fileModified && !differentImporterVersion {
                            task.debug("File unchanged")
                            task.success(.skipped)
                            return fileURL
                        }

                        print("CHANGE: \(status.contentModificationDate.millisecondsSinceReferenceDate) != \(contentModificationDate.millisecondsSinceReferenceDate): \(fileURL.relativePath)")

                        // Clean up the existing assets.
                        // TODO: We also need to do this for files that just don't exist anymore.
                        // TODO: This needs to be a utility.
                        let fileManager = FileManager.default
                        for asset in try await self.store.assets(for: fileURL.relativePath,
                                                                 filesURL: self.site.filesURL) {
                            task.info("Removing intermediate '\(asset.fileURL.relativePath)'...")
                            guard fileManager.fileExists(atPath: asset.fileURL.path) else {
                                task.warning("Skipping missing file...")
                                continue
                            }
                            try FileManager.default.removeItem(at: asset.fileURL)
                        }
                        try await self.store.forgetAssets(for: fileURL.relativePath)


                        // TODO: Clean up the existing intermediates if we know that the contents have changed.
                    }

                    task.debug("File new or changed; re-importing")

                    // Import the file.
                    let file = File(url: fileURL, contentModificationDate: contentModificationDate)
                    do {
                        // TODO: Inject the task into the process operation.
                        let result = try await handler.process(file: file, outputURL: self.site.filesURL)
                        let status = Status(fileURL: file.url,
                                            contentModificationDate: file.contentModificationDate,
                                            importer: handler.identifier,
                                            fingerprint: handlerFingerprint)
                        try await self.store.save(document: result.document, assets: result.assets, status: status)
                        task.success()
                        return fileURL
                    } catch {
                        task.failure(error)
                        throw InContextError.importError(fileURL, error)
                    }
                }
            }
        }

        // Remove the documents associated with the files that don't exist any more.
        let documentSourcePaths = Set(try await store.documentRelativeSourcePaths())
        let sourcePaths = Set(fileURLs.map { $0.relativePath })
        let deletedSourcePaths = documentSourcePaths.subtracting(sourcePaths)
        try await store.deleteDocuments(relativeSourcePaths: Array(deletedSourcePaths))

        // TODO: Remove the assets associated with the files that don't exist anymore.
        // TODO: Remove the render output for documents that no longer exist.
    }

    func renderContent(session: Session, concurrent: Bool) async throws {

        // Preload the existing render statuses in one batch in the hope that it's faster.
        let renderStatuses = try await session.withTask("Loading render cache...") { _ in
            return try await store.renderStatuses()
                .reduce(into: [String: RenderStatus](), { partialResult, renderStatus in
                    partialResult[renderStatus.0] = renderStatus.1
                })
        }

        let documents = try session.withTask("Getting documents...") { _ in
            return try store.documents()
        }

        let updates = try await session.withTask("Checking for changes...") { _ in
            return try await withThrowingTaskGroup(of: (Document?).self) { group in
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
        }

        // Render the documents that need updates.
        try await session.withTask("Rendering \(updates.count) documents...") { _ in
            _ = try await withTaskRunner(of: Void.self, concurrent: concurrent) { tasks in
                for document in updates {
                    tasks.add {
                        try await self.render(session: session,
                                              document: document,
                                              documents: documents,
                                              renderStatus: renderStatuses[document.url])
                    }
                }
            }
        }

    }

    func prepare() throws {
        try FileManager.default.createDirectory(at: site.filesURL, withIntermediateDirectories: true)
    }

    func doBuild() async throws {
        let session = tracker.new(type: .build, name: "Build")
        try await session.run {
            renderManager.clearTemplateCache()
            try await importContent(session: session)
            try await renderContent(session: session, concurrent: !serializeRender)
            session.success()
        }
    }

    // TODO: Not sure if this needs to return? It could actually not inject a logger but have a block.
    public func build(watch: Bool = false) async throws {
        try prepare()

        // Prepare to watch for changes in case we've been asked to watch.
        // We create the change observer here (already started) to ensure we don't miss any changes that happen during
        // our initial build.
        let changeObserver = try ChangeObserver(fileURLs: [
            site.contentURL,
            site.templatesURL
        ])

        // TODO: The InContext Helper GUI currently starts different logging sessions whenever rebuilding. We should
        //       explore these two implementations could be somehow unified to avoid duplicate approaches.
        //       That might also improve on the need to have two different code paths (below).

        // We have different error reporting requirements if we're watching and running one-shot.
        if watch {
            while true {
                do {
                    try await doBuild()
                } catch {
                    print("Build failed with error \(error).")
                }
                try changeObserver.wait()
            }
        } else {
            try await doBuild()
        }

    }

}
