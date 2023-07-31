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
import Yams

class MarkdownImporter: Importer {

    struct Settings: ImporterSettings {

        let defaultCategory: String
        let defaultTemplate: TemplateIdentifier

        func combine(into fingerprint: inout Fingerprint) throws {
            try fingerprint.update(defaultCategory)
            try fingerprint.update(defaultTemplate)
        }

    }

    let identifier = "import_markdown"
    let version = 11

    func settings(for configuration: [String : Any]) throws -> Settings {
        let args: [String: Any] = try configuration.requiredValue(for: "args")
        return Settings(defaultCategory: try args.requiredValue(for: "default_category"),
                        defaultTemplate: try args.requiredRawRepresentable(for: "default_template"))
    }

    func process(site: Site, file: File, settings: Settings) async throws -> ImporterResult {

        let fileURL = file.url

        let data = try Data(contentsOf: fileURL)
        guard let contents = String(data: data, encoding: .utf8) else {
            throw InContextError.unsupportedEncoding
        }
        let details = fileURL.basenameDetails()

        // TODO: Rename to frontmatter
        let result = try FrontmatterDocument(contents: contents, generateHTML: true)

        // Set the title if it doesn't exist.
        var metadata = [AnyHashable: Any]()
        metadata.merge(result.metadata) { $1 }
        if metadata["title"] == nil {
            metadata["title"] = details.title
        }

        // Strict metadata parsing.
        let decoder = YAMLDecoder()
        let structuredMetadata = (!result.rawMetadata.isEmpty ?
                                  try decoder.decode(Metadata.self, from: result.rawMetadata) :
                                    Metadata())

        let category: String = try metadata.value(for: "category", default: settings.defaultCategory)

        // TODO: There's a bunch of legacy code which detects thumbnails. *sigh*
        //       I think it might actually be possible to do this with the template engine.

        let document = Document(url: fileURL.siteURL,
                                parent: fileURL.parentURL,
                                type: category,
                                date: structuredMetadata.date ?? details.date,
                                metadata: metadata,
                                contents: result.content,
                                contentModificationDate: file.contentModificationDate,
                                template: structuredMetadata.template ?? settings.defaultTemplate,
                                relativeSourcePath: file.relativePath)
        return ImporterResult(documents: [document])
    }

}
