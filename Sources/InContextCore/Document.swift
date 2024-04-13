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
    let metadata: [AnyHashable: Any]
    let contents: String
    let contentModificationDate: Date
    let template: String
    let inlineTemplate: String?
    let relativeSourcePath: String
    let format: Format
    let depth: Int

    let fingerprint: String

    init(url: String,
         parent: String,
         category: String,
         date: Date?,
         title: String?,
         metadata: [AnyHashable: Any],
         contents: String,
         contentModificationDate: Date,
         template: String,
         inlineTemplate: String?,
         relativeSourcePath: String,
         format: Format,
         depth: Int,
         fingerprint: String) {
        self.url = url
        self.parent = parent
        self.category = category
        self.date = date
        self.title = title
        self.metadata = metadata
        self.contents = contents
        self.contentModificationDate = contentModificationDate
        self.template = template
        self.inlineTemplate = inlineTemplate
        self.relativeSourcePath = relativeSourcePath
        self.format = format
        self.depth = depth
        self.fingerprint = fingerprint
    }

    init(url: String,
         parent: String,
         category: String,
         date: Date?,
         title: String?,
         metadata: [AnyHashable: Any],
         contents: String,
         contentModificationDate: Date,
         template: String,
         inlineTemplate: String?,
         relativeSourcePath: String,
         format: Format) throws {
        self.url = url
        self.parent = parent
        self.category = category
        self.date = date
        self.title = title
        self.metadata = metadata
        self.contents = contents
        self.contentModificationDate = contentModificationDate
        self.template = template
        self.inlineTemplate = inlineTemplate
        self.relativeSourcePath = relativeSourcePath
        self.format = format
        self.depth = url.pathDepth

        var fingerprint = Fingerprint()
        try fingerprint.update(url)
        try fingerprint.update(parent)
        try fingerprint.update(category)
        try fingerprint.update(date ?? Date.distantPast)
        try fingerprint.update(title ?? "-")
        try fingerprint.update(metadata)
        try fingerprint.update(contents)
        try fingerprint.update(contentModificationDate)
        try fingerprint.update(template)
        try fingerprint.update(inlineTemplate ?? "-")
        try fingerprint.update(relativeSourcePath)
        try fingerprint.update(format.rawValue)
        self.fingerprint = fingerprint.finalize()
    }

}
