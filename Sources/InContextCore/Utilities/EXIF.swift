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

#if canImport(ImageIO)
import ImageIO

// Metadata import details from Python.
//METADATA_SCHEMA = Dictionary({
//
//    "title": String(First(Key("Title"), Key("DisplayName"), Key("ObjectName"), Empty())),
//    "content": String(First(Key("ImageDescription"), Key("Description"), Key("ArtworkContentDescription"), Default(None))),
//    "date": First(EXIFDate(First(Key("DateTimeOriginal"), Key("ContentCreateDate"), Key("CreationDate"))), Empty()),
//    "projection": First(Key("ProjectionType"), Empty()),
//    "location": First(Dictionary({
//        "latitude": GPSCoordinate(Key("GPSLatitude")),
//        "longitude": GPSCoordinate(Key("GPSLongitude")),
//    }), Empty())
//
//})

struct EXIF {

    enum CompassDirection: String {
        case north = "N"
        case south = "S"
        case east = "E"
        case west = "W"

        var multiplier: Double {
            switch self {
            case .north, .east:
                return 1
            case .west, .south:
                return -1
            }
        }
    }

    private static let dateTimeForatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter
    }()

    let _properties: [String: Any]
    let _metadata: CGImageMetadata

    init?(_ imageSource: CGImageSource, _ index: Int) throws {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, index, nil) else {
            return nil
        }
        guard let typedProperties = properties as? [String: Any] else {
            throw InContextError.internalInconsistency("Failed to load image properties")
        }

        // Image metadata, not image properties?
        guard let imageMetadata = CGImageSourceCopyMetadataAtIndex(imageSource, 0, nil) else {
            throw InContextError.internalInconsistency("Failed to load image metadata")
        }

        self._properties = typedProperties
        self._metadata = imageMetadata
    }

    var pixelWidth: Int? {
        get throws { return try _properties.optionalValue(for: "PixelWidth") }
    }

    var pixelHeight: Int? {
        get throws { return try _properties.optionalValue(for: "PixelHeight") }
    }

    // TODO: Use EXIF timezones if they exist.

    var dateTimeOriginal: Date? {
        get throws {
            guard let string: String = try _properties.optionalValue(for: ["{Exif}", "DateTimeOriginal"]) else {
                return nil
            }
            guard let date = Self.dateTimeForatter.date(from: string) else {
                throw InContextError.internalInconsistency("Failed to parse DateTimeOriginal (\(string))")
            }
            return date
        }
    }

    var dateTimeDigitized: Date? {
        get throws {
            guard let string: String = try _properties.optionalValue(for: ["{Exif}", "DateTimeDigitized"]) else {
                return nil
            }
            guard let date = Self.dateTimeForatter.date(from: string) else {
                throw InContextError.internalInconsistency("Failed to parse DateTimeDigitized (\(string))")
            }
            return date
        }

    }

    var title: String? {
        get throws { return try _properties.optionalValue(for: "Title") }
    }

    var displayName: String? {
        get throws { return try _properties.optionalValue(for: "DisplayName") }
    }

    var objectName: String? {
        get throws { return try _properties.optionalValue(for: ["{IPTC}", "ObjectName"]) }
    }

    var imageDescription: String? {
        get throws { return try _properties.optionalValue(for: ["{TIFF}", "ImageDescription"])}
    }

    var latitude: Double? {
        get throws { return try _properties.optionalValue(for: ["{GPS}", "Latitude"])}
    }

    var latitudeRef: CompassDirection? {
        get throws { return try _properties.optionalRawRepresentable(for: ["{GPS}", "LatitudeRef"])}
    }

    var longitude: Double? {
        get throws { return try _properties.optionalValue(for: ["{GPS}", "Longitude"])}
    }

    var longitudeRef: CompassDirection? {
        get throws { return try _properties.optionalRawRepresentable(for: ["{GPS}", "LongitudeRef"])}
    }

    var projectionType: String? {
        get throws {
            guard let tag = CGImageMetadataCopyTagWithPath(_metadata, nil, "GPano:ProjectionType" as NSString) else {
                return nil
            }
            guard let value = CGImageMetadataTagCopyValue(tag) as? String else {
                // TODO: Consider making this a little cleaner
                throw InContextError.internalInconsistency("Unexpected value for image property 'ProjectionType'")
            }
            return value
        }
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

    var firstTitle: String? {
        get throws { return try (try title) ?? (try displayName) ?? (try objectName) }
    }

}

#endif
