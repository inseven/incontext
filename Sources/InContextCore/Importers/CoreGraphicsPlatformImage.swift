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

#if canImport(ImageIO)

import Foundation
import ImageIO

import PlatformSupport

final class CoreGraphicsPlatformImage: PlatformImage {

    let source: CGImageSource
    let exif: any ImageMetadata

    init(url: URL) throws {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            throw InContextError.internalInconsistency("Failed to open image file at '\(url.relativePath)'.")
        }
        guard let exif = try EXIF(source, 0) else {
            throw InContextError.internalInconsistency("Failed to load properties for image at '\(url.relativePath)'.")
        }
        self.source = source
        self.exif = exif
    }

    var frameCount: Int {
        return CGImageSourceGetCount(source)
    }

    func write(maxPixelSize: Int, format: UTType, to url: URL) throws {
        let options = [kCGImageSourceCreateThumbnailWithTransform: kCFBooleanTrue,
                     kCGImageSourceCreateThumbnailFromImageAlways: kCFBooleanTrue,
                              kCGImageSourceThumbnailMaxPixelSize: maxPixelSize as NSNumber] as CFDictionary

        let frameCount = CGImageSourceGetCount(source)

        guard let destination = CGImageDestinationCreateWithURL(url as CFURL,
                                                                format.identifier as CFString,
                                                                frameCount,
                                                                nil) else {
            throw InContextError.internalInconsistency("Failed to resize image at '\(url.relativePath)'.")
        }

        // Cherry-pick relevant image properties.
        var destinationProperties: [String: Any] = [:]
        if let sourceProperties = CGImageSourceCopyProperties(source, nil) as? [String: Any] {
            if let gifProperties = sourceProperties[kCGImagePropertyGIFDictionary as String] {
                destinationProperties[kCGImagePropertyGIFDictionary as String] = gifProperties
            }
        }
        CGImageDestinationSetProperties(destination, destinationProperties as CFDictionary)

        // Resize the frames.
        for i in 0..<frameCount {
            let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, i, options)!
            if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any] {
                var frameProperties: [String: Any] = [:]
                if let gifProperties = properties[kCGImagePropertyGIFDictionary as String] {
                    frameProperties[kCGImagePropertyGIFDictionary as String] = gifProperties
                }
                CGImageDestinationAddImage(destination, thumbnail, frameProperties as CFDictionary)
            }
        }

        CGImageDestinationFinalize(destination)  // TODO: Handle error here?
    }

}

#endif
