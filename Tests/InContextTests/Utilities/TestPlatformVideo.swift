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

final class TestPlatformVideo: PlatformVideo {

    let size: Size?
    let duration: Double?
    let creationDate: Date?
    let title: String?
    let mediaDescription: String?
    let location: (latitude: Double, longitude: Double)?

    init(size: Size? = Size(width: 640, height: 480),
         duration: Double? = nil,
         creationDate: Date? = nil,
         title: String? = nil,
         mediaDescription: String? = nil,
         location: (latitude: Double, longitude: Double)? = nil) {
        self.size = size
        self.duration = duration
        self.creationDate = creationDate
        self.title = title
        self.mediaDescription = mediaDescription
        self.location = location
    }

    init(url: URL) async throws {
        fatalError("Unsupported")
    }

    func writeThumbnail(at time: Double, maxPixelSize: Int, format: FileType, to url: URL) async throws {
        try Data().write(to: url)
    }

    func writeVideo(maxPixelSize: Int, format: FileType, to url: URL) async throws {
        try Data().write(to: url)
    }

}
