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

#if os(Linux)

class PlatformImage {

    let url: URL
    let exif: EXIF

    init(url: URL) throws {
        self.url = url
        self.exif = try EXIF(url: url)
    }

}

#else

import CoreGraphics
import ImageIO

class PlatformImage {

    let url: URL
    let source: CGImageSource
    let exif: EXIF

    init(url: URL) throws {
        guard let image = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            throw InContextError.internalInconsistency("Failed to open image file at '\(url.relativePath)'.")
        }
        self.url = url
        self.source = image
        self.exif = try EXIF(image, 0)
    }

}

#endif