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

import Licensable

extension Licensable where Self == License {

    public static var incontext: License {

        let hummingbird = License(id: "https://github.com/hummingbird-project/hummingbird",
                                  name: "Hummingbird",
                                  author: "Hummingbird Authors",
                                  text: String(contentsOfResource: "hummingbird-license"),
                                  attributes: [
                                      .url(URL(string: "https://github.com/hummingbird-project/hummingbird")!,
                                           title: "GitHub"),
                                  ])

        let luaSwift = License(id: "https://github.com/tomsci/LuaSwift",
                               name: "LuaSwift",
                               author: "Tom Sutcliffe",
                               text: String(contentsOfResource: "luaswift-license"),
                               attributes: [
                                .url(URL(string: "https://github.com/tomsci/LuaSwift")!, title: "GitHub"),
                               ])

        let sqliteSwift = License(id: "https://github.com/stephencelis/SQLite.swift",
                                  name: "SQLite.swift",
                                  author: "Stephen Celis",
                                  text: String(contentsOfResource: "sqliteswift-license"),
                                  attributes: [
                                    .url(URL(string: "https://github.com/stephencelis/SQLite.swift")!, title: "GitHub"),
                                  ])

        let tilt = License(id: "https://github.com/tomsci/tomscis-lua-templater",
                           name: "Tilt",
                           author: "Tom Sutcliffe",
                           text: String(contentsOfResource: "tilt-license"),
                           attributes: [
                            .url(URL(string: "https://github.com/tomsci/tomscis-lua-templater")!,
                                 title: "GitHub"),
                           ])

        let titlecaser = License(id: "https://github.com/jwells89/Titlecaser",
                                 name: "Titlecaser",
                                 author: "John Ivan Wells",
                                 text: String(contentsOfResource: "titlecaser-license"),
                                 attributes: [
                                    .url(URL(string: "https://github.com/jwells89/Titlecaser")!,
                                         title: "GitHub"),
                                 ])

        let yams = License(id: "https://github.com/jpsim/Yams",
                           name: "Yams",
                           author: "JP Simard",
                           text: String(contentsOfResource: "yams-license"),
                           attributes: [
                            .url(URL(string: "https://github.com/jpsim/Yams")!, title: "GitHub"),
                           ])
        
        return License(id: "https://github.com/inseven/interact",
                       name: "InContext",
                       author: "Jason Morley",
                       text: String(contentsOfResource: "incontext-license"),
                       attributes: [
                           .url(URL(string: "https://github.com/inseven/incontext")!, title: "GitHub"),
                       ],
                       licenses: [
                           .licensable,
                           hummingbird,
                           luaSwift,
                           sqliteSwift,
                           titlecaser,
                           tilt,
                           yams,
                       ])
    }

}
