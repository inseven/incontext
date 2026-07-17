// MIT License
//
// Copyright (c) 2016-2026 Jason Morley
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

enum FileType: String, CaseIterable {
    case gif = "image/gif"
    case heic = "image/heic"
    case html = "text/html"
    case jpeg = "image/jpeg"
    case markdown = "text/markdown"
    case quickTimeMovie = "video/quicktime"
    case tiff = "image/tiff"
}

extension FileType {

    internal enum Extension: String, CaseIterable {
        case gif
        case heic
        case htm
        case html
        case jpeg
        case jpg
        case markdown
        case md
        case mov
        case tiff

        var fileType: FileType {
            switch self {
            case .gif: .gif
            case .heic: .heic
            case .htm, .html: .html
            case .jpeg, .jpg: .jpeg
            case .markdown, .md: .markdown
            case .mov: .quickTimeMovie
            case .tiff: .tiff
            }
        }
    }

    var preferredFilenameExtension: String {
        func map(_ fileType: FileType) -> Extension {
            switch fileType {
            case .gif: .gif
            case .heic: .heic
            case .html: .html
            case .jpeg: .jpeg
            case .markdown: .md
            case .quickTimeMovie: .mov
            case .tiff: .tiff
            }
        }
        return map(self).rawValue
    }

    var preferredMIMEType: String {
        return self.rawValue
    }

    init?(mimeType: String) {
        self.init(rawValue: mimeType.lowercased())
    }

    init?(filenameExtension: String) {
        guard let filenameExtension = Extension(rawValue: filenameExtension.lowercased()) else {
            return nil
        }
        self = filenameExtension.fileType
    }

}

#if canImport(UniformTypeIdentifiers)

import UniformTypeIdentifiers

extension FileType {

    var identifier: String? {
        switch self {
        case .gif:
            return UTType.gif.identifier
        case .heic:
            return UTType.heic.identifier
        case .html:
            return nil
        case .jpeg:
            return UTType.jpeg.identifier
        case .markdown:
            return nil
        case .quickTimeMovie:
            return nil
        case .tiff:
            return UTType.tiff.identifier
        }
    }

}

#endif
