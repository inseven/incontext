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

import SQLite

class Store: Queryable {

    struct Schema {

        static let documents = Table("documents")
        static let status = Table("status")
        static let assets = Table("assets")
        static let renderStatus = Table("render_status")

        // common
        static let url = Expression<String>("url")
        static let contentModificationDate = Expression<Date>("content_modification_date")

        // documents
        static let parent = Expression<String>("parent")
        static let type = Expression<String>("type")
        static let date = Expression<Date?>("date")
        static let metadata = Expression<String>("metadata")
        static let contents = Expression<String>("contents")
        static let template = Expression<String>("template")

        // status
        static let relativePath = Expression<String>("relative_path")  // TODO: This should be relative source path
        static let importer = Expression<String>("importer")
        static let fingerprint = Expression<String>("fingerprint")

        // assets
        static let relativeAssetPath = Expression<String>("relative_asset_path")
        static let relativeSourcePath = Expression<String>("relative_source_path")

        // render status
        static let details = Expression<String>("details")

    }

    enum Operation {
        case read
        case write
    }

    static let isMultiThreaded = false

    let databaseURL: URL
    let workQueue = DispatchQueue(label: "Store.workQueue", attributes: isMultiThreaded ? .concurrent : [])
    let connection: Connection
    let documentsCache = Cache<QueryDescription, [Document]>()
    let contentModificationDatesCache = Cache<QueryDescription, [Date]>()

    static var migrations: [Int32: (Connection) throws -> Void] = [
        1: { connection in
            print("create the documents table...")
            try connection.run(Schema.documents.create(ifNotExists: true) { t in
                t.column(Schema.url, primaryKey: true)
                t.column(Schema.parent)
                t.column(Schema.type)
                t.column(Schema.date)
                t.column(Schema.metadata)
                t.column(Schema.contents)
                t.column(Schema.contentModificationDate)
                t.column(Schema.template)
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
        try workQueue.sync(flags: .barrier) {
            try self.syncQueue_migrate()
        }
    }

    private func run<T>(_ operation: Operation = .read, perform: @escaping () throws -> T) async throws -> T {
        let flags: DispatchWorkItemFlags
        switch operation {
        case .read:
            flags = .barrier
        case .write:
            flags = .barrier
        }
        return try await withCheckedThrowingContinuation { continuation in
            workQueue.async(flags: flags) {
                let result = Swift.Result<T, Error> {
                    try Task.checkCancellation()
                    return try perform()
                }
                continuation.resume(with: result)
            }
        }
    }

    private func syncQueue_migrate() throws {
        dispatchPrecondition(condition: .onQueue(workQueue))
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

    private func syncQueue_save(documents: [Document], assets: [Asset], status: Status) throws {
        dispatchPrecondition(condition: .onQueue(workQueue))
        try connection.transaction {

            // Invalidate the caches.
            documentsCache.removeAll()
            contentModificationDatesCache.removeAll()

            // Write the documents.
            for document in documents {

                // Serialise the metadata.
                let data = try JSONSerialization.data(withJSONObject: document.metadata)
                guard let metadata = String(data: data, encoding: .utf8) else {
                    // TODO: Better error.
                    throw InContextError.unknown
                }

                try connection.run(Schema.documents.insert(or: .replace,
                                                           Schema.url <- document.url,
                                                           Schema.parent <- document.parent,
                                                           Schema.type <- document.type,
                                                           Schema.date <- document.date,
                                                           Schema.metadata <- metadata,
                                                           Schema.contents <- document.contents,
                                                           Schema.contentModificationDate <- document.contentModificationDate,
                                                           Schema.template <- document.template))
            }
            for asset in assets {
                try connection.run(Schema.assets.insert(or: .replace,
                                                        Schema.relativeAssetPath <- asset.relativePath,
                                                        Schema.relativeSourcePath <- status.relativePath))
            }
            try connection.run(Schema.status.insert(or: .replace,
                                                    Schema.relativePath <- status.relativePath,
                                                    Schema.contentModificationDate <- status.contentModificationDate,
                                                    Schema.importer <- status.importer,
                                                    Schema.fingerprint <- status.fingerprint))
        }
    }

    private func syncQueue_status(for relativePath: String) throws -> Status? {
        dispatchPrecondition(condition: .onQueue(workQueue))
        guard let status = try connection.pluck(Schema.status.filter(Schema.relativePath == relativePath)) else {
            return nil
        }
        return Status(fileURL: URL(filePath: try status.get(Schema.relativePath), relativeTo: site.contentURL),
                      contentModificationDate: try status.get(Schema.contentModificationDate),
                      importer: try status.get(Schema.importer),
                      fingerprint: try status.get(Schema.fingerprint))
    }

    private func syncQueue_assets(for relativePath: String) throws -> [Asset] {
        dispatchPrecondition(condition: .onQueue(workQueue))
        let rowIterator = try connection.prepareRowIterator(Schema.assets.filter(Schema.relativeSourcePath == relativePath))
        return try rowIterator.map { row in
            return Asset(fileURL: URL(filePath: try row.get(Schema.relativeAssetPath), relativeTo: site.filesURL))
        }
    }

    private func syncQueue_forgetAssets(for relativePath: String) throws {
        dispatchPrecondition(condition: .onQueue(workQueue))
        try connection.run(Schema.assets
            .filter(Schema.relativeSourcePath == relativePath)
            .delete())
    }

    private func syncQueue_renderStatus(for url: String) throws -> RenderStatus? {
        dispatchPrecondition(condition: .onQueue(workQueue))
        guard let renderStatus = try connection.pluck(Schema.renderStatus.filter(Schema.url == url)) else {
            return nil
        }
        // TODO: Check to see if this is costly to construct
        let decoder = JSONDecoder()
        guard let data = try renderStatus.get(Schema.details).data(using: .utf8) else {
            throw InContextError.unknown
        }
        return try decoder.decode(RenderStatus.self, from: data)
    }

    private func syncQueue_renderStatuses() throws -> [(String, RenderStatus)] {
        dispatchPrecondition(condition: .onQueue(workQueue))
        let rowIterator = try connection.prepareRowIterator(Schema.renderStatus)
        return try rowIterator.map { row in
            let decoder = JSONDecoder()
            guard let data = row[Schema.details].data(using: .utf8) else {
                throw InContextError.unknown
            }
            return (row[Schema.url], try decoder.decode(RenderStatus.self, from: data))
        }
    }

    private func syncQueue_save(renderStatus: RenderStatus, for url: String) throws {
        dispatchPrecondition(condition: .onQueue(workQueue))
        try connection.transaction {

            // TODO: Performance
            let encoder = JSONEncoder()
            let renderStatus = try encoder.encode(renderStatus)
            guard let string = String(data: renderStatus, encoding: .utf8) else {
                // TODO: Decent error
                throw InContextError.unknown
            }

            try connection.run(Schema.renderStatus.insert(or: .replace,
                                                          Schema.url <- url,
                                                          Schema.details <- string))
        }
    }

    private func syncQueue_documents(query: QueryDescription?) throws -> [Document] {
        dispatchPrecondition(condition: .onQueue(workQueue))

        let filter = query?.expression() ?? Expression<Bool>(value: true)

        let query = Schema.documents
            .filter(filter)
            .order(Schema.date.desc)
        let rowIterator = try connection.prepareRowIterator(query)

        return try rowIterator.map { row in

            // Deserialize the metadata.
            let metadataString = row[Schema.metadata]
            guard let data = metadataString.data(using: .utf8),
                  let metadata = try JSONSerialization.jsonObject(with: data) as? [AnyHashable: Any]
            else {
                throw InContextError.unknown
            }

            return Document(url: row[Schema.url],
                            parent: row[Schema.parent],
                            type: row[Schema.type],
                            date: row[Schema.date],
                            metadata: metadata,
                            contents: row[Schema.contents],
                            contentModificationDate: row[Schema.contentModificationDate],
                            template: row[Schema.template])
        }
    }

    private func syncQueue_contentModificationDates(query: QueryDescription?) throws -> [Date] {
        dispatchPrecondition(condition: .onQueue(workQueue))

        let filter = query?.expression() ?? Expression<Bool>(value: true)

        let query = Schema.documents
            .select(Schema.contentModificationDate)
            .filter(filter)
            .order(Schema.date.desc)  // TODO: Move the order into the query.
        let rowIterator = try connection.prepareRowIterator(query)

        return try rowIterator.map { row in
            return row[Schema.contentModificationDate]
        }
    }

    func save(documents: [Document], assets: [Asset], status: Status) async throws {
        try await run(.write) {
            try self.syncQueue_save(documents: documents, assets: assets, status: status)
        }
    }

    // TODO: Rename to relativeSourcePath
    func status(for relativePath: String) async throws -> Status? {
        return try await run {
            return try self.syncQueue_status(for: relativePath)
        }
    }

    // TODO: Rename to relativeSourcePath
    func assets(for relativePath: String) async throws -> [Asset] {
        return try await run {
            return try self.syncQueue_assets(for: relativePath)
        }
    }

    func forgetAssets(for relativePath: String) async throws {
        try await run(.write) {
            return try self.syncQueue_forgetAssets(for: relativePath)
        }
    }

    func documents() async throws -> [Document] {
        return try await run {
            return try self.syncQueue_documents(query: nil)
        }
    }

    func save(renderStatus: RenderStatus, for url: String) async throws {
        try await run(.write) {
            try self.syncQueue_save(renderStatus: renderStatus, for: url)
        }
    }

    func renderStatus(for url: String) async throws -> RenderStatus? {
        return try await run {
            return try self.syncQueue_renderStatus(for: url)
        }
    }

    func renderStatuses() async throws -> [(String, RenderStatus)] {
        return try await run {
            return try self.syncQueue_renderStatuses()
        }
    }

    func documents(query: QueryDescription) throws -> [Document] {
        // TODO: Cache results by query description?
        dispatchPrecondition(condition: .notOnQueue(workQueue))
        return try workQueue.sync {
            if let documents = documentsCache[query] {
                return documents
            }
            let documents = try syncQueue_documents(query: query)
            documentsCache[query] = documents
            return documents
        }
    }

    // TODO: This can actually be async.
    func contentModificationDates(query: QueryDescription) throws -> [Date] {
        dispatchPrecondition(condition: .notOnQueue(workQueue))
        return try workQueue.sync {
            if let contentModificationDates = contentModificationDatesCache[query] {
                return contentModificationDates
            }
            let contentModificationDates = try syncQueue_contentModificationDates(query: query)
            contentModificationDatesCache[query] = contentModificationDates
            return contentModificationDates
        }
    }

}
