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

        func combine(into fingerprint: inout Fingerprint) throws {
            try fingerprint.update(defaultCategory)
            try fingerprint.update(titleFromFilename)
        }
    }

    let identifier = "import_video"
    let version = 6

    func settings(for configuration: [String : Any]) throws -> Settings {
        let args: [String: Any] = try configuration.requiredValue(for: "args")
        return Settings(defaultCategory: try args.requiredValue(for: "category"),
                        titleFromFilename: try args.requiredValue(for: "title_from_filename"))
    }

    func process(site: Site, file: File, settings: Settings) async throws -> ImporterResult {

        let fileURL = file.url

        // Create the assets directory.
        let assetsURL = URL(filePath: fileURL.relevantRelativePath, relativeTo: site.filesURL)
        try FileManager.default.createDirectory(at: assetsURL, withIntermediateDirectories: true)

        let video = AVAsset(url: file.url)

        // TODO: Scale video.
        let videoURL = assetsURL.appendingPathComponent("video.mov")
        try await export(video: video,
                         withPreset: AVAssetExportPresetHighestQuality,
                         toFileType: .mov,
                         atURL: videoURL)

        // TODO: Scale thumbnail.
        let thumbnailURL = assetsURL.appendingPathComponent("thumbnail", conformingTo: .jpeg)
        try await thumbnail(asset: video, destinationURL: thumbnailURL)

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
            "url": thumbnailURL.relativePath.ensureLeadingSlash(),
            "width": 100,
            "height": 100,
            "filename": "cheese",
        ]

        let videoDetails: [String: Any] = [
            "url": videoURL.relativePath.ensureLeadingSlash(),
            "width": 100,
            "height": 100,
            "filename": "cheese",
        ]

        let metadata: [String: Any] = [
            "thumbnail": thumbnailDetails,
            "video": videoDetails,
        ]

        let document = Document(url: fileURL.siteURL,
                                parent: fileURL.parentURL,
                                category: settings.defaultCategory,
                                date: Date(),  // TODO: Date
                                title: nil,  // TODO: Title
                                metadata: metadata,
                                contents: "",
                                contentModificationDate: file.contentModificationDate,
                                template: TemplateIdentifier(.tilt, "photo.html"),  // TODO: Inject this
                                inlineTemplate: nil,  // TODO: Inject this
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
