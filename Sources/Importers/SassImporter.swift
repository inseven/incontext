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

import DartSass

class SassImporter: Importer {

    struct Settings: ImporterSettings {
        let path: String
    }

    let identifier = "preprocess_stylesheet"
    let version = 9

    func settings(for configuration: [String : Any]) throws -> Settings {
        let args: [String: Any] = try configuration.requiredValue(for: "args")
        return Settings(path: try args.requiredValue(for: "path"))
    }

    func process(site: Site, file: File, settings: Settings) async throws -> ImporterResult {
        let inputURL = URL(filePath: settings.path, relativeTo: site.contentURL)
        let outputURL = site.outputURL(relativePath: inputURL.deletingPathExtension().relativePath + ".css")
        let compiler = try Compiler()
        let results = try await compiler.compile(fileURL: inputURL)
        try await compiler.shutdownGracefully()
        try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        try results.css.write(to: outputURL, atomically: true, encoding: .utf8)
        return ImporterResult(assets: [Asset(fileURL: outputURL)])
    }

}
