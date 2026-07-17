// MIT License
//
// Copyright (c) 2016-2026 Jason Morley
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

#if canImport(FoundationXML)
import FoundationXML
#endif

struct XMPMetadata {

    private static let dublinCoreNamespace = "http://purl.org/dc/elements/1.1/"
    private static let rdfNamespace = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"

    let title: String?
    let mediaDescription: String?

    init?(data: Data) {
        let parser = XMLParser(data: data)
        parser.shouldProcessNamespaces = true
        let delegate = Delegate()
        parser.delegate = delegate
        guard parser.parse() else {
            return nil
        }
        self.title = delegate.title
        self.mediaDescription = delegate.mediaDescription
    }

    private class Delegate: NSObject, XMLParserDelegate {

        private enum Property {
            case title
            case mediaDescription
        }

        var title: String?
        var mediaDescription: String?

        private var property: Property? = nil
        private var buffer: String? = nil

        func parser(_ parser: XMLParser,
                    didStartElement elementName: String,
                    namespaceURI: String?,
                    qualifiedName qName: String?,
                    attributes attributeDict: [String: String]) {
            if namespaceURI == XMPMetadata.dublinCoreNamespace {
                switch elementName {
                case "title":
                    property = .title
                case "description":
                    property = .mediaDescription
                default:
                    break
                }
            } else if namespaceURI == XMPMetadata.rdfNamespace, elementName == "li", property != nil {
                buffer = ""
            }
        }

        func parser(_ parser: XMLParser, foundCharacters string: String) {
            buffer? += string
        }

        func parser(_ parser: XMLParser,
                    didEndElement elementName: String,
                    namespaceURI: String?,
                    qualifiedName qName: String?) {
            if namespaceURI == XMPMetadata.rdfNamespace, elementName == "li", let buffer {
                switch property {
                case .title:
                    title = title ?? buffer
                case .mediaDescription:
                    mediaDescription = mediaDescription ?? buffer
                case .none:
                    break
                }
                self.buffer = nil
            } else if namespaceURI == XMPMetadata.dublinCoreNamespace,
                      elementName == "title" || elementName == "description" {
                property = nil
            }
        }

    }

}
