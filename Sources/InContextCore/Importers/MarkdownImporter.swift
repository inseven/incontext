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

class MarkdownImporter: Importer {

    struct Settings: ImporterSettings {

        let defaultCategory: String
        let defaultTemplate: String

        func combine(into fingerprint: inout Fingerprint) throws {
            try fingerprint.update(defaultCategory)
            try fingerprint.update(defaultTemplate)
        }

    }

    let identifier = "markdown"
    let version = 11

    func settings(for configuration: [String : Any]) throws -> Settings {
        return Settings(defaultCategory: try configuration.requiredValue(for: "defaultCategory"),
                        defaultTemplate: try configuration.requiredValue(for: "defaultTemplate"))
    }

    func process(file: File,
                 settings: Settings,
                 outputURL: URL) async throws -> ImporterResult {

        let fileURL = file.url
        let details = fileURL.basenameDetails()
        let frontmatter = try FrontmatterDocument(contentsOf: fileURL, generateHTML: true)

        // Merge the details and metadata.
        var metadata = [AnyHashable: Any]()
        metadata["title"] = details.title
        metadata.merge(frontmatter.metadata) { $1 }

        let category: String = try metadata.value(for: "category", default: settings.defaultCategory)

        let document = try Document(url: fileURL.siteURL,
                                    parent: fileURL.parentURL,
                                    category: category,
                                    date: frontmatter.structuredMetadata.date ?? details.date,
                                    title: frontmatter.structuredMetadata.title ?? details.title,
                                    metadata: metadata,
                                    contents: frontmatter.content,
                                    contentModificationDate: file.contentModificationDate,
                                    template: frontmatter.structuredMetadata.template ?? settings.defaultTemplate,
                                    inlineTemplate: nil,
                                    relativeSourcePath: file.relativePath,
                                    format: .text)
        return ImporterResult(document: document)
    }

}
