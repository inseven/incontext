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

// Corrects relative paths for images have been stored in the database.
// Fails silently for documents that do not have a corresponding destination in the site.
// TODO: We need to store the source to destination mapping for all files in the site (including copied files) to allow
//       for a nice clean transform at this level that doesn't involve guessing.
// TODO: These transforms also need rigorous testing
struct ImageDocumentTransform: Transformer {

    func transform(store: QueryTracker, document: DocumentContext, content: SwiftSoup.Document) throws {
        for img in try content.getElementsByTag("img") {
            if img.hasAttr("src") {
                let src = try img.attr("src")
                let newSrc = document.relativeSourcePath(for: src)
//                print("\(src) -> \(newSrc)")
                let query = QueryDescription(relativeSourcePath: newSrc)
                guard let document = try store.documents(query: query).first else {
                    print("Failed to update src for '\(src)'.")
                    continue
                }
                guard let image = document.metadata["image"] as? [String: Any],
                      let url = image["url"] as? String else {
                    throw InContextError.internalInconsistency("Failed to fetch image metadata")
                }
                try img.attr("src", url)
            }
        }
    }

}
