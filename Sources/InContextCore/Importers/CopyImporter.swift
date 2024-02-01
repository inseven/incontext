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

class CopyImporter: Importer {

    typealias Settings = EmptySettings

    let identifier = "copy"
    let version = 1

    func settings(for configuration: [String : Any]) throws -> EmptySettings {
        guard configuration.isEmpty else {
            throw InContextError.unexpecteArgs
        }
        return EmptySettings()
    }

    func process(file: File,
                 settings: Settings,
                 outputURL: URL) async throws -> ImporterResult {
        // TODO: Consider whether these actually get a tracking context that lets them add to the site instead of
        //       returning documents. That feels like it might be cleaner and more flexible?
        //       That approach would have the benefit of meaning that we don't really need to do significant path
        //       manipulation.
        let destinationURL = URL(filePath: file.relativePath, relativeTo: outputURL)
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: destinationURL.deletingLastPathComponent(),
                                        withIntermediateDirectories: true)

        // TODO: This shouldn't really be necessary.
        if fileManager.fileExists(atPath: destinationURL.path) {
            print("Cleaning up orphaned file at '\(destinationURL.relativePath)'...")
            try fileManager.removeItem(at: destinationURL)
        }

        try fileManager.copyItem(at: file.url, to: destinationURL)
        return ImporterResult(assets: [Asset(fileURL: destinationURL)])
    }

}
