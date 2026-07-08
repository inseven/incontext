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

import Licensable

fileprivate let fseventsWrapperLicense = License(id: "https://github.com/Frizlab/FSEventsWrapper",
                                                 name: "FSEventsWrapper",
                                                 author: "François Lamboley",
                                                 text: String(contentsOfResource: "fseventswrapper-license"),
                                                 attributes: [
                                                    .url(URL(string: "https://github.com/Frizlab/FSEventsWrapper")!,
                                                         title: "GitHub"),
                                                 ])

fileprivate let hoedownLicense = License(id: "https://github.com/hoedown/hoedown",
                                         name: "Hoedown",
                                         author: "Hoedown Authors",
                                         text: String(contentsOfResource: "hoedown-license"),
                                         attributes: [
                                            .url(URL(string: "https://github.com/hoedown/hoedown")!, title: "GitHub"),
                                         ])

fileprivate let hummingbirdLicense = License(id: "https://github.com/hummingbird-project/hummingbird",
                                             name: "Hummingbird",
                                             author: "Hummingbird Authors",
                                             text: String(contentsOfResource: "hummingbird-license"),
                                             attributes: [
                                                .url(URL(string: "https://github.com/hummingbird-project/hummingbird")!,
                                                     title: "GitHub"),
                                             ])

fileprivate let hummingbirdCoreLicense = License(id: "https://github.com/hummingbird-project/hummingbird-core",
                                                 name: "HummingbirdCore",
                                                 author: "Hummingbird Authors",
                                                 text: String(contentsOfResource: "hummingbirdcore-license"),
                                                 attributes: [
                                                    .url(URL(string: "https://github.com/hummingbird-project/hummingbird-core")!,
                                                         title: "GitHub"),
                                                 ])

fileprivate let lruCacheLicense = License(id: "https://github.com/nicklockwood/LRUCache",
                                          name: "LRUCache",
                                          author: "Nick Lockwood",
                                          text: String(contentsOfResource: "lrucache-license"),
                                          attributes: [
                                            .url(URL(string: "https://github.com/nicklockwood/LRUCache")!, title: "GitHub"),
                                          ])

fileprivate let luaSwiftLicense = License(id: "https://github.com/tomsci/LuaSwift",
                                          name: "LuaSwift",
                                          author: "Tom Sutcliffe",
                                          text: String(contentsOfResource: "luaswift-license"),
                                          attributes: [
                                            .url(URL(string: "https://github.com/tomsci/LuaSwift")!, title: "GitHub"),
                                          ])

fileprivate let sqliteSwiftLicense = License(id: "https://github.com/stephencelis/SQLite.swift",
                                             name: "SQLite.swift",
                                             author: "Stephen Celis",
                                             text: String(contentsOfResource: "sqliteswift-license"),
                                             attributes: [
                                                .url(URL(string: "https://github.com/stephencelis/SQLite.swift")!,
                                                     title: "GitHub"),
                                             ])

fileprivate let swiftAlgorithmsLicense = License(id: "https://github.com/apple/swift-algorithms",
                                                 name: "Swift Algorithms",
                                                 author: "Apple Inc.",
                                                 text: String(contentsOfResource: "swiftalgorithms-license"),
                                                 attributes: [
                                                    .url(URL(string: "https://github.com/apple/swift-algorithms")!,
                                                         title: "GitHub"),
                                                 ])

fileprivate let swiftArgumentParserLicense = License(id: "https://github.com/apple/swift-argument-parser",
                                                     name: "Swift Argument Parser",
                                                     author: "Apple Inc.",
                                                     text: String(contentsOfResource: "swiftargumentparser-license"),
                                                     attributes: [
                                                        .url(URL(string: "https://github.com/apple/swift-argument-parser")!,
                                                             title: "GitHub"),
                                                     ])

fileprivate let swiftAtomicsLicense = License(id: "https://github.com/apple/swift-atomics",
                                              name: "Swift Atomics",
                                              author: "Apple Inc.",
                                              text: String(contentsOfResource: "swiftatomics-license"),
                                              attributes: [
                                                .url(URL(string: "https://github.com/apple/swift-atomics")!, title: "GitHub"),
                                              ])

fileprivate let swiftBacktraceLicense = License(id: "https://github.com/swift-server/swift-backtrace",
                                                name: "Backtrace",
                                                author: "Swift Server Working Group",
                                                text: String(contentsOfResource: "swiftbacktrace-license"),
                                                attributes: [
                                                    .url(URL(string: "https://github.com/swift-server/swift-backtrace")!,
                                                         title: "GitHub"),
                                                ])

fileprivate let swiftCollectionsLicense = License(id: "https://github.com/apple/swift-collections",
                                                  name: "Swift Collections",
                                                  author: "Apple Inc.",
                                                  text: String(contentsOfResource: "swiftcollections-license"),
                                                  attributes: [
                                                    .url(URL(string: "https://github.com/apple/swift-collections")!,
                                                         title: "GitHub"),
                                                  ])

fileprivate let swiftCryptoLicense = License(id: "https://github.com/apple/swift-crypto",
                                             name: "Swift Crypto",
                                             author: "Apple Inc.",
                                             text: String(contentsOfResource: "swiftcrypto-license"),
                                             attributes: [
                                                .url(URL(string: "https://github.com/apple/swift-crypto")!, title: "GitHub"),
                                             ])

fileprivate let swiftDistributedTracingLicense = License(id: "https://github.com/apple/swift-distributed-tracing",
                                                         name: "Swift Distributed Tracing",
                                                         author: "Apple Inc.",
                                                         text: String(contentsOfResource: "swiftdistributedtracing-license"),
                                                         attributes: [
                                                            .url(URL(string: "https://github.com/apple/swift-distributed-tracing")!,
                                                                 title: "GitHub"),
                                                         ])

fileprivate let swiftHTTPStructuredHeadersLicense = License(id: "https://github.com/apple/swift-http-structured-headers",
                                                            name: "Swift HTTP Structured Headers",
                                                            author: "Apple Inc.",
                                                            text: String(contentsOfResource: "swifthttpstructuredheaders-license"),
                                                            attributes: [
                                                                .url(URL(string: "https://github.com/apple/swift-http-structured-headers")!,
                                                                     title: "GitHub"),
                                                            ])

fileprivate let swiftHTTPTypesLicense = License(id: "https://github.com/apple/swift-http-types",
                                                name: "Swift HTTP Types",
                                                author: "Apple Inc.",
                                                text: String(contentsOfResource: "swifthttptypes-license"),
                                                attributes: [
                                                    .url(URL(string: "https://github.com/apple/swift-http-types")!,
                                                         title: "GitHub"),
                                                ])

fileprivate let swiftLogLicense = License(id: "https://github.com/apple/swift-log",
                                          name: "SwiftLog",
                                          author: "Apple Inc.",
                                          text: String(contentsOfResource: "swiftlog-license"),
                                          attributes: [
                                            .url(URL(string: "https://github.com/apple/swift-log")!, title: "GitHub"),
                                          ])

fileprivate let swiftMetricsLicense = License(id: "https://github.com/apple/swift-metrics",
                                              name: "SwiftMetrics",
                                              author: "Apple Inc.",
                                              text: String(contentsOfResource: "swiftmetrics-license"),
                                              attributes: [
                                                .url(URL(string: "https://github.com/apple/swift-metrics")!, title: "GitHub"),
                                              ])

fileprivate let swiftNIOLicense = License(id: "https://github.com/apple/swift-nio",
                                          name: "SwiftNIO",
                                          author: "Apple Inc.",
                                          text: String(contentsOfResource: "swiftnio-license"),
                                          attributes: [
                                            .url(URL(string: "https://github.com/apple/swift-nio")!, title: "GitHub"),
                                          ])

fileprivate let swiftNIOExtrasLicense = License(id: "https://github.com/apple/swift-nio-extras",
                                                name: "NIOExtras",
                                                author: "Apple Inc.",
                                                text: String(contentsOfResource: "swiftnioextras-license"),
                                                attributes: [
                                                    .url(URL(string: "https://github.com/apple/swift-nio-extras")!,
                                                         title: "GitHub"),
                                                ])

fileprivate let swiftNIOHTTP2License = License(id: "https://github.com/apple/swift-nio-http2",
                                               name: "SwiftNIO HTTP/2",
                                               author: "Apple Inc.",
                                               text: String(contentsOfResource: "swiftniohttp2-license"),
                                               attributes: [
                                                .url(URL(string: "https://github.com/apple/swift-nio-http2")!, title: "GitHub"),
                                               ])

fileprivate let swiftNIOSSLLicense = License(id: "https://github.com/apple/swift-nio-ssl",
                                            name: "SwiftNIO SSL",
                                            author: "Apple Inc.",
                                            text: String(contentsOfResource: "swiftniossl-license"),
                                            attributes: [
                                                .url(URL(string: "https://github.com/apple/swift-nio-ssl")!, title: "GitHub"),
                                            ])

fileprivate let swiftNIOTransportServicesLicense = License(id: "https://github.com/apple/swift-nio-transport-services",
                                                           name: "NIO Transport Services",
                                                           author: "Apple Inc.",
                                                           text: String(contentsOfResource: "swiftniotransportservices-license"),
                                                           attributes: [
                                                            .url(URL(string: "https://github.com/apple/swift-nio-transport-services")!,
                                                                 title: "GitHub"),
                                                           ])

fileprivate let swiftNumericsLicense = License(id: "https://github.com/apple/swift-numerics",
                                               name: "Swift Numerics",
                                               author: "Apple Inc.",
                                               text: String(contentsOfResource: "swiftnumerics-license"),
                                               attributes: [
                                                .url(URL(string: "https://github.com/apple/swift-numerics")!, title: "GitHub"),
                                               ])

fileprivate let swiftServiceContextLicense = License(id: "https://github.com/apple/swift-service-context",
                                                     name: "Swift Service Context",
                                                     author: "Apple Inc.",
                                                     text: String(contentsOfResource: "swiftservicecontext-license"),
                                                     attributes: [
                                                        .url(URL(string: "https://github.com/apple/swift-service-context")!,
                                                             title: "GitHub"),
                                                     ])

fileprivate let swiftServiceLifecycleLicense = License(id: "https://github.com/swift-server/swift-service-lifecycle",
                                                       name: "Swift Service Lifecycle",
                                                       author: "Swift Server Working Group",
                                                       text: String(contentsOfResource: "swiftservicelifecycle-license"),
                                                       attributes: [
                                                        .url(URL(string: "https://github.com/swift-server/swift-service-lifecycle")!,
                                                             title: "GitHub"),
                                                       ])

fileprivate let swiftSoupLicense = License(id: "https://github.com/scinfu/SwiftSoup",
                                           name: "SwiftSoup",
                                           author: "Nabil Chatbi",
                                           text: String(contentsOfResource: "swiftsoup-license"),
                                           attributes: [
                                            .url(URL(string: "https://github.com/scinfu/SwiftSoup")!, title: "GitHub"),
                                           ])

fileprivate let swiftSystemLicense = License(id: "https://github.com/apple/swift-system",
                                             name: "Swift System",
                                             author: "Apple Inc.",
                                             text: String(contentsOfResource: "swiftsystem-license"),
                                             attributes: [
                                                .url(URL(string: "https://github.com/apple/swift-system")!, title: "GitHub"),
                                             ])

fileprivate let tiltLicense = License(id: "https://github.com/tomsci/tomscis-lua-templater",
                                      name: "Tilt",
                                      author: "Tom Sutcliffe",
                                      text: String(contentsOfResource: "tilt-license"),
                                      attributes: [
                                        .url(URL(string: "https://github.com/tomsci/tomscis-lua-templater")!,
                                             title: "GitHub"),
                                      ])

fileprivate let titlecaserLicense = License(id: "https://github.com/jwells89/Titlecaser",
                                            name: "Titlecaser",
                                            author: "John Ivan Wells",
                                            text: String(contentsOfResource: "titlecaser-license"),
                                            attributes: [
                                                .url(URL(string: "https://github.com/jwells89/Titlecaser")!,
                                                     title: "GitHub"),
                                            ])

fileprivate let yamsLicense = License(id: "https://github.com/jpsim/Yams",
                                      name: "Yams",
                                      author: "JP Simard",
                                      text: String(contentsOfResource: "yams-license"),
                                      attributes: [
                                        .url(URL(string: "https://github.com/jpsim/Yams")!, title: "GitHub"),
                                      ])

fileprivate let incontextLicense = License(id: "https://github.com/inseven/incontext",
                                           name: "InContext",
                                           author: "Jason Morley",
                                           text: String(contentsOfResource: "incontext-license"),
                                           attributes: [
                                            .url(URL(string: "https://github.com/inseven/incontext")!, title: "GitHub"),
                                           ],
                                           licenses: [
                                            .licensable,
                                            fseventsWrapperLicense,
                                            hoedownLicense,
                                            hummingbirdLicense,
                                            hummingbirdCoreLicense,
                                            lruCacheLicense,
                                            luaSwiftLicense,
                                            sqliteSwiftLicense,
                                            swiftAlgorithmsLicense,
                                            swiftArgumentParserLicense,
                                            swiftAtomicsLicense,
                                            swiftBacktraceLicense,
                                            swiftCollectionsLicense,
                                            swiftCryptoLicense,
                                            swiftDistributedTracingLicense,
                                            swiftHTTPStructuredHeadersLicense,
                                            swiftHTTPTypesLicense,
                                            swiftLogLicense,
                                            swiftMetricsLicense,
                                            swiftNIOLicense,
                                            swiftNIOExtrasLicense,
                                            swiftNIOHTTP2License,
                                            swiftNIOSSLLicense,
                                            swiftNIOTransportServicesLicense,
                                            swiftNumericsLicense,
                                            swiftServiceContextLicense,
                                            swiftServiceLifecycleLicense,
                                            swiftSoupLicense,
                                            swiftSystemLicense,
                                            tiltLicense,
                                            titlecaserLicense,
                                            yamsLicense,
                                           ])


extension Licensable where Self == License {

    public static var incontext: License { incontextLicense }

}
