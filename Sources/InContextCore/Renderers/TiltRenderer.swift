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

import Tilt
import Lua
import CLua
import Foundation

fileprivate struct LuaStateArgumentProvider: ArgumentProvider {
    let L: LuaState

    func getArgument<T>(_ index: Int) -> T? {
        // Index is zero based (so + 1) and the first Lua stack index is the Function userdata, so add another +1
        return L.tovalue(CInt(index + 2))
    }

    func countArguments() -> Int {
        return Int(L.gettop() - 1)
    }

}

fileprivate func readFile(_ L: LuaState!) -> CInt {
    guard let templateCache: TemplateCache = L.tovalue(lua_upvalueindex(1)),
          let name = L.tostring(1),
          let template = try? templateCache.details(for: TemplateIdentifier(name)) else {
        return 0
    }
    L.push(template.contents)
    return 1
}

fileprivate func warning(_ L: LuaState!) -> CInt {
    guard let text = L.tostring(1) else {
        return 0
    }
    print(text)
    return 0
}

class TiltRenderer {

    static let version = 1

    let templateCache: TemplateCache

    let env: TiltEnvironment

    init(templateCache: TemplateCache) {
        self.templateCache = templateCache
        env = TiltEnvironment()
        let L = env.L

        L.registerMetatable(for: TemplateCache.self, functions: [:])
        L.registerDefaultMetatable(functions: [
            "__call": .closure { L in
                guard let function: Callable = L.touserdata(1) else {
                    throw InContextError.internalInconsistency("Object does not support Callable")
                }
                let result = try function.call(with: LuaStateArgumentProvider(L: L))
                L.push(any: result)
                return 1
            },
            "__index": .closure { L in
                guard let obj: EvaluationContext = L.touserdata(1) else {
                    throw InContextError.internalInconsistency("Object does not support EvaluationContext")
                }
                guard let memberName = L.tostring(2) else {
                    // Trying to lookup a non-string member, not happening
                    return 0
                }
                let result = try obj.lookup(memberName)
                L.push(any: result)
                return 1
            },
        ])

        L.pushGlobals()

        L.push(userdata: templateCache)
        lua_pushcclosure(L, readFile, 1)
        lua_setfield(L, -2, "readFile")

        lua_pushcfunction(L, warning)
        lua_setfield(L, -2, "printWarning")

        L.pop() // globals
    }

    func setContext(_ context: [String: Any]) throws {
        env.L.getglobal("setContext")
        try env.L.pcall(context)
    }

    func render(name: String, context: [String : Any]) throws -> RenderResult {
        try setContext(context)
        guard let template = try templateCache.details(for: TemplateIdentifier(name)) else {
            throw InContextError.unknownTemplate(name)
        }
        let result = try env.render(filename: name, contents: template.contents)
        return RenderResult(content: result.text, templatesUsed: result.includes)
    }

}
