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
import UniformTypeIdentifiers

import Stencil

extension UTType {

    static let markdown: UTType = UTType(mimeType: "text/markdown", conformingTo: .text)!

}

struct Site {

    // TODO: These are hardcoded as resize operations; they should have custom names and be able to apply 'filters'.
    // TODO: Need to be able to always clamp to specific dimension.
    let transforms = [
        ImageTransform(basename: "large", width: 1600, format: .jpeg, sets: ["image", "previews"]),
        ImageTransform(basename: "small", width: 480, format: .jpeg, sets: ["thumbnail", "previews"]),
    ]

    let importers: [([UTType], Importer)] = [
        ([.jpeg, .heic, .jpeg, .png, .gif, .tiff], ImageImporter()),
        ([.markdown], MarkdownImporter()),
    ]

    let rootURL: URL

    var contentURL: URL {
        return rootURL.appending(component: "content")
    }

    var templatesURL: URL {
        return rootURL.appending(component: "templates")
    }

    var buildURL: URL {
        return rootURL.appending(component: "build-swift")
    }

    var storeURL: URL {
        return buildURL.appending(component: "store.sqlite")
    }

    var filesURL: URL {
        return buildURL.appending(component: "files")
    }

    func importer(for url: URL) -> Importer? {
        guard let fileType = UTType(filenameExtension: url.pathExtension) else {
            return nil
        }
        for (types, importer) in site.importers {
            if types.contains(where: { fileType.conforms(to:$0) }) {
                return importer
            }
        }
        return nil
    }

    // TODO: Use a thread-safe cache.
    func template(named name: String) throws -> String {
        let templateURL = templatesURL.appending(component: name)
        let data = try Data(contentsOf: templateURL)
        guard let template = String(data: data, encoding: .utf8) else {
            throw InContextError.unsupportedEncoding
        }
        return template
    }

    func environment() -> Environment {
        // Get the template.

        let ext = Extension()
        let templatesPath = site.templatesURL.path(percentEncoded: false)
        let loader = FileSystemLoader(paths: [.init(templatesPath)])
        let environment = Environment(loader: loader, extensions: [ext])

        ext.registerFilter("safe") { content in
            return content
        }

        ext.registerFilter("date") { (value: Any?, arguments: [Any?]) in

            // Check the arguments.
            guard arguments.count == 1,
                  let dateFormat = arguments.first as? String
            else {
                // TODO: The error checking in here is absurd and needs more thought.
                return nil
//                throw TemplateSyntaxError("'date' filter must be called with string date format (got '\(arguments)')")
            }

            // Jinja2 is incredibly permissive and seems to coerce a nil input as a nil, so we allow that
            // here too to keep things simple.
            guard value != nil else {
                return nil
            }

            // Check the input.
            guard let date = value as? Date else {
                // TODO: Why the heck isn't the earlier nil check working?
                return nil
//                        throw TemplateSyntaxError("'date' filter expects a date (received \(value))")
            }

            // Actually format the date.
            let formatter = DateFormatter()
            formatter.dateFormat = dateFormat
            return formatter.string(from: date)
        }

        ext.registerFilter("titlecase") { (value: Any?) in
            guard let string = value as? String else {
                throw TemplateSyntaxError("'titlecase' filter expects a string")
            }
            return string.toTitleCase()
        }

        ext.registerFilter("selectattr") { (value: Any?, arguments: [Any?]) in
            // TODO: Implement this!
            return value
        }

        ext.registerFilter("attribute_with_default") { (value: Any?, arguments: [Any?]) in
            // TODO: Implement this!
            return value
        }

        ext.registerFilter("sort") { (value: Any?, arguments: [Any?]) in
            // TODO: Implement this!
            return value
        }

        ext.registerTag("with", parser: WithNode.parse)
        ext.registerTag("macro", parser: MacroNode.parse)
        ext.registerTag("set", parser: SetNode.parse)
        ext.registerTag("gallery", parser: GalleryNode.parse)  // This can and probably should be implemented as a template.
        ext.registerTag("video", parser: VideoNode.parse)  // This can and probably should be implemented as a template.
        ext.registerTag("template", parser: TemplateNode.parse)

        // Pre-render the contents.
        // TODO: Inject the site for querying.

        return environment
    }

}
