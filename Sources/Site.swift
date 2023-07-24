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
import Yaml

struct Site {

    // TODO: These are hardcoded as resize operations; they should have custom names and be able to apply 'filters'.
    // TODO: Need to be able to always clamp to specific dimension.
    let transforms = [
        ImageTransform(basename: "large", width: 1600, format: .jpeg, sets: ["image", "previews"]),
        ImageTransform(basename: "small", width: 480, format: .jpeg, sets: ["thumbnail", "previews"]),
    ]

    let rootURL: URL
    let contentURL: URL
    let templatesURL: URL
    let buildURL: URL
    let storeURL: URL
    let filesURL: URL

    let settings: [AnyHashable: Any]

    let importers: [String: Importer]

    let handlers: [Handler]

    init(rootURL: URL) throws {
        self.rootURL = rootURL
        self.contentURL = rootURL.appendingPathComponent("content", isDirectory: true)
        self.templatesURL = rootURL.appendingPathComponent("templates", isDirectory: true)
        self.buildURL = rootURL.appendingPathComponent("build-swift", isDirectory: true)
        self.storeURL = buildURL.appendingPathComponent("store.sqlite")
        self.filesURL = buildURL.appendingPathComponent("files", isDirectory: true)

        let settingsURL = rootURL.appendingPathComponent("site.yaml")
        let settingsData = try Data(contentsOf: settingsURL)
        guard let settingsString = String(data: settingsData, encoding: .utf8) else {
            throw InContextError.unsupportedEncoding
        }
        self.settings = try (try Yaml.load(settingsString)).dictionary()


        guard let buildSteps = settings["build_steps"] as? [[String: Any]],
              let processFiles = buildSteps.first,
              processFiles["task"] as? String == "process_files",
              let args = processFiles["args"] as? [String: Any],
              let handlers = args["handlers"] as? [[String: Any]]
        else {
            throw InContextError.corruptSettings
        }

        let actualHandlers = try handlers.map { handler in
            guard let when = handler["when"] as? String,
                  let then = handler["then"] as? String
            else {
                throw InContextError.corruptSettings
            }

            let settings: [AnyHashable: Any]
            if handler["args"] != nil {
                guard let args = handler["args"] as? [AnyHashable: Any] else {
                    throw InContextError.corruptSettings
                }
                settings = args
            } else {
                settings = [:]
            }

            return try Handler(when: when, then: then, settings: settings)
        }
        self.handlers = actualHandlers

        self.importers = ([
                CopyImporter(),
                IgnoreImporter(),
                ImageImporter(),
                MarkdownImporter(),
                SassImporter(),
                VideoImporter(),
            ] as [Importer]).reduce(into: [:]) { $0[$1.legacyIdentifier] = $1 }
    }

    func importer(for url: URL) throws -> (Importer, [AnyHashable: Any])? {
        for handler in handlers {
            guard try handler.when.wholeMatch(in: url.relativePath) != nil else {
                continue
            }
            guard let importer = importers[handler.then] else {
                throw InContextError.unknownImporter(handler.then)
            }
            return (importer, handler.settings)
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

    func outputURL(relativePath: String) -> URL {
        return URL(filePath: relativePath, relativeTo: filesURL)
    }

    static func ext() -> Extension {

        let ext = Extension()
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

        ext.registerFilter("json") { (value: Any?) in
            // TODO: Encode some JSON.
            return "{}"
        }

        ext.registerFilter("unique") { (value: Any?) in
            guard let value = value as? [String] else {
                throw TemplateSyntaxError("'unique' filter expects an array of strings")
            }
            return Array(Set(value))
        }

        ext.registerFilter("map") { (value: Any?, arguments: [Any?]) in
            // TODO: This should actually get a property off the thing.
            return value
        }

        ext.registerFilter("sort") { (value: Any?, arguments: [Any?]) in
            // TODO: Actually sort the input.
            return value
        }

        ext.registerFilter("rejectattr") { (value: Any?, arguments: [Any?]) in
            // TODO: Actually reject properties the input.
            return value
        }

        ext.registerTag("with", parser: WithNode.parse)
        ext.registerTag("macro", parser: MacroNode.parse)
        ext.registerTag("set", parser: SetNode.parse)
        ext.registerTag("update", parser: UpdateNode.parse)
        ext.registerTag("gallery", parser: GalleryNode.parse)  // This can and probably should be implemented as a template.
        ext.registerTag("video", parser: VideoNode.parse)  // This can and probably should be implemented as a template.
        ext.registerTag("template", parser: TemplateNode.parse)

        return ext
    }

    func environment() -> Environment {
        // Get the template.

        let templatesPath = site.templatesURL.path(percentEncoded: false)
        let loader = FileSystemLoader(paths: [.init(templatesPath)])
        let environment = Environment(loader: loader, extensions: [Self.ext()])



        // Pre-render the contents.
        // TODO: Inject the site for querying.

        return environment
    }

}
