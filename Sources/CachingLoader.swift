//
//  File 2.swift
//  
//
//  Created by Jason Barrie Morley on 26/07/2023.
//

import Foundation

import Stencil

// TODO: Perhaps inject the template _content_ loader into this first so it doesnt parse the templates that aren't needed?
//       That would allow us to make this all guaranteed thread safe too which would be nice.
class CachingLoader: Loader {

    let rootURL: URL
    var cache: [String: (Template, Date)] = [:]

    init(rootURL: URL) {
        precondition(rootURL.hasDirectoryPath)
        self.rootURL = rootURL

    }

    func load(environment: Environment) async throws {
        let fileManager = FileManager.default
        let resourceKeys = Set<URLResourceKey>([.nameKey, .isDirectoryKey, .contentModificationDateKey])
        let directoryEnumerator = fileManager.enumerator(at: rootURL,
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

                    guard !isDirectory else {
                        continue
                    }

                    let name = fileURL.relativePath
                    // TODO: Debug logging
//                    print("Loading '\(name)'...")
                    let contents = try String(contentsOf: fileURL, encoding: .utf8)
                    let template = try Template(templateString: contents, environment: environment, name: name)
                    cache[name] = (template, contentModificationDate)
                }
            }
        }
        print("Template load took \(duration).")
    }

    func contentModificationTime(for name: String) -> Date? {
        return cache[name]?.1
    }

    func loadTemplate(name: String, environment: Stencil.Environment) throws -> Template {
        guard let details = cache[name] else {
            throw InContextError.unknown
        }
        return details.0
    }

}
