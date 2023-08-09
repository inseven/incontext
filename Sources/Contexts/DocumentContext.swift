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

import SwiftSoup

struct DocumentContext: EvaluationContext {

    private let renderTracker: RenderTracker
    private let document: Document

    var url: String {
        return document.url
    }

    var title: String? {
        return document.title
    }

    var format: Document.Format {
        return document.format
    }

    // TODO: Rename to `text` to differentiate it from `html`
    var content: String {
        // TODO: Consistent content/contents naming.
        return document.contents
    }

    var contentModificationDate: Date {
        return document.contentModificationDate
    }

    var date: Date? {
        return document.date
    }

    init(renderTracker: RenderTracker, document: Document) {
        self.renderTracker = renderTracker
        self.document = document
    }

    func relativeSourcePath(for relativePath: String) -> String {

        // Do not touch absolute paths.
        guard !relativePath.hasPrefix("/") else {
            return relativePath
        }

        let rootURL = URL(fileURLWithPath: "/", isDirectory: true)
        let documentURL = URL(filePath: document.relativeSourcePath, relativeTo: rootURL)
        let parentURL = documentURL.deletingLastPathComponent()
        let url = parentURL.appendingPathComponent(relativePath)
        return url.relativePath
    }

    // TODO: Implement the thumbnail getter.

    // Generic transform; could be a protocol?
    // Takes a selector, and outputs the replacement for the selector?
    // Enough information injected (store, document, etc) to allow for correction of URLs and application of templates.
    // Perhaps there are off-the-shelf ones which perform a lookup and apply a template, and ones which just rewrite URLs
    // for matching selectors.
    // TODO: HTML media queries sound really nice.
    // TODO: Should the image transform _always_ place all image sizes into a fixed place?
    // Markdown files should be handled one way, and regular HTML tags should be handled another, since there's no way
    // that a user can write good image tags from Markdown.
    // TODO: Perhaps all document types can have an 'inline' template that is specified in the configuration and used
    //       whenever they're rendered inline.  ****IMPORTANT****
    /*
     .replaceInline("//img", .relativeLookup("@src"))  <-- this would replace all 'img' tags with an inline template
                                                           rendered with the document based on the relative lookup of
                                                           the src property of the tag.
     .convertRelativePaths("//img[@src]") <-- convert any relative paths to the new primary destination in the site
                                              note: this would require us to actually designate a primary file which
                                              we're not currently doing in the case of an image.

     .transformElements("//img", .replaceElement(.inlineRender("src")))
     .transformElements("//img", .convertRelativeAttributePaths(for: "src"))
     .transformElements("//img", .replaceElement(.string("Cheese"))

     */
    let transforms: [Transformer] = [
        ImageDocumentTransform(),
        RelativeSourceTransform(selector: "img", attribute: "src"),
    ]

    // TODO: Add a render cache for pages?
    // TODO: Unique document contexts in a cache to save loading them every time; query for the ids, and then and look
    //       them up by URL?

    func html() throws -> String {
        let content = try SwiftSoup.parse(document.contents)
        for transform in transforms {
            try transform.transform(renderTracker: renderTracker, document: self, content: content)
        }
        return try content.html()
    }

    func lookup(_ name: String) throws -> Any? {
        switch name {
        case "url":
            return url
        case "title":
            return title
        case "format":
            return format.rawValue
        case "content":
            return content
        case "html":
            // TODO: Make this a method to make it apparent to the template that it's doing work.
            return try html()
        case "date":
            return date
        case "contentModificationDate", "last_modified":
            return contentModificationDate
        case "query": return Function { (name: String) -> [DocumentContext] in
            guard let queries = document.metadata["queries"] as? [String: Any],
                  let query = queries[name] else {
                throw InContextError.unknownQuery(name)
            }
            return try renderTracker.documentContexts(query: try QueryDescription(definition: query))
        }
        case "children": return Function { () -> [DocumentContext] in
            return try renderTracker.documentContexts(query: QueryDescription(parent: document.url))
        }
        case "parent": return Function { () -> DocumentContext? in
            return try renderTracker.documentContexts(query: QueryDescription(url: document.parent)).first
        }
        case "closestAncestor": return Function { () -> DocumentContext? in
            var testURL: String? = url
            while true {
                testURL = testURL?.deletingLastPathComponent?.ensuringTrailingSlash()
                guard let testURL else {
                    return nil
                }
                guard let parent = try renderTracker.documentContexts(query: QueryDescription(url: testURL)).first else {
                    continue
                }
                return parent
            }
        }
        case "previous": return Function { () -> DocumentContext? in
            // TODO: Implement me!
            return nil
        }
        case "next": return Function { () -> DocumentContext? in
            // TODO: Implement me!
            return nil
        }
        case "child": return Function { (relativePath: String) -> DocumentContext? in
            let relativeSourcePath = relativeSourcePath(for: relativePath)
            return try renderTracker.documentContexts(query: QueryDescription(relativeSourcePath: relativeSourcePath)).first
        }
        case "relative_source_path": return Function { (relativePath: String) -> String in
            return relativeSourcePath(for: relativePath)
        }
        case "abspath": return Function { (relativePath: String) -> String in
            return relativeSourcePath(for: relativePath).ensuringLeadingSlash()
        }
        case "resolve": return Function { (relativePath: String) -> String in
            // Documentation: Resolve a relative or absolute source path, converting it into it's destination in the
            // output site. If this is a file, it will attempt to find the canonical representation of the file in the
            // new site.
            // TODO: We might wish to have a resolve_document equivalent which clearly finds the document in the
            // destination.
            // Return the canonical in-site file for a path relative to the source document.
            // TODO: Consider throwing if this is called with unexpected arguments or the target file couldn't be found
            //       (or doesn't exist in the site).
            // TODO: This is currently guess-work and should be far more rigorously coded with updates to Document in
            //       the future.
            let relativeSourcePath = relativeSourcePath(for: relativePath)

            // We currently special-case image documents that follow a known structure.
            if let child = try renderTracker.documentContexts(query: QueryDescription(relativeSourcePath: relativeSourcePath)).first,
               let image = child.document.metadata["image"] as? [String: Any],
               let url = image["url"] as? String {
                return url
            }
            
            return relativeSourcePath.ensuringLeadingSlash()
        }
        default:
            return document.metadata[name]
        }
    }

}
