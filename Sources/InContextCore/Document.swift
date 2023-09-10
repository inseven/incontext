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

struct Document {

    enum Format: String, Codable {
        case text
        case image
        case video
    }

    let url: String
    let parent: String
    let category: String
    let date: Date?
    let title: String?
    let thumbnail: String?
    let queries: [String: QueryDescription]
    let metadata: [String: Any]
    let contents: String
    let contentModificationDate: Date
    let template: TemplateIdentifier
    let inlineTemplate: TemplateIdentifier?
    let relativeSourcePath: String
    let format: Format

    let fingerprint: String

    init(url: String,
         parent: String,
         category: String,
         date: Date?,
         title: String?,
         thumbnail: String?,
         queries: [String: QueryDescription] = [:],
         metadata: [String: Any],
         contents: String,
         contentModificationDate: Date,
         template: TemplateIdentifier,
         inlineTemplate: TemplateIdentifier?,
         relativeSourcePath: String,
         format: Format,
         fingerprint: String) {
        self.url = url
        self.parent = parent
        self.category = category
        self.date = date
        self.title = title
        self.thumbnail = thumbnail
        self.queries = queries
        self.metadata = metadata
        self.contents = contents
        self.contentModificationDate = contentModificationDate
        self.template = template
        self.inlineTemplate = inlineTemplate
        self.relativeSourcePath = relativeSourcePath
        self.format = format
        self.fingerprint = fingerprint
    }

    init(url: String,
         parent: String,
         category: String,
         date: Date?,
         title: String?,
         thumbnail: String?,
         queries: [String: QueryDescription],
         metadata: [String: Any],
         contents: String,
         contentModificationDate: Date,
         template: TemplateIdentifier,
         inlineTemplate: TemplateIdentifier?,
         relativeSourcePath: String,
         format: Format) throws {
        self.url = url
        self.parent = parent
        self.category = category
        self.date = date
        self.title = title
        self.thumbnail = thumbnail
        self.queries = queries
        self.metadata = metadata
        self.contents = contents
        self.contentModificationDate = contentModificationDate
        self.template = template
        self.inlineTemplate = inlineTemplate
        self.relativeSourcePath = relativeSourcePath
        self.format = format

        var fingerprint = Fingerprint()
        try fingerprint.update(url)
        try fingerprint.update(category)
        if let date {
            try fingerprint.update(date)
        }
        if let title {
            try fingerprint.update(title)
        }
        try fingerprint.update(queries)
        try fingerprint.update(metadata)
        try fingerprint.update(contents)
        try fingerprint.update(contentModificationDate)
        try fingerprint.update(template)
        if let inlineTemplate {
            try fingerprint.update(inlineTemplate)
        }
        self.fingerprint = fingerprint.finalize()
    }

}
