// MIT License
//
// Copyright (c) 2016-2024 Jason Morley
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

#if canImport(CoreGraphics)
import CoreGraphics
#endif

import Foundation

#if canImport(ImageIO)
import ImageIO
#endif

import PlatformSupport

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
    let image: PlatformImage
    let exif: EXIF  // TODO: This is encapsulated in `PlatformImage`

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

        // TODO: Honour the input format if we don't have one.
        guard let format = self.format ?? context.fileURL.type else {
            throw InContextError.internalInconsistency("Failed to detect output type for '\(context.fileURL.relativePath)'.")
        }
        let destinationFilename = basename + "." + (format.preferredFilenameExtension ?? "")
        let destinationURL = context.assetsURL.appending(component: destinationFilename)

#if os(Linux)

#else

        let options = [kCGImageSourceCreateThumbnailWithTransform: kCFBooleanTrue,
                     kCGImageSourceCreateThumbnailFromImageAlways: kCFBooleanTrue,
                              kCGImageSourceThumbnailMaxPixelSize: maxPixelSize as NSNumber] as CFDictionary

        let frameCount = CGImageSourceGetCount(context.image.source)

        guard let destination = CGImageDestinationCreateWithURL(destinationURL as CFURL,
                                                                format.identifier as CFString,
                                                                frameCount,
                                                                nil) else {
            throw InContextError.internalInconsistency("Failed to resize image at '\(context.fileURL.relativePath)'.")
        }

        // Cherry-pick relevant image properties.
        var destinationProperties: [String: Any] = [:]
        if let sourceProperties = CGImageSourceCopyProperties(context.image.source, nil) as? [String: Any] {
            if let gifProperties = sourceProperties[kCGImagePropertyGIFDictionary as String] {
                destinationProperties[kCGImagePropertyGIFDictionary as String] = gifProperties
            }
        }
        CGImageDestinationSetProperties(destination, destinationProperties as CFDictionary)

        // Resize the frames.
        for i in 0..<frameCount {
            let thumbnail = CGImageSourceCreateThumbnailAtIndex(context.image.source, i, options)!
            if let properties = CGImageSourceCopyPropertiesAtIndex(context.image.source, i, nil) as? [String: Any] {
                var frameProperties: [String: Any] = [:]
                if let gifProperties = properties[kCGImagePropertyGIFDictionary as String] {
                    frameProperties[kCGImagePropertyGIFDictionary as String] = gifProperties
                }
                CGImageDestinationAddImage(destination, thumbnail, frameProperties as CFDictionary)
            }
        }

        CGImageDestinationFinalize(destination)  // TODO: Handle error here?

#endif

        // context.assets.append(Asset(fileURL: destinationURL as URL))  // TODO: Why `as URL`?

        let details = [
            "width": targetSize.width,
            "height": targetSize.height,
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
        _Resize(basename: "1600", width: 1600, format: .jpeg, sets: ["image", "previews"])
        _Resize(basename: "1200", width: 1200, format: .jpeg, sets: ["previews"])
        _Resize(basename: "800", width: 800, format: .jpeg, sets: ["previews"])
        _Resize(basename: "400", width: 400, format: .jpeg, sets: ["thumbnail", "previews"])
    }

    _Where(_True()) {
        _Resize(basename: "1600", width: 1600, sets: ["image", "previews"])
        _Resize(basename: "1200", width: 1200, sets: ["previews"])
        _Resize(basename: "800", width: 800, sets: ["previews"])
        _Resize(basename: "400", width: 400, sets: ["thumbnail", "previews"])
    }

}

class ImageImporter {

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

    let identifier = "image"
    let version = 13

    func settings(for configuration: [String : Any]) throws -> Settings {
        return Settings(defaultCategory: try configuration.requiredValue(for: "category"),
                        titleFromFilename: try configuration.requiredValue(for: "titleFromFilename"),
                        defaultTemplate: try configuration.requiredValue(for: "defaultTemplate"),
                        inlineTemplate: try configuration.requiredValue(for: "inlineTemplate"))
    }

}

extension ImageImporter: Importer {

    func process(file: File,
                 settings: Settings,
                 outputURL: URL) async throws -> ImporterResult {

        let fileURL = file.url

        // Create the assets directory.
        let assetsURL = URL(filePath: fileURL.relevantRelativePath, relativeTo: outputURL)  // TODO: Make this a utiltiy and test it
        try FileManager.default.createDirectory(at: assetsURL, withIntermediateDirectories: true)

        // Load the image.
        let image = try PlatformImage(url: fileURL)

        let details = fileURL.basenameDetails()

        // Metadata.
        var metadata: [String: Any] = [:]

        if let scale = details.scale {
            metadata["scale"] = scale
        }

        if let projectionType = try image.exif.projectionType {
            metadata["projection"] = projectionType
        }

        // Content.
        var content: FrontmatterDocument? = nil
        if let imageDescription = try image.exif.imageDescription {
            let frontmatter = try FrontmatterDocument(contents: imageDescription, generateHTML: true)
            guard let contentMetadata = frontmatter.metadata as? [String: Any] else {
                throw InContextError.internalInconsistency("Unexpected key type for metadata")
            }
            metadata.merge(contentMetadata) { $1 }
            content = frontmatter
        }

        // Location.
        if let latitude = try image.exif.signedLatitude,
           let longitude = try image.exif.signedLongitude {
            metadata["location"] = [
                "latitude": latitude,
                "longitude": longitude,
            ]
        }

        // Perform the transforms.
        var context = TransformContext(fileURL: fileURL,
                                       image: image,
                                       exif: image.exif,
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

        let date = try (try? image.exif.dateTimeOriginal) ?? (try image.exif.dateTimeDigitized) ?? details.date
        let title = try image.exif.firstTitle ?? content?.title ?? filenameTitle

        let document = try Document(url: fileURL.siteURL,
                                    parent: fileURL.parentURL,
                                    category: settings.defaultCategory,
                                    date: date,
                                    title: title,
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
