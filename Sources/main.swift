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
import Ink
import UniformTypeIdentifiers

// TODO: Inject the file
typealias Importer = (Site, File) async throws -> [Document]

func image_handler(site: Site, file: File) async throws -> [Document] {

    let fileURL = file.url

    let resourceURL = site.filesURL.appending(path: fileURL.relevantRelativePath)
    try FileManager.default.createDirectory(at: resourceURL, withIntermediateDirectories: true)

    // Load the original image.
    guard let image = CGImageSourceCreateWithURL(fileURL as CFURL, nil) else {
        throw InContextError.unknown
    }

    // TODO: Extract some of this data into the document.
    _ = CGImageSourceCopyPropertiesAtIndex(image, 0, nil) as? [String: Any]

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
    }

    let details = fileURL.basenameDetails()

    return [Document(url: fileURL.siteURL,
                     parent: fileURL.parentURL,
                     type: "",
                     date: details.date,
                     metadata: [:],
                     contents: "",
                     mtime: file.contentModificationDate,
                     template: "photo.html")]
}

func markdown_handler(site: Site, file: File) async throws -> [Document] {

    let fileURL = file.url

    let data = try Data(contentsOf: fileURL)
    guard let contents = String(data: data, encoding: .utf8) else {
        throw InContextError.unsupportedEncoding
    }
    let details = fileURL.basenameDetails()

    let result = try FrontmatterDocument(contents: contents, generateHTML: true)

    // Set the title if it doesn't exist.
    var metadata = result.metadata  // TODO: Perform a copy?
    if metadata["title"] == nil {
        metadata["title"] = details.title
    }

    // TODO: The metadata doesn't seem to permit complex structure; I might have to create my own parser.
    // TODO: There's a bunch of legacy code which detects thumbnails. *sigh*
    //       I think it might actually be possible to do this with the template engine.

    // TODO: Do I actually wnat it to process the markdown at import time? Does it matter?
    return [Document(url: fileURL.siteURL,
                     parent: fileURL.parentURL,
                     type: "",
                     date: details.date,
                     metadata: metadata,
                     contents: result.content,
                     mtime: file.contentModificationDate,
                     template: (metadata["template"] as? String) ?? "page.html")]  // TODO: Where the heck does this come from?
}

// TODO: Load the site configuration.
// TODO: Consider files on disk for default directory behaviours.
// TODO: Detect sites in roots above the current directory (gitlike)
let site = Site(rootURL: URL(filePath: "/Users/jbmorley/Projects/jbmorley.co.uk"))

let ic = try Builder(site: site)
try await ic.build()
