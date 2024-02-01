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

class RenderTracker {

    private let site: Site
    private let store: Store
    private let renderManager: RenderManager
    private var queries = Set<QueryStatus>()
    private var renderers = Set<RendererInstance>()
    private var statuses = Set<TemplateRenderStatus>()

    init(site: Site, store: Store, renderManager: RenderManager) {
        self.site = site
        self.store = store
        self.renderManager = renderManager
    }

    func add(_ rendererInstance: RendererInstance) {
        renderers.insert(rendererInstance)
    }

    func add(_ templateStatus: TemplateRenderStatus) {
        statuses.insert(templateStatus)
    }

    func documents(query: QueryDescription) throws -> [Document] {
        let documents = try store.documents(query: query)
        queries.insert(QueryStatus(query: query,
                                   fingerprints: documents.map({ $0.fingerprint })))
        return documents
    }

    func documentContexts(query: QueryDescription) throws -> [DocumentContext] {
        return try documents(query: query)
            .map { DocumentContext(renderTracker: self, document: $0) }
    }

    func renderStatus(for document: Document) -> RenderStatus {
        return RenderStatus(documentFingerprint: document.fingerprint,
                            queries: Array(queries),
                            renderers: Array(renderers),
                            templates: Array(statuses))
    }

    func render(_ document: Document, template: TemplateIdentifier? = nil) throws -> String {
        let template = template ?? document.template
        let context = Builder.context(for: site, document: document, renderTracker: self)
        return try renderManager.render(renderTracker: self, template: template, context: context)
    }

}
