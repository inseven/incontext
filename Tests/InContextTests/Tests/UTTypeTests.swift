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
            case .png:
                XCTAssertEqual(fileType.preferredMIMEType, "image/png")
            case .quickTimeMovie:
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
            case .png:
                XCTAssertEqual(fileType.preferredFilenameExtension, "png")
            case .quickTimeMovie:
                XCTAssertEqual(fileType.preferredFilenameExtension, "mov")
            case .tiff:
                XCTAssertEqual(fileType.preferredFilenameExtension, "tiff")
            }
        }
    }

    func testFilenameExtensions() {
        for filenameExtension in FileType.Extension.allCases {
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
                XCTAssertEqual(FileType(filenameExtension: filenameExtension.rawValue), .quickTimeMovie)
            case .png:
                XCTAssertEqual(FileType(filenameExtension: filenameExtension.rawValue), .png)
            case .tiff:
                XCTAssertEqual(FileType(filenameExtension: filenameExtension.rawValue), .tiff)
            }
        }

    }

    func testPreferredExtensionRoundTrip() {
        for type in FileType.allCases {
            XCTAssertEqual(FileType(filenameExtension: type.preferredFilenameExtension), type)
        }
    }

}
