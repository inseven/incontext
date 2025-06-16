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

import XCTest
@testable import InContextCore

// #if !os(Linux)

class ImageImporterTests: ContentTestCase {

    func testExtractTitle() async throws {
        _ = try defaultSourceDirectory.add("site.yaml", contents: """
version: 2
title: Example
url: http://example.com
steps:
  - when: '(.*/)?.*\\.jpeg'
    then: image
    args:
        category: general
        defaultTemplate: photo.html
        inlineTemplate: image.html
        titleFromFilename: false
""")


        // TODO: It shouldn't be necessary to pass the site into the importer.
        let file = try defaultSourceDirectory.copy(try bundle.throwingURL(forResource: "IMG_0581", withExtension: "jpeg"),
                                                   to: "image.jpeg",
                                                   location: .content)
        let importer = ImageImporter()
        let settings =  ImageImporter.Settings(defaultCategory: "photos",
                                               titleFromFilename: false,
                                               defaultTemplate: "photo.html",
                                               inlineTemplate: "image.html")
        let result = try await importer.process(file: file,
                                                settings: settings,
                                                outputURL: defaultSourceDirectory.site.filesURL)
        XCTAssertNotNil(result.document)
        XCTAssertEqual(result.document?.title, "Hallgrímskirkja Church")
    }

    func testResizeGif() async throws {
        _ = try defaultSourceDirectory.add("site.yaml", contents: """
version: 2
title: Example
url: http://example.com
steps:
  - when: '(.*/)?.*\\.gif'
    then: image
    args:
        category: general
        defaultTemplate: photo.html
        inlineTemplate: image.html
        titleFromFilename: false
""")


        // TODO: It shouldn't be necessary to pass the site into the importer.
        let file = try defaultSourceDirectory.copy(try bundle.throwingURL(forResource: "nezumi_anim", withExtension: "gif"),
                                                   to: "nezumi_anim.gif",
                                                   location: .content)
        let importer = ImageImporter()
        let settings =  ImageImporter.Settings(defaultCategory: "photos",
                                               titleFromFilename: false,
                                               defaultTemplate: "photo.html",
                                               inlineTemplate: "image.html")
        let result = try await importer.process(file: file,
                                                settings: settings,
                                                outputURL: defaultSourceDirectory.site.filesURL)
        XCTAssertNotNil(result.document)
//        XCTAssertEqual(result.document?.title, "Hallgrímskirkja Church")
        XCTAssert(FileManager.default.fileExists(at: defaultSourceDirectory.site.filesURL
            .appendingPathComponent("nezumi_anim")))
        XCTAssert(FileManager.default.fileExists(at: defaultSourceDirectory.site.filesURL
            .appendingPathComponent("nezumi_anim")
            .appendingPathComponent("1600", conformingTo: .gif)))

        // Check the number of frames in the image.
        guard let imageSource = CGImageSourceCreateWithURL(defaultSourceDirectory.site.filesURL
            .appendingPathComponent("nezumi_anim")
            .appendingPathComponent("1600", conformingTo: .gif) as CFURL, nil) else {
            fatalError("Failed to create image source")
        }

        XCTAssertEqual(CGImageSourceGetCount(imageSource), 14)
    }

}

// #endif
