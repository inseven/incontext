// MIT License
//
// Copyright (c) 2023 Jason Morley
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
import Hoedown

fileprivate extension UnsafeMutablePointer where Pointee == hoedown_buffer {

    var size: size_t {
        return pointee.size
    }

    func put(_ string: String) {
        string.withCString { data in
            hoedown_buffer_put(self, data, string.count)
        }
    }

    func put(format: String, _ arguments: CVarArg...) {
        put(String(format: format, arguments: arguments))
    }

    func put(_ buffer: UnsafePointer<hoedown_buffer>) {
        hoedown_buffer_put(self, buffer.pointee.data, buffer.pointee.size)
    }

    func asString() -> String? {
        guard let cString = hoedown_buffer_cstr(self) else {
            return nil
        }
        return String(cString: cString)
    }

}

fileprivate extension UnsafePointer where Pointee == hoedown_buffer {

    func asString() -> String? {
        let data = Data(bytes: pointee.data, count: pointee.size)
        return String(data: data, encoding: .utf8)
    }

}

class Hoedown {

    struct Extensions : OptionSet {

        let rawValue: UInt32

        init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        private init(_ value: hoedown_extensions) {
            self.rawValue = value.rawValue
        }

        // Block-level extensions.
        static let tables = Extensions(HOEDOWN_EXT_TABLES)
        static let fencedCode = Extensions(HOEDOWN_EXT_FENCED_CODE)
        static let footnotes = Extensions(HOEDOWN_EXT_FOOTNOTES)

        // Span-level extensions.
        static let autolink = Extensions(HOEDOWN_EXT_AUTOLINK)
        static let strikethrough = Extensions(HOEDOWN_EXT_STRIKETHROUGH)
        static let underline = Extensions(HOEDOWN_EXT_UNDERLINE)
        static let highlight = Extensions(HOEDOWN_EXT_HIGHLIGHT)
        static let quote = Extensions(HOEDOWN_EXT_QUOTE)
        static let superscript = Extensions(HOEDOWN_EXT_SUPERSCRIPT)
        static let math = Extensions(HOEDOWN_EXT_MATH)

        // Other flags.
        static let noIntraEmphasis = Extensions(HOEDOWN_EXT_NO_INTRA_EMPHASIS)
        static let spaceHeaders = Extensions(HOEDOWN_EXT_SPACE_HEADERS)
        static let mathExplicit = Extensions(HOEDOWN_EXT_MATH_EXPLICIT)

        // Negative flags.
        static let disableIndentedCode = Extensions(HOEDOWN_EXT_DISABLE_INDENTED_CODE)

    }

    struct HTMLFlags : OptionSet {

        let rawValue: UInt32

        init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        private init(_ value: hoedown_html_flags) {
            self.rawValue = value.rawValue
        }

        static let skipHTML = HTMLFlags(HOEDOWN_HTML_SKIP_HTML)
        static let escape = HTMLFlags(HOEDOWN_HTML_ESCAPE)
        static let hardWrap = HTMLFlags(HOEDOWN_HTML_HARD_WRAP)
        static let useXHTML = HTMLFlags(HOEDOWN_HTML_USE_XHTML)
    }

    static func render(markdown: String,
                       flags: Hoedown.HTMLFlags = [],
                       extensions: Hoedown.Extensions = [],
                       useSmartyPants: Bool = false,
                       nestingLevel: Int = 0,
                       maxNesting: UInt = 16) -> String? {

        guard let renderer = hoedown_html_renderer_new(hoedown_html_flags(flags.rawValue), CInt(nestingLevel)) else {
            return nil
        }
        defer {
            hoedown_html_renderer_free(renderer)
        }

        renderer.pointee.header = { buffer, content, level, data in

            let buffer = buffer!
            let data = data!
            let state = data.pointee.opaque.assumingMemoryBound(to: hoedown_html_renderer_state.self)

            if buffer.size > 0 {
                buffer.put("\n")
            }

            if level <= state.pointee.toc_data.nesting_level {
                buffer.put(format: "<h%d id=\"toc_%d\">", level, state.pointee.toc_data.header_count)
                state.pointee.toc_data.header_count += 1
            } else {
                buffer.put(format: "<h%d>", level)
            }

            if let content {
                if let identifier = content.asString()?.safeIdentifier() {
                    buffer.put(format: "<a id=\"%@\"></a>", identifier)
                }
                buffer.put(content)
            }

            buffer.put(format: "</h%d>\n", level)
        }


        // Create the renderer.
        let document = hoedown_document_new(renderer,
                                            hoedown_extensions(extensions.rawValue),
                                            Int(maxNesting))
        defer {
            hoedown_document_free(document)
        }

        // Create the processing buffers.
        guard let outputBuffer = hoedown_buffer_new(16) else { return nil }
        defer { hoedown_buffer_free(outputBuffer) }
        guard let sourceBuffer = hoedown_buffer_new(16) else { return nil }
        defer { hoedown_buffer_free(sourceBuffer) }

        // Optionally pre-process with SmartyPants.
        if useSmartyPants {
            hoedown_html_smartypants(sourceBuffer, markdown, markdown.utf8.count);
        } else {
            hoedown_buffer_put(sourceBuffer, markdown, markdown.utf8.count);
        }

        // Process the Markdown.
        hoedown_document_render(document, outputBuffer, sourceBuffer.pointee.data, sourceBuffer.pointee.size);

        return outputBuffer.asString()
    }

}
