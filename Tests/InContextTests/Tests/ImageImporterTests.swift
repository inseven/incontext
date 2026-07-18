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

class ImageImporterTests: XCTestCase {

    func testExtractTitle() async throws {
        try await withTemporarySourceDirectory { sourceDirectory in
            let file = try sourceDirectory.copy(try bundle.throwingURL(forResource: "IMG_0581", withExtension: "jpeg"),
                                                to: "image.jpeg",
                                                location: .content)
            let result = try await ImageImporter.process(file: file,
                                                         settings: imageSettings(),
                                                         outputURL: sourceDirectory.filesURL)
            XCTAssertNotNil(result.document)
            XCTAssertEqual(result.document?.title, "Hallgrímskirkja Church")
        }
    }

    func testResizeGif() async throws {
        try await withTemporarySourceDirectory { sourceDirectory in
            let file = try sourceDirectory.copy(try bundle.throwingURL(forResource: "nezumi_anim", withExtension: "gif"),
                                                to: "nezumi_anim.gif",
                                                location: .content)
            let result = try await ImageImporter.process(file: file,
                                                         settings: imageSettings(),
                                                         outputURL: sourceDirectory.filesURL)
            XCTAssertNotNil(result.document)
            let thumbnailURL = sourceDirectory.filesURL
                .appendingPathComponent("nezumi_anim")
                .appendingPathComponent("1600.gif")
            XCTAssert(FileManager.default.fileExists(at: sourceDirectory.filesURL
                .appendingPathComponent("nezumi_anim")))
            XCTAssert(FileManager.default.fileExists(at: thumbnailURL))

            // Check the number of frames in the image.
            let thumbnail = try await NativeImage(url: thumbnailURL)
            XCTAssertEqual(thumbnail.frameCount, 14)
        }
    }

    func testExtractLocation() async throws {
        try await withTemporarySourceDirectory { sourceDirectory in
            let file = try sourceDirectory.copy(try bundle.throwingURL(forResource: "IMG_0581", withExtension: "jpeg"),
                                                to: "image.jpeg",
                                                location: .content)
            let result = try await ImageImporter.process(file: file,
                                                         settings: imageSettings(),
                                                         outputURL: sourceDirectory.filesURL)
            let location = try XCTUnwrap(result.document?.metadata["location"] as? [String: Double])
            XCTAssertEqual(try XCTUnwrap(location["latitude"]), 64.142272166666672, accuracy: 0.0001)
            XCTAssertEqual(try XCTUnwrap(location["longitude"]), -21.927391666666665, accuracy: 0.0001)
        }
    }

    private func imageSettings(titleFromFilename: Bool = false) -> ImageImporter.Settings {
        return ImageImporter.Settings(defaultCategory: "photos",
                                      titleFromFilename: titleFromFilename,
                                      defaultTemplate: "photo.html",
                                      inlineTemplate: "image.html")
    }

    func testFrontmatterTitleOverridesMetadataTitle() async throws {
        try await withTemporarySourceDirectory { sourceDirectory in
            let file = try sourceDirectory.add("image.jpeg", location: .content, contents: "")
            let image = TestPlatformImage(title: "Metadata Title",
                                          mediaDescription: """
---
title: Frontmatter Title
---
""")
            let result = try await ImageImporter.process(file: file,
                                                         settings: imageSettings(),
                                                         outputURL: sourceDirectory.filesURL,
                                                         image: image)
            XCTAssertEqual(result.document?.title, "Frontmatter Title")
        }
    }

    func testMetadataTitleUsedWhenFrontmatterHasNoTitle() async throws {
        try await withTemporarySourceDirectory { sourceDirectory in
            let file = try sourceDirectory.add("image.jpeg", location: .content, contents: "")
            let image = TestPlatformImage(title: "Metadata Title",
                                          mediaDescription: "A plain caption with no frontmatter.")
            let result = try await ImageImporter.process(file: file,
                                                         settings: imageSettings(),
                                                         outputURL: sourceDirectory.filesURL,
                                                         image: image)
            XCTAssertEqual(result.document?.title, "Metadata Title")
        }
    }

    func testFrontmatterDateOverridesMetadataDate() async throws {
        try await withTemporarySourceDirectory { sourceDirectory in
            let file = try sourceDirectory.add("image.jpeg", location: .content, contents: "")
            let image = TestPlatformImage(dateTimeOriginal: Date(2001, 10, 02, 01, 54, 02),
                                          mediaDescription: """
---
date: '2020-05-04 12:00:00 +00:00'
---
""")
            let result = try await ImageImporter.process(file: file,
                                                         settings: imageSettings(),
                                                         outputURL: sourceDirectory.filesURL,
                                                         image: image)
            XCTAssertEqual(result.document?.date, Date(2020, 05, 04, 12, 00, 00))
        }
    }

    func testFrontmatterLocationOverridesMetadataLocation() async throws {
        try await withTemporarySourceDirectory { sourceDirectory in
            let file = try sourceDirectory.add("image.jpeg", location: .content, contents: "")
            let image = TestPlatformImage(mediaDescription: """
---
location:
  latitude: 1.5
  longitude: 2.5
---
""",
                                          signedLatitude: 64.0,
                                          signedLongitude: -21.0)
            let result = try await ImageImporter.process(file: file,
                                                         settings: imageSettings(),
                                                         outputURL: sourceDirectory.filesURL,
                                                         image: image)
            let location = try XCTUnwrap(result.document?.metadata["location"] as? [AnyHashable: Any])
            XCTAssertEqual(location["latitude"] as? Double, 1.5)
            XCTAssertEqual(location["longitude"] as? Double, 2.5)
        }
    }

    func testFrontmatterInjectsCustomMetadata() async throws {
        try await withTemporarySourceDirectory { sourceDirectory in
            let file = try sourceDirectory.add("image.jpeg", location: .content, contents: "")
            let image = TestPlatformImage(mediaDescription: """
---
photographer: Jane Doe
---
""")
            let result = try await ImageImporter.process(file: file,
                                                         settings: imageSettings(),
                                                         outputURL: sourceDirectory.filesURL,
                                                         image: image)
            XCTAssertEqual(result.document?.metadata["photographer"] as? String, "Jane Doe")
        }
    }

    func testRespectsUppercaseExtensions() async throws {
        // The current hard-coded image transform pipeline converts TIFFs to JPEGs. Before introducing file extension
        // case normalization in `FileType`, this was failing on case-sensitive file systems for files with uppercase
        // extensions. This test will need revisiting when we switch to a user-configurable transform pipeline.
        try await withTemporarySourceDirectory { sourceDirectory in
            let file = try sourceDirectory.copy(try bundle.throwingURL(forResource: "IMG_0581", withExtension: "heic"),
                                                to: "IMG_0581.HEIC",
                                                location: .content)
            let result = try await ImageImporter.process(file: file,
                                                         settings: imageSettings(),
                                                         outputURL: sourceDirectory.filesURL)
            XCTAssertNotNil(result.document)
            let imageURL = sourceDirectory.filesURL
                .appendingPathComponent("IMG_0581")
                .appendingPathComponent("1600.jpeg")
            XCTAssert(FileManager.default.fileExists(at: imageURL))
        }
    }

}
