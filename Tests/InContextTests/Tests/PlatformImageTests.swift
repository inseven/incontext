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

class PlatformImageTests: ContentTestCase {

    let imageBackend: any PlatformImage.Type = defaultPlatformImage

    func testPixelDimensions() throws {
        let url = try bundle.throwingURL(forResource: "IMG_0581", withExtension: "jpeg")
        let image = try imageBackend.init(url: url)
        XCTAssertEqual(try XCTUnwrap(image.pixelWidth), 4032)
        XCTAssertEqual(try XCTUnwrap(image.pixelHeight), 3024)
    }

    func testDateTimeOriginal() throws {
        let url = try bundle.throwingURL(forResource: "IMG_0581", withExtension: "jpeg")
        let image = try imageBackend.init(url: url)
        XCTAssertEqual(try image.dateTimeOriginal, Date(2023, 04, 12, 11, 08, 27))
    }

    func testLocation() throws {
        let url = try bundle.throwingURL(forResource: "IMG_0581", withExtension: "jpeg")
        let image = try imageBackend.init(url: url)
        let latitude = try XCTUnwrap(image.signedLatitude)
        let longitude = try XCTUnwrap(image.signedLongitude)
        XCTAssertEqual(latitude, 64.142272166666672, accuracy: 0.0001)
        XCTAssertEqual(longitude, -21.927391666666665, accuracy: 0.0001)
    }

    func testImageDescription() throws {
        let url = try bundle.throwingURL(forResource: "IMG_0581", withExtension: "jpeg")
        let image = try imageBackend.init(url: url)
        let description = try XCTUnwrap(image.imageDescription)
        XCTAssert(description.contains("Hallgrímskirkja Church"))
    }

    func testProjectionType() throws {
        let url = try bundle.throwingURL(forResource: "R0010239", withExtension: "JPG")
        let image = try imageBackend.init(url: url)
        XCTAssertEqual(try image.projectionType, "equirectangular")
    }

    func testMetadataForImageWithReadWarnings() throws {
        let url = try bundle.throwingURL(forResource: "threshold", withExtension: "png")
        let image = try imageBackend.init(url: url)
        XCTAssertNil(try image.dateTimeOriginal)
        XCTAssertNil(try image.dateTimeDigitized)
        XCTAssertNil(try image.firstTitle)
        XCTAssertNil(try image.imageDescription)
        XCTAssertNil(try image.signedLatitude)
        XCTAssertNil(try image.signedLongitude)
        XCTAssertNil(try image.projectionType)
    }

    func testFrameCountForStillImage() throws {
        let url = try bundle.throwingURL(forResource: "IMG_0581", withExtension: "jpeg")
        let image = try imageBackend.init(url: url)
        XCTAssertEqual(image.frameCount, 1)
    }

    func testFrameCountForAnimatedGif() throws {
        let url = try bundle.throwingURL(forResource: "nezumi_anim", withExtension: "gif")
        let image = try imageBackend.init(url: url)
        XCTAssertEqual(image.frameCount, 14)
    }

    func testResizesImage() throws {
        let url = try bundle.throwingURL(forResource: "IMG_0581", withExtension: "jpeg")
        let image = try imageBackend.init(url: url)

        let destinationURL = directoryURL.appendingPathComponent("thumbnail.jpeg")
        try image.write(maxPixelSize: 400, format: .jpeg, to: destinationURL)
        XCTAssert(FileManager.default.fileExists(at: destinationURL))

        let thumbnail = try imageBackend.init(url: destinationURL)
        let width = try XCTUnwrap(thumbnail.pixelWidth)
        let height = try XCTUnwrap(thumbnail.pixelHeight)
        XCTAssertEqual(max(width, height), 400)
    }

}
