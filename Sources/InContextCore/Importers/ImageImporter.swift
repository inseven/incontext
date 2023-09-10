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

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

protocol _Test {
    // TODO: This needs to pass in the metadata
    func evaluate(fileURL: URL) -> Bool
}

struct _True: _Test {

    func evaluate(fileURL: URL) -> Bool {
        return true
    }

}

struct _Metadata: _Test {

    let key: String
    let value: String

    init(_ key: String, equals value: String) {
        self.key = key
        self.value = value
    }

    func evaluate(fileURL: URL) -> Bool {
        return true
    }

}

func ||<T: _Test, Q: _Test>(lhs: T, rhs: Q) -> _Or<T, Q> {
    return _Or(lhs, rhs)
}

func &&<T: _Test, Q: _Test>(lhs: T, rhs: Q) -> _And<T, Q> {
    return _And(lhs, rhs)
}

struct _Type: _Test {

    let type: UTType

    init(_ type: UTType) {
        self.type = type
    }

    func evaluate(fileURL: URL) -> Bool {
        guard let fileType = fileURL.type else {
            return false
        }
        return fileType.conforms(to: type)
    }

}

struct _Where {

    let test: _Test
    let transforms: [_Transform]

    init(_ test: _Test, @TransformsBuilder transforms: () -> [_Transform]) {
        self.test = test
        self.transforms = transforms()
    }

}

struct _And<A: _Test, B: _Test>: _Test {

    let lhs: A
    let rhs: B

    init(_ lhs: A, _ rhs: B) {
        self.lhs = lhs
        self.rhs = rhs
    }

    func evaluate(fileURL: URL) -> Bool {
        return lhs.evaluate(fileURL: fileURL) && rhs.evaluate(fileURL: fileURL)
    }

}

struct _Or<A: _Test, B: _Test>: _Test {

    let lhs: A
    let rhs: B

    init(_ lhs: A, _ rhs: B) {
        self.lhs = lhs
        self.rhs = rhs
    }

    func evaluate(fileURL: URL) -> Bool {
        return lhs.evaluate(fileURL: fileURL) || rhs.evaluate(fileURL: fileURL)
    }

}

struct TransformContext {

    let fileURL: URL
    let imageSource: CGImageSource
    let exif: EXIF

    let assetsURL: URL

    var metadata: [String: Any]
    var assets: [Asset]

}

// TODO: Consider making the data that's injected in generic? That way this could be used in multiple places?
//       Perhaps an image transform could allow for a bunch of type-constrained resize transforms in a pipeline?
protocol _Transform {
    func apply(to context: inout TransformContext) throws
}

struct _Resize: _Transform {

    let basename: String
    let width: Int  // TODO: Consider making this richer.
    let format: UTType?  // TODO: Rename to outputType
    let sets: [String]

    init(basename: String, width: Int, format: UTType? = nil, sets: [String]) {
        precondition(!sets.isEmpty, "Resize output must be stored in at least one set.")
        self.basename = basename
        self.width = width
        self.format = format
        self.sets = sets
    }

    func apply(to context: inout TransformContext) throws {

        guard let width = try context.exif.pixelWidth,
              let height = try context.exif.pixelHeight
        else {
            throw InContextError.internalInconsistency("Failed to get dimensions of image at \(context.fileURL.relativePath).")
        }

        let size = Size(width: width, height: height)
        let targetSize = size.fit(width: self.width)
        let maxPixelSize = max(targetSize.width, targetSize.height)

        let options = [kCGImageSourceCreateThumbnailWithTransform: kCFBooleanTrue,
                     kCGImageSourceCreateThumbnailFromImageAlways: kCFBooleanTrue,
                              kCGImageSourceThumbnailMaxPixelSize: maxPixelSize as NSNumber] as CFDictionary

        guard let format = self.format ?? context.fileURL.type else {
            throw InContextError.internalInconsistency("Failed to detect output type for '\(context.fileURL.relativePath)'.")
        }

        // TODO: Honour the input format if we don't have one.
        let destinationFilename = basename + "." + (format.preferredFilenameExtension ?? "")
        let destinationURL = context.assetsURL.appending(component: destinationFilename)

        let thumbnail = CGImageSourceCreateThumbnailAtIndex(context.imageSource, 0, options)!
        guard let destination = CGImageDestinationCreateWithURL(destinationURL as CFURL,
                                                                format.identifier as CFString,
                                                                1,
                                                                nil) else {
            throw InContextError.internalInconsistency("Failed to resize image at '\(context.fileURL.relativePath)'.")
        }
        CGImageDestinationAddImage(destination, thumbnail, nil)
        CGImageDestinationFinalize(destination)  // TODO: Handle error here?
        context.assets.append(Asset(fileURL: destinationURL as URL))

        let details = [
            "width": width,
            "height": height,
            "filename": "cheese", // TODO: Remove??
            "url": destinationURL.relativePath.ensuringLeadingSlash(),
        ] as [String: Any]

        // Add the results to the metadata.
        // This is unpleasantly nuanced as it attempts to replicate behaviour from InContext 2 that ensures sets with a
        // single entry are dictionaries, and sets with multiple entries are arrays. Hopefully we can remove this
        // behaviour in the future.
        for set in sets {
            guard let opaqueContainer = context.metadata[set] else {
                // Create a single entry container when no images exist.
                context.metadata[set] = details
                continue
            }
            guard var container = opaqueContainer as? [[String: Any]] else {
                // Try to promote a single entry container to an array.
                guard let entry = opaqueContainer as? [String: Any] else {
                    throw InContextError.internalInconsistency("Unexpected data in image set '\(set)'.")
                }
                context.metadata[set] = [entry, details]
                continue
            }
            container.append(details)
            context.metadata[set] = container
        }

    }

}

@resultBuilder struct TransformsBuilder {

    public static func buildBlock() -> [_Transform] {
        return []
    }

    public static func buildBlock(_ transforms: _Transform...) -> [_Transform] {
        return transforms
    }

}

@resultBuilder struct OperationsBuilder {

    public static func buildBlock() -> [_Where] {
        return []
    }

    public static func buildBlock(_ operations: _Where...) -> [_Where] {
        return operations
    }

}

struct _Configuration {

    let operations: [_Where]

    init(operations: [_Where]) {
        self.operations = operations
    }

    init(@OperationsBuilder operations: () -> [_Where]) {
        self.operations = operations()
    }

}

let configuration = _Configuration {

//    _Where(_Metadata("projection", equals: "equirectangular")) {
//        _Resize(basename: "large", width: 10000, sets: ["image"])
//        _Fisheye(basename: "preview-small", width: 480, format: .jpeg, sets: ["thumbnail", "previews"])
//        _Fisheye(basename: "preview-large", width: 960, format: .jpeg, sets: ["previews"])
//    }

    _Where(_Type(.heic) || _Type(.tiff)) {
        _Resize(basename: "large", width: 1600, format: .jpeg, sets: ["image", "previews"])
        _Resize(basename: "small", width: 480, format: .jpeg, sets: ["thumbnail", "previews"])
    }

    _Where(_True()) {
        _Resize(basename: "large", width: 1600, sets: ["image", "previews"])
        _Resize(basename: "small", width: 480, sets: ["thumbnail", "previews"])
    }

}

class ImageImporter: Importer {

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

    let identifier = "image"
    let version = 10

    func settings(for configuration: [String : Any]) throws -> Settings {
        let args: [String: Any] = try configuration.requiredValue(for: "args")
        return Settings(defaultCategory: try args.requiredValue(for: "category"),
                        titleFromFilename: try args.requiredValue(for: "title_from_filename"),
                        defaultTemplate: try args.requiredRawRepresentable(for: "default_template"),
                        inlineTemplate: try args.requiredRawRepresentable(for: "inline_template"))
    }

    func process(file: File,
                 settings: Settings,
                 outputURL: URL) async throws -> ImporterResult {

        let fileURL = file.url

        // Create the assets directory.
        let assetsURL = URL(filePath: fileURL.relevantRelativePath, relativeTo: outputURL)  // TODO: Make this a utiltiy and test it
        try FileManager.default.createDirectory(at: assetsURL, withIntermediateDirectories: true)

        // Load the original image.
        guard let image = CGImageSourceCreateWithURL(fileURL as CFURL, nil) else {
            throw InContextError.internalInconsistency("Failed to open image file at '\(fileURL.relativePath)'.")
        }

        guard let exif = try EXIF(image, 0) else {
            throw InContextError.internalInconsistency("Failed to load properties for image at '\(fileURL.relativePath)'.")
        }

        let details = fileURL.basenameDetails()

        // Metadata.
        var metadata: [String: Any] = [:]

        if let scale = details.scale {
            metadata["scale"] = scale
        }

        if let projectionType = try exif.projectionType {
            metadata["projection"] = projectionType
        }

        // Content.
        var content: FrontmatterDocument? = nil
        if let imageDescription = try exif.imageDescription {
            let frontmatter = try FrontmatterDocument(contents: imageDescription, generateHTML: true)
            metadata.merge(frontmatter.frontmatter.metadata) { $1 }
            content = frontmatter
        }

        // Location.
        if let latitude = try exif.signedLatitude,
           let longitude = try exif.signedLongitude {
            metadata["location"] = [
                "latitude": latitude,
                "longitude": longitude,
            ]
        }

        // Perform the transforms.
        var context = TransformContext(fileURL: fileURL,
                                       imageSource: image,
                                       exif: exif,
                                       assetsURL: assetsURL,
                                       metadata: metadata,
                                       assets: [])
        for operation in configuration.operations {
            guard operation.test.evaluate(fileURL: fileURL) else {
                continue
            }
            for transform in operation.transforms {
                try transform.apply(to: &context)
            }
            // We only run the first matching operation!
            break
        }

        let filenameTitle = settings.titleFromFilename ? details.title : nil

        // N.B. The EXIF 'DateTimeOriginal' field sometimes appears to be invalid so we fall back on DateTimeDigitized.

        let date = try (try? exif.dateTimeOriginal) ?? (try exif.dateTimeDigitized) ?? details.date
        let title = try exif.firstTitle ?? content?.frontmatter.title ?? filenameTitle

        let document = try Document(url: fileURL.siteURL,
                                    parent: fileURL.parentURL,
                                    category: settings.defaultCategory,
                                    date: date,
                                    title: title,
                                    thumbnail: nil,  // TODO: Feels like images should have a thumbnail? Are they their own thumbnail?
                                    queries: [:],
                                    metadata: context.metadata,
                                    contents: content?.content ?? "",
                                    contentModificationDate: file.contentModificationDate,
                                    template: settings.defaultTemplate,
                                    inlineTemplate: settings.inlineTemplate,
                                    relativeSourcePath: file.relativePath,
                                    format: .image)
        return ImporterResult(document: document, assets: context.assets)
    }

}
