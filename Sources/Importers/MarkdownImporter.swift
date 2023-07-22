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

class MarkdownImporter: Importer {

    let identifier = "app.incontext.importer.markdown"
    let legacyIdentifier = "import_markdown"
    let version = 5

    func process(site: Site, file: File, settings: [AnyHashable: Any]) async throws -> ImporterResult {

        let fileURL = file.url

        let data = try Data(contentsOf: fileURL)
        guard let contents = String(data: data, encoding: .utf8) else {
            throw InContextError.unsupportedEncoding
        }
        let details = fileURL.basenameDetails()

        let result = try FrontmatterDocument(contents: contents, generateHTML: true)

        // Set the title if it doesn't exist.
        var metadata = [AnyHashable: Any]()
        metadata.merge(result.metadata) { $1 }
        if metadata["title"] == nil {
            metadata["title"] = details.title
        }

        // TODO: The metadata doesn't seem to permit complex structure; I might have to create my own parser.
        // TODO: There's a bunch of legacy code which detects thumbnails. *sigh*
        //       I think it might actually be possible to do this with the template engine.

        // TODO: Do I actually wnat it to process the markdown at import time? Does it matter?
        let document = Document(url: fileURL.siteURL,
                                parent: fileURL.parentURL,
                                type: "",
                                date: details.date,
                                metadata: metadata,
                                contents: result.content,
                                mtime: file.contentModificationDate,
                                template: (metadata["template"] as? String) ?? "page.html")  // TODO: Use a default for this.
        return ImporterResult(documents: [document])
    }

}
