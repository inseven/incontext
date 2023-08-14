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
import RegexBuilder

struct Handler<T: Importer> {

    let rulesVersion = 1

    let when: Regex<AnyRegexOutput>
    let whenSource: String
    let importer: T
    let settings: T.Settings

    init(when: String, importer: T, settings: T.Settings) throws {
        self.when = try Regex("^" + when + "$").ignoresCase()
        self.whenSource = when
        self.importer = importer
        self.settings = settings
    }

}

extension Handler: Fingerprintable {

    func combine(into fingerprint: inout Fingerprint) throws {
        try fingerprint.update(rulesVersion)
        try fingerprint.update(importer.identifier)
        try fingerprint.update(importer.version)
        try fingerprint.update(settings)
    }

    var version: Int {
        return importer.version
    }

    var identifier: String {
        return importer.identifier
    }

    func matches(relativePath: String) throws -> Bool {
        return try when.wholeMatch(in: relativePath) != nil
    }

    func process(file: File, outputURL: URL) async throws -> ImporterResult {
        return try await importer.process(file: file, settings: settings, outputURL: outputURL)
    }

}
