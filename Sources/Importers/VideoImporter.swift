// MIT License
//
// Copyright (c) 2023 Jason Barrie Morley
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

import AVFoundation
import Foundation

class VideoImporter: Importer {

    struct Settings: ImporterSettings {
        let defaultCategory: String
        let titleFromFilename: Bool
        let defaultTemplate: TemplateIdentifier
        let inlineTemplate: TemplateIdentifier

        func combine(into fingerprint: inout Fingerprint) throws {
            try fingerprint.update(defaultCategory)
            try fingerprint.update(titleFromFilename)
            try fingerprint.update(defaultTemplate)
            try fingerprint.update(inlineTemplate)
        }
    }

    let identifier = "video"
    let version = 8

    func settings(for configuration: [String : Any]) throws -> Settings {
        let args: [String: Any] = try configuration.requiredValue(for: "args")
        return Settings(defaultCategory: try args.requiredValue(for: "category"),
                        titleFromFilename: try args.requiredValue(for: "title_from_filename"),
                        defaultTemplate: try args.requiredRawRepresentable(for: "default_template"),
                        inlineTemplate: try args.requiredRawRepresentable(for: "inline_template"))
    }

    func process(site: Site, file: File, settings: Settings) async throws -> ImporterResult {

        let fileURL = file.url

        // Create the assets directory.
        let assetsURL = URL(filePath: fileURL.relevantRelativePath, relativeTo: site.filesURL)
        try FileManager.default.createDirectory(at: assetsURL, withIntermediateDirectories: true)

        let asset = AVAsset(url: file.url)

//        // Load the metadata.
//        for format in try await asset.load(.availableMetadataFormats) {
//            let metadata = try await asset.loadMetadata(for: format)
//            print(metadata)
//            // Process the format-specific metadata collection.
//        }

        // Get the first track to guess the dimensions.
        let videoTracks = try await asset.load(.tracks).filter { track in
            return track.mediaType == .video
        }

        guard let naturalSize = try await videoTracks.first?.load(.naturalSize) else {
            throw InContextError.internalInconsistency("Failed to determine size of video '\(fileURL.relativePath)'.")
        }
        let size = Size(naturalSize)

        let quickTimeMetadata = try await asset.loadMetadata(for: .quickTimeMetadata)

        let date: Date?
        if let creationDateItem = AVMetadataItem.metadataItems(from: quickTimeMetadata,
                                                               filteredByIdentifier: .quickTimeMetadataCreationDate).first,
           let creationDate = try await creationDateItem.load(.dateValue) {
            date = creationDate
        } else {
            date = nil
        }

        let content: FrontmatterDocument?
        if let descriptionItem = AVMetadataItem.metadataItems(from: quickTimeMetadata,
                                                          filteredByIdentifier: .quickTimeMetadataDescription).first,
           let description = try await descriptionItem.load(.stringValue) {
            content = try FrontmatterDocument(contents: description, generateHTML: true)
        } else {
            content = nil
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

//        https://img.ly/blog/working-with-large-video-and-image-files-on-ios-with-swift/#resizingavideo
//        let newAsset = AVAsset(url:Bundle.main.url(forResource: "jumping-man", withExtension: "mov")!) //1
//        var newSize = <some size that you've calculated> //2
//        let resizeComposition = AVMutableVideoComposition(asset: newAsset, applyingCIFiltersWithHandler: { request in
//          let filter = CIFilter(name: "CILanczosScaleTransform") //3
//          filter?.setValue(request.sourceImage, forKey: kCIInputImageKey)
//          filter?.setValue(<some scale factor>, forKey: kCIInputScaleKey) //4
//          let resultImage = filter?.outputImage
//          request.finish(with: resultImage, context: nil)
//        })
//        resizeComposition.renderSize = newSize //5

        let thumbnailDetails: [String: Any] = [
            "url": thumbnailURL.relativePath.ensuringLeadingSlash(),
            "width": size.width,
            "height": size.height,
            "filename": "cheese",
        ]

        let videoDetails: [String: Any] = [
            "url": videoURL.relativePath.ensuringLeadingSlash(),
            "width": size.width,
            "height": size.height,
            "filename": "cheese",
        ]

        let metadata: [String: Any] = [
            "thumbnail": thumbnailDetails,
            "video": videoDetails,
        ]

        let document = Document(url: fileURL.siteURL,
                                parent: fileURL.parentURL,
                                category: settings.defaultCategory,
                                date: content?.structuredMetadata.date ?? date,
                                title: content?.structuredMetadata.title,  // TODO: Title
                                metadata: metadata,
                                contents: content?.content ?? "",
                                contentModificationDate: file.contentModificationDate,
                                template: settings.defaultTemplate,
                                inlineTemplate: settings.inlineTemplate,
                                relativeSourcePath: file.relativePath,
                                format: .video)

        return ImporterResult(documents: [document], assets: [Asset(fileURL: videoURL), Asset(fileURL: thumbnailURL)])
    }

    func thumbnail(asset: AVAsset, destinationURL: URL) async throws {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 1, preferredTimescale: 1)
        let result = try await generator.image(at: time)

        let format: UTType = .jpeg

        guard let destination = CGImageDestinationCreateWithURL(destinationURL as CFURL,
                                                                format.identifier as CFString,
                                                                1,
                                                                nil) else {
            throw InContextError.internalInconsistency("Failed to save thumbnail at '\(destinationURL.relativePath)'.")
        }
        CGImageDestinationAddImage(destination, result.image, nil)
        CGImageDestinationFinalize(destination)  // TODO: Handle error here?

    }


    // https://developer.apple.com/documentation/avfoundation/media_reading_and_writing/exporting_video_to_alternative_formats
    func export(video: AVAsset,
                withPreset preset: String = AVAssetExportPresetHighestQuality,
                toFileType outputFileType: AVFileType = .mov,
                atURL outputURL: URL) async throws {

        // Check the compatibility of the preset to export the video to the output file type.
        guard await AVAssetExportSession.compatibility(ofExportPreset: preset,
                                                       with: video,
                                                       outputFileType: outputFileType) else {
            throw InContextError.internalInconsistency("The preset can't export the video to the output file type.")
        }

        // Create and configure the export session.
        guard let exportSession = AVAssetExportSession(asset: video,
                                                       presetName: preset) else {
            throw InContextError.internalInconsistency("Failed to create export session.")
        }
        exportSession.outputFileType = outputFileType
        exportSession.outputURL = outputURL

        // Convert the video to the output file type and export it to the output URL.
        await exportSession.export()
    }

}
