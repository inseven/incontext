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

class RenderManager {

    let templateCache: TemplateCache
    let renderers: [TemplateLanguage: Renderer]

    init(templateCache: TemplateCache) {
        self.templateCache = templateCache
        self.renderers = [
            .identity: IdentityRenderer(templateCache: templateCache),
            .stencil: StencilRenderer(templateCache: templateCache),
            .tilt: TiltRenderer(templateCache: templateCache),
        ]
    }

    func render(templateTracker: TemplateTracker,
                identifier: TemplateIdentifier,
                context: [String: Any]) async throws -> String {

        guard let renderer = renderers[identifier.language] else {
            throw InContextError.internalInconsistency("Failed to get renderer for language '\(identifier.language)'.")
        }

        let renderResult = try await renderer.render(name: identifier.name, context: context)

        // Generate the TemplateStatus tuples with the template content modification times.
        let templatesUsed: [TemplateIdentifier] = renderResult.templatesUsed.map { name in
            return TemplateIdentifier(identifier.language, name)
        }

        for identifier in templatesUsed {
            guard let modificationDate = templateCache.modificationDate(for: identifier) else {
                throw InContextError.internalInconsistency("Failed to get content modification date for template '\(identifier)'.")
            }
            templateTracker.add(TemplateStatus(identifier: identifier, modificationDate: modificationDate))
        }
        return renderResult.content
    }

}
