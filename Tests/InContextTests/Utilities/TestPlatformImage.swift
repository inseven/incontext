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

@testable import InContextCore

final class TestPlatformImage: PlatformImage {

    let size: Size?
    let dateTimeOriginal: Date?
    let dateTimeDigitized: Date?
    let title: String?
    let mediaDescription: String?
    let signedLatitude: Double?
    let signedLongitude: Double?
    let projectionType: String?
    let frameCount: Int

    init(size: Size? = Size(width: 640, height: 480),
         dateTimeOriginal: Date? = nil,
         dateTimeDigitized: Date? = nil,
         title: String? = nil,
         mediaDescription: String? = nil,
         signedLatitude: Double? = nil,
         signedLongitude: Double? = nil,
         projectionType: String? = nil,
         frameCount: Int = 1) {
        self.size = size
        self.dateTimeOriginal = dateTimeOriginal
        self.dateTimeDigitized = dateTimeDigitized
        self.title = title
        self.mediaDescription = mediaDescription
        self.signedLatitude = signedLatitude
        self.signedLongitude = signedLongitude
        self.projectionType = projectionType
        self.frameCount = frameCount
    }

    init(url: URL) async throws {
        fatalError("Unsupported")
    }

    func write(maxPixelSize: Int, format: FileType, to url: URL) throws {
        try Data().write(to: url)
    }

}
