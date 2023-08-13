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

class RenderManager {

    private let templateCache: TemplateCache

    private let syncQueue = DispatchQueue(label: "RenderManager.syncQueue")
    private var renderers: [TiltRenderer] = []

    init(templateCache: TemplateCache) {
        self.templateCache = templateCache
    }

    var rendererVersion: Int {
        return TiltRenderer.version
    }

    func render(renderTracker: RenderTracker,
                template: TemplateIdentifier,
                context: [String: Any]) throws -> String {

        let renderer = TiltRenderer(templateCache: templateCache)
//        let renderer = syncQueue.sync { renderers.popLast() } ?? TiltRenderer(templateCache: templateCache)
//        defer {
//            syncQueue.async {
//                self.renderers.append(renderer)
//            }
//        }

        // Perform the render.
        let renderResult = try renderer.render(name: template.name, context: context)

        // Record the renderer instance used.
        // It is sufficient to record this once for the whole render operation even though multiple templates might be
        // used, as we do not allow mixing of template languages within a single top-level render.
        renderTracker.add(RendererInstance(version: type(of: renderer).self.version))

        // Generate language-scoped identifiers for the templates reported as used by the renderer.
        let templatesUsed: [TemplateIdentifier] = renderResult.templatesUsed.map { name in
            return TemplateIdentifier(name)
        }

        // Look-up the modification date for each template, generate an associated render status, and add this to the
        // tracker.
        for template in templatesUsed {
            guard let modificationDate = try templateCache.modificationDate(for: template) else {
                throw InContextError.internalInconsistency("Failed to get content modification date for template '\(template)'.")
            }
            renderTracker.add(TemplateRenderStatus(identifier: template, modificationDate: modificationDate))
        }

        // Prettify HTML output to make debugging a little easier.
        guard template.type?.conforms(to: .html) ?? false else {
            return renderResult.content
        }
        let dom = try SwiftSoup.parse(renderResult.content)
        return try dom.html()
    }

    func clearCache() {
        templateCache.clear()
    }

}
