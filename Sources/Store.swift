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

struct Status {

    var relativePath: String {
        return fileURL.relativePath
    }

    let fileURL: URL
    let contentModificationDate: Date
    let importer: String
    let importerVersion: Int

}

class Store {

    struct Schema {

        static let documents = Table("documents")
        static let status = Table("status")

        // documents
        static let url = Expression<String>("url")
        static let parent = Expression<String>("parent")
        static let type = Expression<String>("type")
        static let date = Expression<Date?>("date")
        static let metadata = Expression<String>("metadata")
        static let contents = Expression<String>("contents")
        static let template = Expression<String>("template")

        // status
        static let relativePath = Expression<String>("relative_path")
        static let contentModificationDate = Expression<Date>("content_modification_date")
        static let importer = Expression<String>("importer")
        static let importerVersion = Expression<Int>("importer_version")

    }

    let databaseURL: URL
    let syncQueue = DispatchQueue(label: "Store.syncQueue")
    let connection: Connection

    static var migrations: [Int32: (Connection) throws -> Void] = [
        1: { connection in
            print("create the items table...")
            try connection.run(Schema.documents.create(ifNotExists: true) { t in
                t.column(Schema.url, primaryKey: true)
                t.column(Schema.parent)
                t.column(Schema.type)
                t.column(Schema.date)
                t.column(Schema.metadata)
                t.column(Schema.contents)
                t.column(Schema.template)
            })
            try connection.run(Schema.status.create(ifNotExists: true) { t in
                t.column(Schema.relativePath, primaryKey: true)
                t.column(Schema.contentModificationDate)
                t.column(Schema.importer)
                t.column(Schema.importerVersion)
            })
        },
    ]

    static var schemaVersion: Int32 = Array(migrations.keys).max() ?? 0

    init(databaseURL: URL) throws {
        self.databaseURL = databaseURL
        self.connection = try Connection(databaseURL.path)
        try syncQueue.sync {
            try self.syncQueue_migrate()
        }
    }

    private func run<T>(operation: @escaping () throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            syncQueue.async {
                let result = Swift.Result<T, Error> {
                    try Task.checkCancellation()
                    return try operation()
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

    private func syncQueue_save(documents: [Document], status: Status) throws {
        dispatchPrecondition(condition: .onQueue(syncQueue))
        try connection.transaction {
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
                                                           Schema.template <- document.template))
            }
            try connection.run(Schema.status.insert(or: .replace,
                                                    Schema.relativePath <- status.relativePath,
                                                    Schema.contentModificationDate <- status.contentModificationDate,
                                                    Schema.importer <- status.importer,
                                                    Schema.importerVersion <- status.importerVersion))
        }
    }

    private func syncQueue_status(for relativePath: String) throws -> Status? {
        dispatchPrecondition(condition: .onQueue(syncQueue))
        guard let status = try connection.pluck(Schema.status.filter(Schema.relativePath == relativePath)) else {
            return nil
        }
        return Status(fileURL: URL(filePath: try status.get(Schema.relativePath), relativeTo: site.contentURL),
                      contentModificationDate: try status.get(Schema.contentModificationDate),
                      importer: try status.get(Schema.importer),
                      importerVersion: try status.get(Schema.importerVersion))
    }

    private func syncQueue_documents() throws -> [Document] {
        dispatchPrecondition(condition: .onQueue(syncQueue))
        let rowIterator = try connection.prepareRowIterator(Schema.documents)
        return try rowIterator.map { row in
            return Document(url: row[Schema.url],
                            parent: row[Schema.parent],
                            type: row[Schema.type],
                            date: row[Schema.date],
                            metadata: [:],  // TODO!
                            contents: row[Schema.contents],
                            mtime: Date(),  // TODO!
                            template: row[Schema.template])
        }
    }

    func save(documents: [Document], for status: Status) async throws {
        try await run {
            try self.syncQueue_save(documents: documents, status: status)
        }
    }

    func status(for relativePath: String) async throws -> Status? {
        return try await run {
            return try self.syncQueue_status(for: relativePath)
        }
    }

    func documents() async throws -> [Document] {
        return try await run {
            return try self.syncQueue_documents()
        }
    }

}
