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

#if canImport(AVFoundation)
import AVFoundation
#endif

class VideoImporter: Importer {

    struct Settings: ImporterSettings {
        let defaultCategory: String
        let titleFromFilename: Bool
        let defaultTemplate: String
        let inlineTemplate: String

        func combine(into fingerprint: inout Fingerprint) throws {
            try fingerprint.update(defaultCategory)
            try fingerprint.update(titleFromFilename)
            try fingerprint.update(defaultTemplate)
            try fingerprint.update(inlineTemplate)
        }
    }

    let identifier = "video"
    let version = 9

    func settings(for configuration: [String : Any]) throws -> Settings {
        return Settings(defaultCategory: try configuration.requiredValue(for: "category"),
                        titleFromFilename: try configuration.requiredValue(for: "titleFromFilename"),
                        defaultTemplate: try configuration.requiredValue(for: "defaultTemplate"),
                        inlineTemplate: try configuration.requiredValue(for: "inlineTemplate"))
    }

#if canImport(AVFoundation)

    static func process(file: File,
                        settings: Settings,
                        outputURL: URL) async throws -> ImporterResult {

        let fileURL = file.url

        // Create the assets directory.
        let assetsURL = URL(filePath: fileURL.relevantRelativePath, relativeTo: outputURL)
        try FileManager.default.createDirectory(at: assetsURL, withIntermediateDirectories: true)

        // Load the video.
        let asset = AVAsset(url: file.url)
        let quickTimeMetadata = try await asset.loadMetadata(for: .quickTimeMetadata)

        // Get the size by inspecting the first track.
        let videoTracks = try await asset.load(.tracks).filter { track in
            return track.mediaType == .video
        }
        guard let naturalSize = try await videoTracks.first?.load(.naturalSize) else {
            throw InContextError.videoLibraryError("Failed to determine size of video '\(fileURL.relativePath)'.")
        }
        let size = Size(naturalSize)

        // Load the details from the filename.
        let details = fileURL.basenameDetails()

        // Metadata.
        var metadata: [String: Any] = [:]

        if let location = try await quickTimeMetadata.location {
            metadata["location"] = [
                "latitude": location.latitude,
                "longitude": location.longitude,
            ]
        }

        // Get the metadata title and description.
        let content: FrontmatterDocument? = if let description = try await quickTimeMetadata.description {
            try FrontmatterDocument(contents: description, generateHTML: true)
        } else {
            nil
        }

        // TODO: Scale video.
        let videoURL = assetsURL.appendingPathComponent("video.mov")
        try await export(video: asset,
                         withPreset: AVAssetExportPresetHighestQuality,
                         toFileType: .mov,
                         atURL: videoURL)

        // TODO: Scale thumbnail.
        let thumbnailURL = assetsURL.appendingPathComponent("thumbnail", conformingTo: .jpeg)
        try await thumbnail(asset: asset, destinationURL: thumbnailURL)

        metadata["video"] = [
            "url": videoURL.relativePath.ensuringLeadingSlash(),
            "width": size.width,
            "height": size.height,
            "filename": "cheese",
        ]

        metadata["thumbnail"] = [
            "url": thumbnailURL.relativePath.ensuringLeadingSlash(),
            "width": size.width,
            "height": size.height,
            "filename": "cheese",
        ]

        // Title.
        let metadataTitle = try await quickTimeMetadata.title
        let filenameTitle = settings.titleFromFilename ? details.title : nil
        let title = content?.title ?? metadataTitle ?? filenameTitle

        // Date.
        let metadataDate = try await quickTimeMetadata.creationDate
        let date = content?.date ?? metadataDate ?? details.date

        let document = try Document(url: fileURL.siteURL,
                                    parent: fileURL.parentURL,
                                    category: settings.defaultCategory,
                                    date: date,
                                    title: title,
                                    metadata: metadata,
                                    contents: content?.content ?? "",
                                    contentModificationDate: file.contentModificationDate,
                                    template: settings.defaultTemplate,
                                    inlineTemplate: settings.inlineTemplate,
                                    relativeSourcePath: file.relativePath,
                                    format: .video)

        return ImporterResult(document: document, assets: [Asset(fileURL: videoURL), Asset(fileURL: thumbnailURL)])
    }

    static func thumbnail(asset: AVAsset, destinationURL: URL) async throws {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 1, preferredTimescale: 1)
        let result = try await generator.image(at: time)

        let format: UTType = .jpeg

        guard let destination = CGImageDestinationCreateWithURL(destinationURL as CFURL,
                                                                format.identifier as CFString,
                                                                1,
                                                                nil) else {
            throw InContextError.videoLibraryError("Failed to save thumbnail at '\(destinationURL.relativePath)'.")
        }
        CGImageDestinationAddImage(destination, result.image, nil)
        CGImageDestinationFinalize(destination)  // TODO: Handle error here?

    }

    // https://developer.apple.com/documentation/avfoundation/media_reading_and_writing/exporting_video_to_alternative_formats
    static func export(video: AVAsset,
                       withPreset preset: String = AVAssetExportPresetHighestQuality,
                       toFileType outputFileType: AVFileType = .mov,
                       atURL outputURL: URL) async throws {

        // Check the compatibility of the preset to export the video to the output file type.
        guard await AVAssetExportSession.compatibility(ofExportPreset: preset,
                                                       with: video,
                                                       outputFileType: outputFileType) else {
            throw InContextError.videoLibraryError("The preset can't export the video to the output file type.")
        }

        // Create and configure the export session.
        guard let exportSession = AVAssetExportSession(asset: video,
                                                       presetName: preset) else {
            throw InContextError.videoLibraryError("Failed to create export session.")
        }

        // Convert the video to the output file type and export it to the output URL.
        try await exportSession.export(to: outputURL, as: outputFileType)
    }

#else

    static func process(file: File,
                        settings: Settings,
                        outputURL: URL) async throws -> ImporterResult {

        throw InContextError.internalInconsistency("Unsupported")
    }

#endif

}
