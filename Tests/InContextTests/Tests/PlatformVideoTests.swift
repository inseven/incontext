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

class PlatformVideoTests: ContentTestCase {

    func testPixelDimensions() async throws {
        let url = try bundle.throwingURL(forResource: "2022-05-31-17-55-03-royal-wave", withExtension: "mov")
        let video = try await NativeVideo(url: url)
        let size = try await video.size
        let unwrapped = try XCTUnwrap(size)
        XCTAssertEqual(unwrapped.width, 1920)
        XCTAssertEqual(unwrapped.height, 1080)
    }

    func testDuration() async throws {
        let url = try bundle.throwingURL(forResource: "2022-05-31-17-55-03-royal-wave", withExtension: "mov")
        let video = try await NativeVideo(url: url)
        let duration = try await video.duration
        XCTAssertEqual(try XCTUnwrap(duration), 7.835, accuracy: 0.01)
    }

    func testCreationDate() async throws {
        let url = try bundle.throwingURL(forResource: "2022-05-31-17-55-03-royal-wave", withExtension: "mov")
        let video = try await NativeVideo(url: url)
        let creationDate = try await video.creationDate
        XCTAssertEqual(try XCTUnwrap(creationDate), Date(2022, 05, 31, 17, 55, 03, timeZone: TimeZone(1)!))
    }

    func testMediaDescription() async throws {
        let url = try bundle.throwingURL(forResource: "2022-05-31-17-55-03-royal-wave", withExtension: "mov")
        let video = try await NativeVideo(url: url)
        let mediaDescription = try await video.mediaDescription
        let description = try XCTUnwrap(mediaDescription)
        XCTAssert(description.contains("Royal Wave"))
        XCTAssert(description.contains("Platinum Jubilee"))
    }

    func testLocation() async throws {
        let url = try bundle.throwingURL(forResource: "2022-05-31-17-55-03-royal-wave", withExtension: "mov")
        let video = try await NativeVideo(url: url)
        let location = try await video.location
        let coordinate = try XCTUnwrap(location)
        XCTAssertEqual(coordinate.latitude, 51.5126, accuracy: 0.0001)
        XCTAssertEqual(coordinate.longitude, -0.1240, accuracy: 0.0001)
    }

    func testWritesThumbnail() async throws {
        let url = try bundle.throwingURL(forResource: "2022-05-31-17-55-03-royal-wave", withExtension: "mov")
        let video = try await NativeVideo(url: url)

        let destinationURL = directoryURL.appendingPathComponent("thumbnail.jpeg")
        try await video.writeThumbnail(at: 1, maxPixelSize: 400, format: .jpeg, to: destinationURL)
        XCTAssert(FileManager.default.fileExists(at: destinationURL))

        let thumbnail = try NativeImage(url: destinationURL)
        let size = try XCTUnwrap(thumbnail.size)
        // AVAssetImageGenerator.maximumSize is a bounding box, not an exact fit, so the encoder's
        // even-dimension rounding can land a pixel or two under the requested size.
        XCTAssertEqual(Double(max(size.width, size.height)), 400, accuracy: 2)
    }

    func testWritesVideo() async throws {
        let url = try bundle.throwingURL(forResource: "2022-05-31-17-55-03-royal-wave", withExtension: "mov")
        let video = try await NativeVideo(url: url)

        let destinationURL = directoryURL.appendingPathComponent("video.mov")
        try await video.writeVideo(maxPixelSize: 640, format: .mov, to: destinationURL)
        XCTAssert(FileManager.default.fileExists(at: destinationURL))

        let transcoded = try await NativeVideo(url: destinationURL)
        let transcodedSize = try await transcoded.size
        let size = try XCTUnwrap(transcodedSize)
        XCTAssertEqual(max(size.width, size.height), 640)
    }

}
