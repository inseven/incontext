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
import CoreGraphics
import Foundation
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


class ImageImporter: Importer {

    struct Settings: ImporterSettings {
        let defaultCategory: String
        let titleFromFilename: Bool

        func combine(into fingerprint: inout Fingerprint) throws {
            try fingerprint.update(defaultCategory)
            try fingerprint.update(titleFromFilename)
        }
    }

    let identifier = "import_photo"
    let version = 6

    func settings(for configuration: [String : Any]) throws -> Settings {
        let args: [String: Any] = try configuration.requiredValue(for: "args")
        return Settings(defaultCategory: try args.requiredValue(for: "category"),
                        titleFromFilename: try args.requiredValue(for: "title_from_filename"))
    }

    func process(site: Site, file: File, settings: Settings) async throws -> ImporterResult {

        let fileURL = file.url

        let resourceURL = URL(filePath: fileURL.relevantRelativePath, relativeTo: site.filesURL)  // TODO: Make this a utiltiy and test it
        try FileManager.default.createDirectory(at: resourceURL, withIntermediateDirectories: true)

        // Load the original image.
        guard let image = CGImageSourceCreateWithURL(fileURL as CFURL, nil) else {
            throw InContextError.internalInconsistency("Failed to open image file at '\(fileURL.relativePath)'.")
        }

        // TODO: Extract some of this data into the document.

        guard let properties = CGImageSourceCopyPropertiesAtIndex(image, 0, nil) as? [String: Any],
              let width = properties["PixelWidth"] as? Int,
              let height = properties["PixelHeight"] as? Int else{
            throw InContextError.internalInconsistency("Filed to get dimensions of image at \(fileURL.relativePath).")
        }

        // TODO: Calculate the aspect ratio etc.

        let title: String = (try properties.optionalValue(for: "Title") ??
                             (try properties.optionalValue(for: "DisplayName")) ??
                             (try properties.optionalValue(for: "ObjectName")) ??
                             "")

        var metadata: [String: Any] = [
            "title": title
        ]

        var assets: [Asset] = []

        // Perform the transforms.
        var transformMetadata: [String: [[String: Any]]] = [:]
        for transform in site.transforms {

            let options = [kCGImageSourceCreateThumbnailWithTransform: kCFBooleanTrue,
                       kCGImageSourceCreateThumbnailFromImageIfAbsent: kCFBooleanTrue,
                                  kCGImageSourceThumbnailMaxPixelSize: transform.width as NSNumber] as CFDictionary

            let destinationFilename = transform.basename + "." + (transform.format.preferredFilenameExtension ?? "")
            let destinationURL = resourceURL.appending(component: destinationFilename)

            // TODO: Doesn't work with SVG.
            let thumbnail = CGImageSourceCreateThumbnailAtIndex(image, 0, options)!
            guard let destination = CGImageDestinationCreateWithURL(destinationURL as CFURL,
                                                                    transform.format.identifier as CFString,
                                                                    1,
                                                                    nil) else {
                throw InContextError.internalInconsistency("Failed to resize image at '\(fileURL.relativePath)'.")
            }
            CGImageDestinationAddImage(destination, thumbnail, nil)
            CGImageDestinationFinalize(destination)  // TODO: Handle error here?
            assets.append(Asset(fileURL: destinationURL as URL))

//            let sourceRatio =
//
//            let availableRect = AVFoundation.AVMakeRect(aspectRatio: image.size, insideRect: .init(origin: .zero, size: maxSize))
//            let targetSize = availableRect.size

            let details = [
                "width": width,
                "height": height,
                "filename": "cheese",
                "url": destinationURL.relativePath.ensureLeadingSlash(),
            ] as [String: Any]

            for setName in transform.sets {
                transformMetadata[setName] = (transformMetadata[setName] ?? []) + [details]
            }
        }

        // Flatten the transform metadata to promote categories with single entires to top-level dictionaries.
        // TODO: This is legacy behaviour from InContext 2 and we should probably reconsider whether it makes sense
        let transformDetails = transformMetadata
            .compactMap { key, value -> (String, Any)? in
                guard !value.isEmpty else {
                    return nil
                }
                if value.count == 1 {
                    return (key, value[0])
                }
                return (key, value)
            }
            .reduce(into: [String: Any]()) { partialResult, element in
                partialResult[element.0] = element.1
            }

        let details = fileURL.basenameDetails()
        metadata = metadata.merging(transformDetails) { $1 }

        let document = Document(url: fileURL.siteURL,
                                parent: fileURL.parentURL,
                                type: "",
                                date: details.date,
                                metadata: metadata,
                                contents: "",
                                contentModificationDate: file.contentModificationDate,
                                template: .stencil("photo.html"),
                                relativeSourcePath: file.relativePath)
        return ImporterResult(documents: [document], assets: assets)
    }

}
