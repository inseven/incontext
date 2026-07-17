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

import PlatformSupport

#if canImport(AVFoundation)
typealias NativeVideo = AVFoundationVideo
#else
typealias NativeVideo = GStreamerVideo
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

    static let videoSize: Int = 1920
    static let thumbnailSize: Int = 400
    static let thumbnailOffset: Double = 1

    let identifier = "video"
    let version = 11

    func settings(for configuration: [String : Any]) throws -> Settings {
        return Settings(defaultCategory: try configuration.requiredValue(for: "category"),
                        titleFromFilename: try configuration.requiredValue(for: "titleFromFilename"),
                        defaultTemplate: try configuration.requiredValue(for: "defaultTemplate"),
                        inlineTemplate: try configuration.requiredValue(for: "inlineTemplate"))
    }

    static func process(file: File,
                        settings: Settings,
                        outputURL: URL) async throws -> ImporterResult {

        let fileURL = file.url

        // Create the assets directory.
        let assetsURL = URL(filePath: fileURL.relevantRelativePath, relativeTo: outputURL)
        try FileManager.default.createDirectory(at: assetsURL, withIntermediateDirectories: true)

        // Load the video.
        let video = try await NativeVideo(url: fileURL)

        // Get the size.
        guard let size = try await video.size else {
            throw InContextError.videoLibraryError("Failed to determine size of video '\(fileURL.relativePath)'.")
        }

        // Load the details from the filename.
        let details = fileURL.basenameDetails()

        // Metadata.
        var metadata: [String: Any] = [:]

        // Scale.
        if let scale = details.scale {
            metadata["scale"] = scale
        }

        // Duration.
        if let duration = try await video.duration {
            metadata["duration"] = duration
        }

        // Location.
        if let location = try await video.location {
            metadata["location"] = [
                "latitude": location.latitude,
                "longitude": location.longitude,
            ]
        }

        // Content.
        var content: FrontmatterDocument? = nil
        if let mediaDescription = try await video.mediaDescription {
            let frontmatter = try FrontmatterDocument(contents: mediaDescription, generateHTML: true)
            guard let contentMetadata = frontmatter.metadata as? [String: Any] else {
                throw InContextError.internalInconsistency("Unexpected key type for metadata")
            }
            metadata.merge(contentMetadata) { $1 }
            content = frontmatter
        }

        // Convert the video.
        let videoFormat: FileType = .quickTimeMovie
        let videoSize = size.fit(width: Self.videoSize)
        let videoFilename = "video." + videoFormat.preferredFilenameExtension
        let videoURL = assetsURL.appendingPathComponent(videoFilename)
        try await video.writeVideo(maxPixelSize: Self.videoSize, format: videoFormat, to: videoURL)

        // Generate the thumbnail.
        let thumbnailSize = size.fit(width: Self.thumbnailSize)
        let thumbnailFilename = "thumbnail." + FileType.jpeg.preferredFilenameExtension
        let thumbnailURL = assetsURL.appendingPathComponent(thumbnailFilename)
        try await video.writeThumbnail(at: Self.thumbnailOffset,
                                       maxPixelSize: Self.thumbnailSize,
                                       format: .jpeg,
                                       to: thumbnailURL)

        metadata["video"] = [
            "url": videoURL.relativePath.ensuringLeadingSlash(),
            "width": videoSize.width,
            "height": videoSize.height,
        ] as [String: Any]

        metadata["thumbnail"] = [
            "url": thumbnailURL.relativePath.ensuringLeadingSlash(),
            "width": thumbnailSize.width,
            "height": thumbnailSize.height,
        ] as [String: Any]

        // Title.
        let metadataTitle = try await video.title
        let filenameTitle = settings.titleFromFilename ? details.title : nil
        let title = content?.title ?? metadataTitle ?? filenameTitle

        // Date.
        let metadataDate = try await video.creationDate
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

}
