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

#if canImport(CMagickWand)

import Foundation
import Glibc

import CMagickWand

actor MagicWand {

    private var isInitialized = false

    func initialize() throws {
        guard !isInitialized else {
            return
        }

        // Relax ImageMagick's resource policy.
        let configDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("incontext-imagemagick-policy", isDirectory: true)
        let policyURL = configDirectory.appendingPathComponent("policy.xml")
        let policy = """
        <?xml version="1.0" encoding="UTF-8"?>
        <policymap>
          <policy domain="resource" name="memory" value="4GiB"/>
          <policy domain="resource" name="map" value="8GiB"/>
          <policy domain="resource" name="disk" value="8GiB"/>
        </policymap>
        """
        try FileManager.default.createDirectory(at: configDirectory, withIntermediateDirectories: true)
        try policy.write(to: policyURL, atomically: true, encoding: .utf8)
        setenv("MAGICK_CONFIGURE_PATH", configDirectory.path, 1)

        // Initialize MagicWand.
        MagickWandGenesis()

        isInitialized = true
    }

    deinit {
        guard isInitialized else {
            return
        }
        MagickWandTerminus()
    }

}

let magicWand = MagicWand()

func initializeMagicWand() async throws {
    try await magicWand.initialize()
}

final class MagickImage: PlatformImage {

    private let wand: OpaquePointer

    init(url: URL) async throws {
        try await initializeMagicWand()
        guard let wand = NewMagickWand() else {
            throw InContextError.allocationFailure
        }
        guard MagickReadImage(wand, url.path) == MagickTrue else {
            let message = MagickImage.exceptionMessage(wand)
            DestroyMagickWand(wand)
            throw InContextError.imageLibraryError(message)
        }

        self.wand = wand
    }

    deinit {
        DestroyMagickWand(wand)
    }

    var size: Size? {
        return Size(width: Int(MagickGetImageWidth(wand)), height: Int(MagickGetImageHeight(wand)))
    }

    var dateTimeOriginal: Date? {
        get throws { return try date(for: "exif:DateTimeOriginal") }
    }

    var dateTimeDigitized: Date? {
        get throws { return try date(for: "exif:DateTimeDigitized") }
    }

    private lazy var xmp: XMPMetadata? = {
        var length = 0
        guard let profile = MagickGetImageProfile(wand, "xmp", &length) else {
            return nil
        }
        defer {
            MagickRelinquishMemory(UnsafeMutableRawPointer(mutating: profile))
        }
        return XMPMetadata(data: Data(bytes: profile, count: length))
    }()

    var title: String? {
        get throws {
            if let title = xmp?.title {
                return title
            }
            return try property("IPTC:2:5")
        }
    }

    var mediaDescription: String? {
        get throws {
            if let mediaDescription = xmp?.mediaDescription {
                return mediaDescription
            }
            if let caption = try property("IPTC:2:120") {
                return caption
            }
            return try property("exif:ImageDescription")
        }
    }

    var signedLatitude: Double? {
        get throws { return try signedCoordinate(magnitude: "exif:GPSLatitude", ref: "exif:GPSLatitudeRef") }
    }

    var signedLongitude: Double? {
        get throws { return try signedCoordinate(magnitude: "exif:GPSLongitude", ref: "exif:GPSLongitudeRef") }
    }

    var projectionType: String? {
        get throws { return try property("GPano:ProjectionType") }
    }

    var frameCount: Int {
        return Int(MagickGetNumberImages(wand))
    }

    func write(maxPixelSize: Int, format: FileType, to url: URL) throws {
        guard let coalesced = MagickCoalesceImages(wand) else {
            throw InContextError.imageLibraryError(MagickImage.exceptionMessage(wand))
        }
        defer {
            DestroyMagickWand(coalesced)
        }

        guard MagickSetImageFormat(coalesced, format.preferredFilenameExtension.uppercased()) == MagickTrue else {
            throw InContextError.imageLibraryError(MagickImage.exceptionMessage(coalesced))
        }

        MagickResetIterator(coalesced)

        while MagickNextImage(coalesced) == MagickTrue {
            let width = Int(MagickGetImageWidth(coalesced))
            let height = Int(MagickGetImageHeight(coalesced))
            let scale = Double(maxPixelSize) / Double(max(width, height))
            let targetWidth = max(1, Int((Double(width) * scale).rounded()))
            let targetHeight = max(1, Int((Double(height) * scale).rounded()))
            guard MagickResizeImage(coalesced, targetWidth, targetHeight, LanczosFilter) == MagickTrue else {
                throw InContextError.imageLibraryError(MagickImage.exceptionMessage(coalesced))
            }
        }

        MagickResetIterator(coalesced)

        guard MagickWriteImages(coalesced, url.path, MagickTrue) == MagickTrue else {
            throw InContextError.imageLibraryError(MagickImage.exceptionMessage(coalesced))
        }
    }

    private func property(_ name: String) throws -> String? {
        MagickClearException(wand)
        guard let value = MagickGetImageProperty(wand, name) else {
            guard MagickGetExceptionType(wand) == UndefinedException else {
                throw InContextError.imageLibraryError(MagickImage.exceptionMessage(wand))
            }
            return nil
        }
        defer {
            MagickRelinquishMemory(UnsafeMutableRawPointer(mutating: value))
        }
        return String(cString: value)
    }

    private func date(for property: String) throws -> Date? {
        guard let string = try self.property(property) else {
            return nil
        }
        return DateParser.default.date(from: string)
    }

    private func signedCoordinate(magnitude property: String, ref refProperty: String) throws -> Double? {
        guard let dms = try self.property(property),
              let refString = try self.property(refProperty),
              let ref = CompassDirection(rawValue: refString)
        else {
            return nil
        }
        return try Self.parseDMS(dms) * ref.multiplier
    }

    // MagickWand returns DMS (degrees, minutes, seconds).
    // For example, "64/1,8/1,3218/100" -> 64 + 8/60 + 32.18/3600.
    static func parseDMS(_ string: String) throws -> Double {
        let components = string.split(separator: ",").map(String.init)
        guard components.count == 3 else {
            throw InContextError.internalInconsistency("Unexpected GPS coordinate format: \(string)")
        }
        let values = try components.map { component -> Double in
            let parts = component.split(separator: "/")
            guard parts.count == 2,
                  let numerator = Double(parts[0]),
                  let denominator = Double(parts[1]),
                  denominator != 0
            else {
                throw InContextError.internalInconsistency("Unexpected GPS coordinate component: \(component)")
            }
            return numerator / denominator
        }
        return values[0] + values[1] / 60 + values[2] / 3600
    }

    private static func exceptionMessage(_ wand: OpaquePointer) -> String {
        var severity = UndefinedException
        guard let value = MagickGetException(wand, &severity) else {
            return "Unknown MagickWand error"
        }
        defer {
            MagickRelinquishMemory(UnsafeMutableRawPointer(mutating: value))
        }
        return String(cString: value)
    }

}

#endif
