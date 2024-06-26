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

import SQLite

class Store {

    struct Schema {

        static let documents = Table("documents")
        static let status = Table("status")
        static let assets = Table("assets")
        static let renderStatus = Table("render_status")

        // common
        static let url = Expression<String>("url")
        static let contentModificationDate = Expression<Int>("content_modification_date")
        static let relativeSourcePath = Expression<String>("relative_source_path")
        static let fingerprint = Expression<String>("fingerprint")

        // documents
        // TODO: Parent should be nullable.
        static let parent = Expression<String>("parent")
        static let category = Expression<String>("category")
        static let date = Expression<Date?>("date")
        static let title = Expression<String?>("title")
        static let metadata = Expression<String>("metadata")
        static let contents = Expression<String>("contents")
        static let template = Expression<String>("template")
        static let inlineTemplate = Expression<String?>("inline_template")
        static let format = Expression<Document.Format>("format")
        static let depth = Expression<Int>("depth")

        // status
        static let relativePath = Expression<String>("relative_path")  // TODO: This should be relative source path
        static let importer = Expression<String>("importer")

        // assets
        static let relativeAssetPath = Expression<String>("relative_asset_path")

        // render status
        static let details = Expression<Data>("details")

    }

    let databaseURL: URL
    let syncQueue = DispatchQueue(label: "Store.syncQueue")
    let connection: Connection
    let documentsCache = Cache<QueryDescription, [Document]>()
    let fingerprintsCache = Cache<QueryDescription, [String]>()
    let renderStatusCache = Cache<String, RenderStatus>()

    static var migrations: [Int32: (Connection) throws -> Void] = [
        1: { connection in
            print("create the documents table...")
            try connection.run(Schema.documents.create(ifNotExists: true) { t in
                t.column(Schema.url, primaryKey: true)
                t.column(Schema.parent)
                t.column(Schema.category)
                t.column(Schema.date)
                t.column(Schema.title)
                t.column(Schema.metadata)
                t.column(Schema.contents)
                t.column(Schema.contentModificationDate)
                t.column(Schema.template)
                t.column(Schema.inlineTemplate)
                t.column(Schema.relativeSourcePath)
                t.column(Schema.format)
                t.column(Schema.depth)
                t.column(Schema.fingerprint)
            })
            print("create the status table...")
            try connection.run(Schema.status.create(ifNotExists: true) { t in
                t.column(Schema.relativePath, primaryKey: true)
                t.column(Schema.contentModificationDate)
                t.column(Schema.importer)
                t.column(Schema.fingerprint)
            })
            print("create the assets table...")
            try connection.run(Schema.assets.create(ifNotExists: true) { t in
                t.column(Schema.relativeAssetPath, primaryKey: true)
                t.column(Schema.relativeSourcePath)
            })
            print("create the render status table...")
            try connection.run(Schema.renderStatus.create(ifNotExists: true) { t in
                t.column(Schema.url, primaryKey: true)
                t.column(Schema.details)
            })
        },
    ]

    static var schemaVersion: Int32 = Array(migrations.keys).max() ?? 0

    init(databaseURL: URL) throws {
        self.databaseURL = databaseURL
        self.connection = try Connection(databaseURL.path)
        try syncQueue.sync(flags: .barrier) {
            try self.syncQueue_migrate()
        }
    }

    private func run<T>(perform: @escaping () throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            syncQueue.async {
                let result = Swift.Result<T, Error> {
                    try Task.checkCancellation()
                    return try perform()
                }
                continuation.resume(with: result)
            }
        }
    }

    private func syncQueue_migrate() throws {
        dispatchPrecondition(condition: .onQueue(syncQueue))
        try connection.transaction {
            let currentVersion = connection.userVersion ?? 0
            print("version \(currentVersion)")
            guard currentVersion < Self.schemaVersion else {
                print("schema up to date")
                return
            }
            for version in currentVersion + 1 ... Self.schemaVersion {
                print("migrating to \(version)...")
                guard let migration = Self.migrations[version] else {
                    throw InContextError.unknownSchemaVersion(version)
                }
                try migration(self.connection)
                connection.userVersion = version
            }
        }
    }

    let iso8601DateForamtter: ISO8601DateFormatter = {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [
            .withInternetDateTime
        ]
        return dateFormatter
    }()

    private func transform(input: Any) -> Any {
        if let dictionary = input as? Dictionary<AnyHashable, Any> {
            return dictionary
                .map { key, value in
                    return (key, transform(input: value))
                }
                .reduce(into: Dictionary<AnyHashable, Any>()) { partialResult, item in
                    partialResult[item.0] = item.1
                }
        } else if let array = input as? Array<Any> {
            return array.map { item in
                return transform(input: item)
            }
        } else if let date = input as? Date {
            return iso8601DateForamtter.string(from: date)
        } else {
            return input
        }
    }

    private func untransform(input: Any) -> Any {
        if let dictionary = input as? Dictionary<AnyHashable, Any> {
            return dictionary
                .map { key, value in
                    return (key, untransform(input: value))
                }
                .reduce(into: Dictionary<AnyHashable, Any>()) { partialResult, item in
                    partialResult[item.0] = item.1
                }
        } else if let array = input as? Array<Any> {
            return array.map { item in
                return untransform(input: item)
            }
        } else if let string = input as? String {
            return iso8601DateForamtter.date(from: string) ?? input
        } else {
            return input
        }
    }

    private func syncQueue_save(document: Document?, assets: [Asset], status: Status) throws {
        dispatchPrecondition(condition: .onQueue(syncQueue))
        try connection.transaction {

            // Invalidate the caches.
            documentsCache.removeAll()
            fingerprintsCache.removeAll()

            // Write the document.
            if let document {

                // Serialise the metadata.
                let data = try JSONSerialization.data(withJSONObject: transform(input: document.metadata))
                guard let metadata = String(data: data, encoding: .utf8) else {
                    throw InContextError.encodingError
                }

                try connection.run(Schema.documents.insert(or: .replace,
                                                           Schema.url <- document.url,
                                                           Schema.parent <- document.parent,
                                                           Schema.category <- document.category,
                                                           Schema.date <- document.date,
                                                           Schema.title <- document.title,
                                                           Schema.metadata <- metadata,
                                                           Schema.contents <- document.contents,
                                                           Schema.contentModificationDate <- document.contentModificationDate.millisecondsSinceReferenceDate,
                                                           Schema.template <- document.template,
                                                           Schema.inlineTemplate <- document.inlineTemplate,
                                                           Schema.relativeSourcePath <- document.relativeSourcePath,
                                                           Schema.format <- document.format,
                                                           Schema.depth <- document.depth,
                                                           Schema.fingerprint <- document.fingerprint))
            }
            for asset in assets {
                try connection.run(Schema.assets.insert(or: .replace,
                                                        Schema.relativeAssetPath <- asset.relativePath,
                                                        Schema.relativeSourcePath <- status.relativePath))
            }
            try connection.run(Schema.status.insert(or: .replace,
                                                    Schema.relativePath <- status.relativePath,
                                                    Schema.contentModificationDate <- status.contentModificationDate.millisecondsSinceReferenceDate,
                                                    Schema.importer <- status.importer,
                                                    Schema.fingerprint <- status.fingerprint))
        }
    }

    private func syncQueue_status(for relativePath: String, contentURL: URL) throws -> Status? {
        dispatchPrecondition(condition: .onQueue(syncQueue))
        precondition(contentURL.hasDirectoryPath)
        guard let status = try connection.pluck(Schema.status.filter(Schema.relativePath == relativePath)) else {
            return nil
        }
        return Status(fileURL: URL(filePath: try status.get(Schema.relativePath), relativeTo: contentURL),
                      contentModificationDate: Date(millisecondsSinceReferenceDate: try status.get(Schema.contentModificationDate)),
                      importer: try status.get(Schema.importer),
                      fingerprint: try status.get(Schema.fingerprint))
    }

    private func syncQueue_assets(for relativePath: String, filesURL: URL) throws -> [Asset] {
        dispatchPrecondition(condition: .onQueue(syncQueue))
        precondition(filesURL.hasDirectoryPath)
        let rowIterator = try connection.prepareRowIterator(Schema.assets.filter(Schema.relativeSourcePath == relativePath))
        return try rowIterator.map { row in
            return Asset(fileURL: URL(filePath: try row.get(Schema.relativeAssetPath), relativeTo: filesURL))
        }
    }

    private func syncQueue_forgetAssets(for relativePath: String) throws {
        dispatchPrecondition(condition: .onQueue(syncQueue))
        try connection.run(Schema.assets
            .filter(Schema.relativeSourcePath == relativePath)
            .delete())
    }

    private func syncQueue_renderStatus(for url: String) throws -> RenderStatus? {
        dispatchPrecondition(condition: .onQueue(syncQueue))
        guard let renderStatus = try connection.pluck(Schema.renderStatus.filter(Schema.url == url)) else {
            return nil
        }
        let decoder = JSONDecoder()
        let data = try renderStatus.get(Schema.details)
        return try decoder.decode(RenderStatus.self, from: data)
    }

    private func syncQueue_renderStatuses() throws -> [(String, RenderStatus)] {
        dispatchPrecondition(condition: .onQueue(syncQueue))
        if !renderStatusCache.isEmpty {
            return renderStatusCache.items
        }
        let rowIterator = try connection.prepareRowIterator(Schema.renderStatus)
        let renderStatuses = try rowIterator.map { row in
            let decoder = JSONDecoder()
            return (row[Schema.url], try decoder.decode(RenderStatus.self, from: row[Schema.details]))
        }
        for item in renderStatuses {
            renderStatusCache[item.0] = item.1
        }
        return renderStatuses
    }

    private func syncQueue_save(renderStatus: RenderStatus, for url: String) throws {
        dispatchPrecondition(condition: .onQueue(syncQueue))
        try connection.transaction {
            let encoder = JSONEncoder()
            let renderStatus = try encoder.encode(renderStatus)
            try connection.run(Schema.renderStatus.insert(or: .replace,
                                                          Schema.url <- url,
                                                          Schema.details <- renderStatus))
        }
        renderStatusCache[url] = renderStatus
    }

    private func syncQueue_documents(query: QueryDescription) throws -> [Document] {
        dispatchPrecondition(condition: .onQueue(syncQueue))

        let rowIterator = try connection.prepareRowIterator(query.query())

        return try rowIterator.map { row in

            // Deserialize the metadata.
            let metadataString = row[Schema.metadata]
            guard let data = metadataString.data(using: .utf8),
                  let metadata = untransform(input: try JSONSerialization.jsonObject(with: data)) as? [AnyHashable: Any]
            else {
                throw InContextError.internalInconsistency("Failed to load document metadata.")
            }

            return Document(url: row[Schema.url],
                            parent: row[Schema.parent],
                            category: row[Schema.category],
                            date: row[Schema.date],
                            title: row[Schema.title],
                            metadata: metadata,
                            contents: row[Schema.contents],
                            contentModificationDate: Date(millisecondsSinceReferenceDate: row[Schema.contentModificationDate]),
                            template: row[Schema.template],
                            inlineTemplate: row[Schema.inlineTemplate],
                            relativeSourcePath: row[Schema.relativeSourcePath],
                            format: row[Schema.format],
                            depth: row[Schema.depth],
                            fingerprint: row[Schema.fingerprint])
        }
    }

    private func syncQueue_fingerprints(query: QueryDescription) throws -> [String] {
        dispatchPrecondition(condition: .onQueue(syncQueue))

        let select = query
            .query()
            .select(Schema.fingerprint)
        let rowIterator = try connection.prepareRowIterator(select)

        return try rowIterator.map { row in
            return row[Schema.fingerprint]
        }
    }

    private func syncQueue_documentRelativeSourcePaths() throws -> [String] {
        dispatchPrecondition(condition: .onQueue(syncQueue))
        let select = Schema
            .documents
            .select(Schema.relativeSourcePath)
        let rowIterator = try connection.prepareRowIterator(select)

        return try rowIterator.map { $0[Schema.relativeSourcePath] }
    }

    private func syncQueue_deleteDocuments(relativeSourcePaths: [String]) throws {
        dispatchPrecondition(condition: .onQueue(syncQueue))
        try connection.transaction {
            for relativeSourcePath in relativeSourcePaths {
                try connection.run(Schema.documents
                    .filter(Schema.relativeSourcePath == relativeSourcePath)
                    .delete())
            }
        }
    }

    func save(document: Document?, assets: [Asset], status: Status) async throws {
        try await run {
            try self.syncQueue_save(document: document, assets: assets, status: status)
        }
    }

    // TODO: Rename to relativeSourcePath
    func status(for relativePath: String, contentURL: URL) async throws -> Status? {
        return try await run {
            return try self.syncQueue_status(for: relativePath, contentURL: contentURL)
        }
    }

    // TODO: Rename to relativeSourcePath
    func assets(for relativePath: String, filesURL: URL) async throws -> [Asset] {
        return try await run {
            return try self.syncQueue_assets(for: relativePath, filesURL: filesURL)
        }
    }

    func forgetAssets(for relativePath: String) async throws {
        try await run {
            return try self.syncQueue_forgetAssets(for: relativePath)
        }
    }

    func save(renderStatus: RenderStatus, for url: String) async throws {
        try await run {
            try self.syncQueue_save(renderStatus: renderStatus, for: url)
        }
    }

    func renderStatuses() async throws -> [(String, RenderStatus)] {
        return try await run {
            return try self.syncQueue_renderStatuses()
        }
    }

    func documentRelativeSourcePaths() async throws -> [String] {
        return try await run {
            return try self.syncQueue_documentRelativeSourcePaths()
        }
    }

    func deleteDocuments(relativeSourcePaths: [String]) async throws {
        return try await run {
            try self.syncQueue_deleteDocuments(relativeSourcePaths: relativeSourcePaths)
        }
    }

    func documents(query: QueryDescription = QueryDescription()) throws -> [Document] {
        dispatchPrecondition(condition: .notOnQueue(syncQueue))
        return try syncQueue.sync {
            if let documents = documentsCache[query] {
                return documents
            }
            let documents = try syncQueue_documents(query: query)
            documentsCache[query] = documents
            return documents
        }
    }

    // TODO: This can actually be async.
    func fingerprints(query: QueryDescription) throws -> [String] {
        dispatchPrecondition(condition: .notOnQueue(syncQueue))
        return try syncQueue.sync {
            if let fingerprints = fingerprintsCache[query] {
                return fingerprints
            }
            let fingerprints = try syncQueue_fingerprints(query: query)
            fingerprintsCache[query] = fingerprints
            return fingerprints
        }
    }

}
