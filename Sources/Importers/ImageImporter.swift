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

import Foundation
import ImageIO

class ImageImporter: Importer {

    let identifier = "app.incontext.importer.image"
    let legacyIdentifier = "import_photo"
    let version = 1

    func process(site: Site, file: File) async throws -> ImporterResult {

        let fileURL = file.url

        let resourceURL = URL(filePath: fileURL.relevantRelativePath, relativeTo: site.filesURL)  // TODO: Make this a utiltiy and test it
        try FileManager.default.createDirectory(at: resourceURL, withIntermediateDirectories: true)

        // Load the original image.
        guard let image = CGImageSourceCreateWithURL(fileURL as CFURL, nil) else {
            throw InContextError.unknown
        }

        // TODO: Extract some of this data into the document.
        _ = CGImageSourceCopyPropertiesAtIndex(image, 0, nil) as? [String: Any]

        var assets: [Asset] = []

        // Perform the transforms.
        for transform in site.transforms {

            let options = [kCGImageSourceCreateThumbnailWithTransform: kCFBooleanTrue,
                       kCGImageSourceCreateThumbnailFromImageIfAbsent: kCFBooleanTrue,
                                  kCGImageSourceThumbnailMaxPixelSize: transform.width as NSNumber] as CFDictionary

            let destinationFilename = transform.basename + "." + (transform.format.preferredFilenameExtension ?? "")
            let destinationURL = resourceURL.appending(component: destinationFilename) as CFURL

            // TODO: Doesn't work with SVG.
            let thumbnail = CGImageSourceCreateThumbnailAtIndex(image, 0, options)!
            guard let destination = CGImageDestinationCreateWithURL(destinationURL,
                                                                    transform.format.identifier as CFString,
                                                                    1,
                                                                    nil) else {
                throw InContextError.unknown
            }
            CGImageDestinationAddImage(destination, thumbnail, nil)
            CGImageDestinationFinalize(destination)  // TODO: Handle error here?
            assets.append(Asset(fileURL: destinationURL as URL))
        }

        let details = fileURL.basenameDetails()

        let document = Document(url: fileURL.siteURL,
                                parent: fileURL.parentURL,
                                type: "",
                                date: details.date,
                                metadata: [:],
                                contents: "",
                                mtime: file.contentModificationDate,
                                template: "photo.html")
        return ImporterResult(documents: [document], assets: assets)
    }

}
