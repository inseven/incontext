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

import PlatformSupport

extension String {

    private static let schemeRegex = /[a-z]+:/.ignoresCase()

    func ensuringTrailingSlash() -> String {
        return hasSuffix("/") ? self : self + "/"
    }

    func ensuringLeadingSlash() -> String {
        return hasPrefix("/") ? self : "/" + self
    }

    func wrapped(by prefix: String, and suffix: String) -> String {
        return prefix + self + suffix
    }

    func safeIdentifier() -> String? {
        return lowercased()
            .replacing(/\s+/, with: "-")
    }

    func html() -> String {
        return Hoedown.render(
            markdown: self,
            extensions: [
                .footnotes,
                .fencedCode,
                .tables,
                .strikethrough,
                .highlight,
            ]) ?? ""
    }

    var hasScheme: Bool {
        get throws {
            return try Self.schemeRegex.prefixMatch(in: self) != nil
        }
    }

    var deletingLastPathComponent: String? {
        guard self != "/" else {
            return nil
        }
        return (self as NSString).deletingLastPathComponent
    }

    private static let rootURL = URL(filePath: "/")

    /// The file-system path depth as given by the components in the path.
    var pathDepth: Int {
        let url = URL(filePath: self, relativeTo: Self.rootURL)
        return url.pathComponents.count - 1
    }

    var pathExtension: String {
        return URL(filePath: self).pathExtension
    }

    var type: UTType? {
        return UTType(filenameExtension: pathExtension)
    }

}

extension String: Fingerprintable {

    func combine(into fingerprint: inout Fingerprint) throws {
        try fingerprint.update(self)
    }

}
