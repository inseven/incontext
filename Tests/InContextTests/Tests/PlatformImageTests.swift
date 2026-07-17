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

class PlatformImageTests: ContentTestCase {

    func testPixelDimensions() throws {
        let url = try bundle.throwingURL(forResource: "IMG_0581", withExtension: "jpeg")
        let image = try NativeImage(url: url)
        let size = try XCTUnwrap(image.size)
        XCTAssertEqual(size.width, 4032)
        XCTAssertEqual(size.height, 3024)
    }

    func testDateTimeOriginal() throws {
        let url = try bundle.throwingURL(forResource: "IMG_0581", withExtension: "jpeg")
        let image = try NativeImage(url: url)
        XCTAssertEqual(try image.dateTimeOriginal, Date(2023, 04, 12, 11, 08, 27))
    }

    func testLocation() throws {
        let url = try bundle.throwingURL(forResource: "IMG_0581", withExtension: "jpeg")
        let image = try NativeImage(url: url)
        let latitude = try XCTUnwrap(image.signedLatitude)
        let longitude = try XCTUnwrap(image.signedLongitude)
        XCTAssertEqual(latitude, 64.142272166666672, accuracy: 0.0001)
        XCTAssertEqual(longitude, -21.927391666666665, accuracy: 0.0001)
    }

    func testMediaDescription() throws {
        let url = try bundle.throwingURL(forResource: "IMG_0581", withExtension: "jpeg")
        let image = try NativeImage(url: url)
        let description = try XCTUnwrap(image.mediaDescription)
        XCTAssert(description.contains("Hallgrímskirkja Church"))
    }

    func testProjectionType() throws {
        let url = try bundle.throwingURL(forResource: "R0010239", withExtension: "JPG")
        let image = try NativeImage(url: url)
        XCTAssertEqual(try image.projectionType, "equirectangular")
    }

    func testMetadataForImageWithReadWarnings() throws {
        let url = try bundle.throwingURL(forResource: "threshold", withExtension: "png")
        let image = try NativeImage(url: url)
        XCTAssertNil(try image.dateTimeOriginal)
        XCTAssertNil(try image.dateTimeDigitized)
        XCTAssertNil(try image.firstTitle)
        XCTAssertNil(try image.mediaDescription)
        XCTAssertNil(try image.signedLatitude)
        XCTAssertNil(try image.signedLongitude)
        XCTAssertNil(try image.projectionType)
    }

    func testFrameCountForStillImage() throws {
        let url = try bundle.throwingURL(forResource: "IMG_0581", withExtension: "jpeg")
        let image = try NativeImage(url: url)
        XCTAssertEqual(image.frameCount, 1)
    }

    func testFrameCountForAnimatedGif() throws {
        let url = try bundle.throwingURL(forResource: "nezumi_anim", withExtension: "gif")
        let image = try NativeImage(url: url)
        XCTAssertEqual(image.frameCount, 14)
    }

    func testResizesImage() throws {
        let url = try bundle.throwingURL(forResource: "IMG_0581", withExtension: "jpeg")
        let image = try NativeImage(url: url)

        let destinationURL = directoryURL.appendingPathComponent("thumbnail.jpeg")
        try image.write(maxPixelSize: 400, format: .jpeg, to: destinationURL)
        XCTAssert(FileManager.default.fileExists(at: destinationURL))

        let thumbnail = try NativeImage(url: destinationURL)
        let size = try XCTUnwrap(thumbnail.size)
        XCTAssertEqual(max(size.width, size.height), 400)
    }

    func testHeicPixelDimensions() throws {
        let url = try bundle.throwingURL(forResource: "IMG_0581", withExtension: "heic")
        let image = try NativeImage(url: url)
        let size = try XCTUnwrap(image.size)
        XCTAssertEqual(size.width, 4032)
        XCTAssertEqual(size.height, 3024)
    }

    func testHeicDateTimeOriginal() throws {
        let url = try bundle.throwingURL(forResource: "IMG_0581", withExtension: "heic")
        let image = try NativeImage(url: url)
        XCTAssertEqual(try image.dateTimeOriginal, Date(2023, 04, 12, 11, 08, 27))
    }

    func testResizesHeicImage() throws {
        let url = try bundle.throwingURL(forResource: "IMG_0581", withExtension: "heic")
        let image = try NativeImage(url: url)

        let destinationURL = directoryURL.appendingPathComponent("thumbnail.jpeg")
        try image.write(maxPixelSize: 400, format: .jpeg, to: destinationURL)
        XCTAssert(FileManager.default.fileExists(at: destinationURL))

        let thumbnail = try NativeImage(url: destinationURL)
        let size = try XCTUnwrap(thumbnail.size)
        XCTAssertEqual(max(size.width, size.height), 400)
    }

    func testConcurrentImports() async throws {
        let url = try bundle.throwingURL(forResource: "hero-open", withExtension: "jpg")
        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<40 {
                group.addTask {
                    let image = try NativeImage(url: url)
                    let dest = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).jpg")
                    try image.write(maxPixelSize: 1600, format: .jpeg, to: dest)
                    try? FileManager.default.removeItem(at: dest)
                }
            }
            try await group.waitForAll()
        }
    }

}
