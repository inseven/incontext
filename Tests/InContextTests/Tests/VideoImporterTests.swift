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

class VideoImporterTests: ContentTestCase {

    func testExtractTitle() async throws {

        _ = try defaultSourceDirectory.add("site.yaml", contents: """
version: 2
title: Example
url: http://example.com
steps:
  - when: '(.*/)?.*\\.mov'
    then: video
    args:
        category: snapshots
        defaultTemplate: video.html
        inlineTemplate: video.html
        titleFromFilename: false
""")

        let video = try defaultSourceDirectory.copy(try bundle.throwingURL(forResource: "2022-05-31-17-55-03-royal-wave",
                                                                           withExtension: "mov"),
                                                    to: "2022-05-31-17-55-03-royal-wave.mov",
                                                    location: .content)

        let result = try await VideoImporter.process(file: video,
                                                     settings: VideoImporter.Settings(defaultCategory: "snapshots",
                                                                                      titleFromFilename: false,
                                                                                      defaultTemplate: "video.html",
                                                                                      inlineTemplate: "video.html"),
                                                     outputURL: defaultSourceDirectory.site.filesURL)
        XCTAssertEqual(result.document?.title, "Royal Wave")
    }

    func testExtractLocation() async throws {

        _ = try defaultSourceDirectory.add("site.yaml", contents: """
version: 2
title: Example
url: http://example.com
steps:
  - when: '(.*/)?.*\\.mov'
    then: video
    args:
        category: snapshots
        defaultTemplate: video.html
        inlineTemplate: video.html
        titleFromFilename: false
""")

        let video = try defaultSourceDirectory.copy(try bundle.throwingURL(forResource: "2022-05-31-17-55-03-royal-wave",
                                                                           withExtension: "mov"),
                                                    to: "2022-05-31-17-55-03-royal-wave.mov",
                                                    location: .content)

        let result = try await VideoImporter.process(file: video,
                                                     settings: VideoImporter.Settings(defaultCategory: "snapshots",
                                                                                      titleFromFilename: false,
                                                                                      defaultTemplate: "video.html",
                                                                                      inlineTemplate: "video.html"),
                                                     outputURL: defaultSourceDirectory.site.filesURL)
        let location = result.document?.metadata["location"] as? [String: Double]
        XCTAssertEqual(location?["latitude"], 51.5126)
        XCTAssertEqual(location?["longitude"], -0.1240)
    }

    private func configureSite(in sourceDirectory: SourceDirectory) throws {
        _ = try sourceDirectory.add("site.yaml", contents: """
version: 2
title: Example
url: http://example.com
steps: []
""")
    }

    private func videoSettings(titleFromFilename: Bool = false) -> VideoImporter.Settings {
        return VideoImporter.Settings(defaultCategory: "snapshots",
                                      titleFromFilename: titleFromFilename,
                                      defaultTemplate: "video.html",
                                      inlineTemplate: "video.html")
    }

    func testFrontmatterTitleOverridesMetadataTitle() async throws {
        try await withTemporarySourceDirectory { sourceDirectory in
            try configureSite(in: sourceDirectory)
            let file = try sourceDirectory.add("video.mov", location: .content, contents: "")
            let video = TestPlatformVideo(title: "Metadata Title",
                                          mediaDescription: """
---
title: Frontmatter Title
---
""")
            let result = try await VideoImporter.process(file: file,
                                                         settings: videoSettings(),
                                                         outputURL: sourceDirectory.site.filesURL,
                                                         video: video)
            XCTAssertEqual(result.document?.title, "Frontmatter Title")
        }
    }

    func testMetadataTitleUsedWhenFrontmatterHasNoTitle() async throws {
        try await withTemporarySourceDirectory { sourceDirectory in
            try configureSite(in: sourceDirectory)
            let file = try sourceDirectory.add("video.mov", location: .content, contents: "")
            let video = TestPlatformVideo(title: "Metadata Title",
                                          mediaDescription: "A plain caption with no frontmatter.")
            let result = try await VideoImporter.process(file: file,
                                                         settings: videoSettings(),
                                                         outputURL: sourceDirectory.site.filesURL,
                                                         video: video)
            XCTAssertEqual(result.document?.title, "Metadata Title")
        }
    }

    func testFrontmatterDateOverridesMetadataDate() async throws {
        try await withTemporarySourceDirectory { sourceDirectory in
            try configureSite(in: sourceDirectory)
            let file = try sourceDirectory.add("video.mov", location: .content, contents: "")
            let video = TestPlatformVideo(creationDate: Date(2001, 10, 02, 01, 54, 02),
                                          mediaDescription: """
---
date: '2020-05-04 12:00:00 +00:00'
---
""")
            let result = try await VideoImporter.process(file: file,
                                                         settings: videoSettings(),
                                                         outputURL: sourceDirectory.site.filesURL,
                                                         video: video)
            XCTAssertEqual(result.document?.date, Date(2020, 05, 04, 12, 00, 00))
        }
    }

    func testFrontmatterDurationOverridesMetadataDuration() async throws {
        try await withTemporarySourceDirectory { sourceDirectory in
            try configureSite(in: sourceDirectory)
            let file = try sourceDirectory.add("video.mov", location: .content, contents: "")
            let video = TestPlatformVideo(duration: 7.835,
                                          mediaDescription: """
---
duration: 42.0
---
""")
            let result = try await VideoImporter.process(file: file,
                                                         settings: videoSettings(),
                                                         outputURL: sourceDirectory.site.filesURL,
                                                         video: video)
            XCTAssertEqual(result.document?.metadata["duration"] as? Double, 42.0)
        }
    }

    func testFrontmatterInjectsCustomMetadata() async throws {
        try await withTemporarySourceDirectory { sourceDirectory in
            try configureSite(in: sourceDirectory)
            let file = try sourceDirectory.add("video.mov", location: .content, contents: "")
            let video = TestPlatformVideo(mediaDescription: """
---
photographer: Jane Doe
---
""")
            let result = try await VideoImporter.process(file: file,
                                                         settings: videoSettings(),
                                                         outputURL: sourceDirectory.site.filesURL,
                                                         video: video)
            XCTAssertEqual(result.document?.metadata["photographer"] as? String, "Jane Doe")
        }
    }

    func testExtractDuration() async throws {

        _ = try defaultSourceDirectory.add("site.yaml", contents: """
version: 2
title: Example
url: http://example.com
steps:
  - when: '(.*/)?.*\\.mov'
    then: video
    args:
        category: snapshots
        defaultTemplate: video.html
        inlineTemplate: video.html
        titleFromFilename: false
""")

        let video = try defaultSourceDirectory.copy(try bundle.throwingURL(forResource: "2022-05-31-17-55-03-royal-wave",
                                                                           withExtension: "mov"),
                                                    to: "2022-05-31-17-55-03-royal-wave.mov",
                                                    location: .content)

        let result = try await VideoImporter.process(file: video,
                                                     settings: VideoImporter.Settings(defaultCategory: "snapshots",
                                                                                      titleFromFilename: false,
                                                                                      defaultTemplate: "video.html",
                                                                                      inlineTemplate: "video.html"),
                                                     outputURL: defaultSourceDirectory.site.filesURL)
        let duration = try XCTUnwrap(result.document?.metadata["duration"] as? Double)
        XCTAssertEqual(duration, 7.835, accuracy: 0.01)
    }

}
