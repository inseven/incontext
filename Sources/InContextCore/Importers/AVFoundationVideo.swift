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

#if canImport(AVFoundation)

import AVFoundation
import CoreImage
import Foundation
import ImageIO

import PlatformSupport

final class AVFoundationVideo: PlatformVideo {

    private let asset: AVAsset
    private let quickTimeMetadata: [AVMetadataItem]

    init(url: URL) async throws {
        self.asset = AVAsset(url: url)
        self.quickTimeMetadata = try await asset.loadMetadata(for: .quickTimeMetadata)
    }

    private var videoTrack: AVAssetTrack? {
        get async throws {
            try await asset.load(.tracks).first { $0.mediaType == .video }
        }
    }

    var size: Size? {
        get async throws {
            guard let naturalSize = try await videoTrack?.load(.naturalSize) else {
                return nil
            }
            return Size(naturalSize)
        }
    }

    var duration: Double? {
        get async throws {
            let duration = try await asset.load(.duration)
            guard duration.isNumeric else {
                return nil
            }
            return duration.seconds
        }
    }

    var creationDate: Date? {
        get async throws {
            return try await quickTimeMetadata.creationDate
        }
    }

    var title: String? {
        get async throws {
            try await quickTimeMetadata.title
        }
    }

    var mediaDescription: String? {
        get async throws {
            try await quickTimeMetadata.description
        }
    }

    var location: (latitude: Double, longitude: Double)? {
        get async throws {
            try await quickTimeMetadata.location
        }
    }

    func writeThumbnail(at time: Double, maxPixelSize: Int, format: UTType, to url: URL) async throws {
        guard let videoSize = try await size else {
            throw InContextError.videoLibraryError("Failed to determine video dimensions.")
        }
        let size = videoSize.fit(width: maxPixelSize)

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: size.width, height: size.height)
        let result = try await generator.image(at: CMTime(seconds: time, preferredTimescale: 600))

        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, format.identifier as CFString, 1, nil) else {
            throw InContextError.videoLibraryError("Failed to create thumbnail destination at '\(url.relativePath)'.")
        }
        CGImageDestinationAddImage(destination, result.image, nil)

        guard CGImageDestinationFinalize(destination) else {
            throw InContextError.videoLibraryError("Failed to write thumbnail to '\(url.relativePath)'.")
        }
    }

    func writeVideo(maxPixelSize: Int, format: UTType, to url: URL) async throws {
        guard format == .mov else {
            throw InContextError.unsupportedMediaType
        }

        guard let videoSize = try await size else {
            throw InContextError.videoLibraryError("Failed to determine video dimensions.")
        }
        let size = videoSize.fit(width: maxPixelSize)
        let scale = Double(size.width) / Double(videoSize.width)

        let composition = AVMutableVideoComposition(asset: asset) { request in
            let filter = CIFilter(name: "CILanczosScaleTransform")
            filter?.setValue(request.sourceImage, forKey: kCIInputImageKey)
            filter?.setValue(scale, forKey: kCIInputScaleKey)
            filter?.setValue(1.0, forKey: kCIInputAspectRatioKey)
            request.finish(with: filter?.outputImage ?? request.sourceImage, context: nil)
        }
        composition.renderSize = CGSize(size)

        let preset = Self.exportPreset(forLongestEdge: max(size.width, size.height))
        guard await AVAssetExportSession.compatibility(ofExportPreset: preset, with: asset, outputFileType: .mov) else {
            throw InContextError.videoLibraryError("Preset '\(preset)' is not compatible with this asset.")
        }

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: preset) else {
            throw InContextError.videoLibraryError("Failed to create export session.")
        }
        exportSession.videoComposition = composition

        try await exportSession.export(to: url, as: .mov)
    }

    private static func exportPreset(forLongestEdge longestEdge: Int) -> String {
        switch longestEdge {
        case ..<640:
            return AVAssetExportPreset640x480
        case ..<960:
            return AVAssetExportPreset960x540
        case ..<1280:
            return AVAssetExportPreset1280x720
        default:
            return AVAssetExportPreset1920x1080
        }
    }

}

#endif
