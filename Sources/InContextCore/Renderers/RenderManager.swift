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

import Foundation

import SwiftSoup

import PlatformSupport

class RenderManager {

    private let templateCache: TemplateCache
    private let extensionsURL: URL

    private let syncQueue = DispatchQueue(label: "RenderManager.syncQueue")
    private var renderers: [TiltRenderer] = []

    init(templateCache: TemplateCache, extensionsURL: URL) {
        self.templateCache = templateCache
        self.extensionsURL = extensionsURL
    }

    var rendererVersion: Int {
        return TiltRenderer.version
    }

    // Look-up the modification date for each template, generate an associated render status.
    private func renderStatuses(for templates: [String]) throws -> [TemplateRenderStatus] {
        var renderStatuses: [TemplateRenderStatus] = []
        for template in templates {
            guard let modificationDate = try templateCache.modificationDate(for: template) else {
                throw InContextError.internalInconsistency("Failed to get content modification date for template '\(template)'.")
            }
            renderStatuses.append(TemplateRenderStatus(identifier: template, modificationDate: modificationDate))
        }
        return renderStatuses
    }

    func extensions() throws -> [Extension] {
        let fileManager = FileManager.default
        return try fileManager.contentsOfDirectory(at: extensionsURL, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "lua" }
            .map { extensionURL in
                let basename = (extensionURL.lastPathComponent as NSString).deletingPathExtension
                return Extension(name: basename, content: try String(contentsOf: extensionURL))
             }
    }

    func render(renderTracker: RenderTracker,
                template: String,
                context: [String: Any]) throws -> String {

        // Perform the render.
        let renderer = TiltRenderer(templateCache: templateCache, extensions: try extensions())
        let renderResult = try renderer.render(name: template, context: context)

        // Track the renderer instance and templates used.
        renderTracker.add(RendererInstance(version: type(of: renderer).self.version))
        renderTracker.add(try renderStatuses(for: renderResult.templatesUsed))

        // Prettify HTML output to make debugging a little easier.
        guard template.type?.conforms(to: .html) ?? false else {
            return renderResult.content
        }
        let dom = try SwiftSoup.parse(renderResult.content)
        return try dom.html()
    }

    func render(renderTracker: RenderTracker,
                string: String,
                filename: String,
                context: [String: Any]) throws -> String {

        // Perform the render.
        let renderer = TiltRenderer(templateCache: templateCache, extensions: try extensions())
        let renderResult = try renderer.render(string: string, filename: filename, context: context)

        // Track the renderer instance and templates used.
        // N.B. This code works around behavior currently built into Tilt that currently explicitly adds the filename
        // hint to the list of templates used.
        // #254: Tilt shouldn’t track the filename hint as a used template (https://github.com/inseven/incontext/issues/254)
        renderTracker.add(RendererInstance(version: type(of: renderer).self.version))
        renderTracker.add(try renderStatuses(for: renderResult.templatesUsed.filter { $0 != filename }))

        return renderResult.content
    }

    func clearTemplateCache() {
        templateCache.clear()
    }

}
