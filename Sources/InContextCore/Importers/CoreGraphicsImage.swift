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

final class CoreGraphicsImage: PlatformImage {

    let source: CGImageSource

    private let properties: [String: Any]
    private let metadata: CGImageMetadata

    init(url: URL) throws {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            throw InContextError.internalInconsistency("Failed to open image file at '\(url.relativePath)'.")
        }
        guard let rawProperties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) else {
            throw InContextError.internalInconsistency("Failed to load properties for image at '\(url.relativePath)'.")
        }
        guard let properties = rawProperties as? [String: Any] else {
            throw InContextError.internalInconsistency("Failed to load image properties")
        }
        guard let metadata = CGImageSourceCopyMetadataAtIndex(source, 0, nil) else {
            throw InContextError.internalInconsistency("Failed to load image metadata")
        }
        self.source = source
        self.properties = properties
        self.metadata = metadata
    }

    var size: Size? {
        get throws {
            guard let width: Int = try properties.optionalValue(for: "PixelWidth"),
                  let height: Int = try properties.optionalValue(for: "PixelHeight")
            else {
                return nil
            }
            return Size(width: width, height: height)
        }
    }

    // TODO: Use EXIF timezones if they exist.

    var dateTimeOriginal: Date? {
        get throws {
            guard let string: String = try properties.optionalValue(for: ["{Exif}", "DateTimeOriginal"]) else {
                return nil
            }
            return DateParser.default.date(from: string)
        }
    }

    var dateTimeDigitized: Date? {
        get throws {
            guard let string: String = try properties.optionalValue(for: ["{Exif}", "DateTimeDigitized"]) else {
                return nil
            }
            return DateParser.default.date(from: string)
        }
    }

    private var title: String? {
        get throws { return try properties.optionalValue(for: "Title") }
    }

    private var displayName: String? {
        get throws { return try properties.optionalValue(for: "DisplayName") }
    }

    private var objectName: String? {
        get throws { return try properties.optionalValue(for: ["{IPTC}", "ObjectName"]) }
    }

    var firstTitle: String? {
        get throws { return try (try title) ?? (try displayName) ?? (try objectName) }
    }

    var mediaDescription: String? {
        get throws { return try properties.optionalValue(for: ["{TIFF}", "ImageDescription"]) }
    }

    private var latitude: Double? {
        get throws { return try properties.optionalValue(for: ["{GPS}", "Latitude"]) }
    }

    private var latitudeRef: CompassDirection? {
        get throws { return try properties.optionalRawRepresentable(for: ["{GPS}", "LatitudeRef"]) }
    }

    private var longitude: Double? {
        get throws { return try properties.optionalValue(for: ["{GPS}", "Longitude"]) }
    }

    private var longitudeRef: CompassDirection? {
        get throws { return try properties.optionalRawRepresentable(for: ["{GPS}", "LongitudeRef"]) }
    }

    var signedLatitude: Double? {
        get throws {
            guard let latitude = try latitude, let latitudeRef = try latitudeRef else {
                return nil
            }
            return latitude * latitudeRef.multiplier
        }
    }

    var signedLongitude: Double? {
        get throws {
            guard let longitude = try longitude, let longitudeRef = try longitudeRef else {
                return nil
            }
            return longitude * longitudeRef.multiplier
        }
    }

    var projectionType: String? {
        get throws {
            guard let tag = CGImageMetadataCopyTagWithPath(metadata, nil, "GPano:ProjectionType" as NSString) else {
                return nil
            }
            guard let value = CGImageMetadataTagCopyValue(tag) as? String else {
                // TODO: Consider making this a little cleaner
                throw InContextError.internalInconsistency("Unexpected value for image property 'ProjectionType'")
            }
            return value
        }
    }

    var frameCount: Int {
        return CGImageSourceGetCount(source)
    }

    func write(maxPixelSize: Int, format: FileType, to url: URL) throws {
        let options = [kCGImageSourceCreateThumbnailWithTransform: kCFBooleanTrue,
                     kCGImageSourceCreateThumbnailFromImageAlways: kCFBooleanTrue,
                              kCGImageSourceThumbnailMaxPixelSize: maxPixelSize as NSNumber] as CFDictionary

        let frameCount = CGImageSourceGetCount(source)

        guard let identifier = format.identifier else {
            throw InContextError.unsupportedMediaType
        }

        guard let destination = CGImageDestinationCreateWithURL(url as CFURL,
                                                                identifier as CFString,
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
