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

import Stencil

class StencilRenderer: Renderer {

    let version = 1

    static func stencilExtension() -> Extension {

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

        ext.registerFilter("base64") { (value: Any?) in
            guard let value = value as? String else {
                throw TemplateSyntaxError("'base64' filter expects a string")
            }
            guard let data = value.data(using: .utf8) else {
                // TODO: Correct error
                throw InContextError.unknown
            }
            return data.base64EncodedString()
        }

        ext.registerFilter("int") { (value: Any?) in
            if let value = value as? NSNumber {
                return value.intValue
            }
            // TODO: Correct error.
            throw InContextError.unknown
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

    let loader: CachingLoader
    let environment: Environment

    init(templateCache: TemplateCache) {
        self.loader = CachingLoader(templateCache: templateCache)
        self.environment = Environment(loader: loader, extensions: [Self.stencilExtension()])
    }

    func render(name: String, context: [String : Any]) async throws -> RenderResult {
        // TODO: Is it possible to track the templates used externally?
        let (content, templates) = try environment.renderTemplate(name: name, context: context)
        return RenderResult(content: content, templatesUsed: templates)
    }

}
