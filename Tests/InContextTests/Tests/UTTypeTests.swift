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

import XCTest
@testable import InContextCore

import PlatformSupport

enum FileType: String, CaseIterable {
    case gif = "image/gif"
    case heic = "image/heic"
    case html = "text/html"
    case jpeg = "image/jpeg"
    case markdown = "text/markdown"
    case quickTimeVideo = "video/quicktime"
    case tiff = "image/tiff"
}

extension FileType {

    // TODO: Rename to Extension
    // TODO: Make this private again.
    fileprivate enum FilenameExtension: String, CaseIterable {
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
    }

    private static func extensions(for fileType: FileType) -> [FilenameExtension] {
        switch fileType {
        case .gif:
            return [.gif]
        case .heic:
            return [.heic]
        case .html:
            return [.html, .htm]
        case .jpeg:
            return [.jpeg, .jpg]
        case .markdown:
            return [.md, .markdown]
        case .quickTimeVideo:
            return [.mov]
        case .tiff:
            return [.tiff, .html]
        }
    }

    // Construct a lookup table from extension to type.
    // This is designed to crash if we don't provide a mapping for all file extensions or there are duplicate mappings.
    private static let extensionToMIMEType: [String: String] = {
        let mapping = FileType.allCases.reduce(into: [String: String]()) { partialResult, fileType in
            for filenameExtension in extensions(for: fileType) {
                precondition(partialResult[filenameExtension.rawValue] == nil)
                partialResult[filenameExtension.rawValue] = fileType.rawValue
            }
        }
        precondition(Set(mapping.keys) == Set(FilenameExtension.allCases.map({ $0.rawValue })))
        return mapping
    }()

    // Construct a lookup table from type to extension.
    // This is designed to crash if we don't provide at least one mapping for each file type.
    private static let extensionToPreferredFilename: [String: String] = {
        return FileType.allCases.reduce(into: [String: String]()) { partialResult, fileType in
            partialResult[fileType.rawValue] = extensions(for: fileType).first!.rawValue
        }
    }()

    var preferredFilenameExtension: String? {
        return Self.extensionToPreferredFilename[self.rawValue]
    }

    var preferredMIMEType: String? {
        return self.rawValue
    }

    init?(mimeType: String) {
        self.init(rawValue: mimeType.lowercased())
    }

    init?(filenameExtension: String) {
        guard let mimeType = Self.extensionToMIMEType[filenameExtension.lowercased()] else {
            return nil
        }
        self.init(mimeType: mimeType)
    }

}

class FileTypeTests: XCTestCase {

    func testFileTypeCaseSensitivity() {
        let heicUpper = FileType(filenameExtension: "HEIC")
        let heicLower = FileType(filenameExtension: "heic")
        XCTAssertNotNil(heicUpper)
        XCTAssertNotNil(heicLower)
        XCTAssertEqual(heicUpper, heicLower)
    }

    func testMultipleExtensions() {
        let jpeg = FileType(filenameExtension: "jpeg")
        let jpg = FileType(filenameExtension: "jpg")
        XCTAssertNotNil(jpeg)
        XCTAssertNotNil(jpg)
        XCTAssertEqual(jpeg, jpg)
    }

    func testPreferredMIMEType() {
        for fileType in FileType.allCases {
            switch fileType {
            case .gif:
                XCTAssertEqual(fileType.preferredMIMEType, "image/gif")
            case .heic:
                XCTAssertEqual(fileType.preferredMIMEType, "image/heic")
            case .html:
                XCTAssertEqual(fileType.preferredMIMEType, "text/html")
            case .jpeg:
                XCTAssertEqual(fileType.preferredMIMEType, "image/jpeg")
            case .markdown:
                XCTAssertEqual(fileType.preferredMIMEType, "text/markdown")
            case .quickTimeVideo:
                XCTAssertEqual(fileType.preferredMIMEType, "video/quicktime")
            case .tiff:
                XCTAssertEqual(fileType.preferredMIMEType, "image/tiff")
            }
        }
    }

    func testPreferredFilenameExtension() {
        for fileType in FileType.allCases {
            switch fileType {
            case .gif:
                XCTAssertEqual(fileType.preferredFilenameExtension, "gif")
            case .heic:
                XCTAssertEqual(fileType.preferredFilenameExtension, "heic")
            case .html:
                XCTAssertEqual(fileType.preferredFilenameExtension, "html")
            case .jpeg:
                XCTAssertEqual(fileType.preferredFilenameExtension, "jpeg")
            case .markdown:
                XCTAssertEqual(fileType.preferredFilenameExtension, "md")
            case .quickTimeVideo:
                XCTAssertEqual(fileType.preferredFilenameExtension, "mov")
            case .tiff:
                XCTAssertEqual(fileType.preferredFilenameExtension, "tiff")
            }
        }
    }

    func testFilenameExtensions() {
        for filenameExtension in FileType.FilenameExtension.allCases {
            switch filenameExtension {
            case .gif:
                XCTAssertEqual(FileType(filenameExtension: filenameExtension.rawValue), .gif)
            case .heic:
                XCTAssertEqual(FileType(filenameExtension: filenameExtension.rawValue), .heic)
            case .htm:
                XCTAssertEqual(FileType(filenameExtension: filenameExtension.rawValue), .html)
            case .html:
                XCTAssertEqual(FileType(filenameExtension: filenameExtension.rawValue), .html)
            case .jpeg:
                XCTAssertEqual(FileType(filenameExtension: filenameExtension.rawValue), .jpeg)
            case .jpg:
                XCTAssertEqual(FileType(filenameExtension: filenameExtension.rawValue), .jpeg)
            case .markdown:
                XCTAssertEqual(FileType(filenameExtension: filenameExtension.rawValue), .markdown)
            case .md:
                XCTAssertEqual(FileType(filenameExtension: filenameExtension.rawValue), .markdown)
            case .mov:
                XCTAssertEqual(FileType(filenameExtension: filenameExtension.rawValue), .quickTimeVideo)
            case .tiff:
                XCTAssertEqual(FileType(filenameExtension: filenameExtension.rawValue), .tiff)
            }
        }

    }

}
