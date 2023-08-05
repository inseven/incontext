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
import TiltC
import Foundation

fileprivate struct LuaStateArgumentProvider: ArgumentProvider {
    let L: LuaState!
    func withArguments<Result>(perform: ([Any?]) throws -> Result) throws -> Result {
        var arguments: [Any?] = []
        for i in 1 ... L.gettop() {
            // First arg is the Function userdata itself
            if i > 1 {
                arguments.append(L.toany(i))
            }
        }
        return try perform(arguments)
    }
}

extension LuaStringRef: Convertible {
    func convertToType(_ t: Any.Type) -> Any? {
        if t == String.self {
            return toString(encoding: .stringEncoding(.utf8))
        } else if t == Data.self {
            return toData()
        } else {
            return nil
        }
    }
}

extension LuaTableRef: Convertible {
    func convertToType(_ t: Any.Type) -> Any? {
        if t == Dictionary<AnyHashable, Any>.self {
            return toDict()
        } else if t == Array<Any>.self {
            return toArray()
        } else {
            return nil
        }
    }
}

fileprivate func callFunctionBlock(_ L: LuaState!) -> CInt {
    return L.convertThrowToError {
        guard let function: Callable = L.touserdata(1) else {
            throw LuaCallError("Object does not support Callable")
        }
        let result = try function.call(with: LuaStateArgumentProvider(L: L))
        L.pushany(result)
        return 1
    }
}

fileprivate func lookupViaEvaluationContext(_ L: LuaState!) -> CInt {
    return L.convertThrowToError {
        guard let obj: EvaluationContext = L.touserdata(1) else {
            throw LuaCallError("Object does not support EvaluationContext")
        }
        guard let memberName = L.tostring(2) else {
            // Trying to lookup a non-string member, not happening
            return 0
        }
        let result = try obj.lookup(memberName)
        L.pushany(result)
        return 1
    }
}

fileprivate func readFile(_ L: LuaState!) -> CInt {
    guard let templateCache: TemplateCache = L.tovalue(lua_upvalueindex(1)),
          let name = L.tostring(1),
          let template = templateCache.details(for: .tilt(name)) else {
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

class TiltRenderer: Renderer {

    let version = 1

    let templateCache: TemplateCache

    let env: TiltEnvironment

    init(templateCache: TemplateCache) {
        self.templateCache = templateCache
        env = TiltEnvironment()
        let L = env.L

        L.registerMetatable(for: TemplateCache.self, functions: [:])
        L.registerDefaultMetatable(functions: [
            "__call": callFunctionBlock,
            "__index": lookupViaEvaluationContext
        ])

        L.pushGlobals()

        L.pushuserdata(templateCache)
        lua_pushcclosure(L, readFile, 1)
        lua_setfield(L, -2, "readFile")

        lua_pushcfunction(L, warning)
        lua_setfield(L, -2, "printWarning")

        L.pop() // globals
    }

    func setContext(_ context: [String: Any]) throws {
        env.L.getglobal("setContext")
        try env.L.pcall(arguments: context)
    }

    func render(name: String, context: [String : Any]) async throws -> RenderResult {
        try setContext(context)
        guard let template = templateCache.details(for: .tilt(name)) else {
            throw InContextError.unknownTemplate(TemplateIdentifier.tilt(name).rawValue)
        }
        let result = try env.render(filename: name, contents: template.contents)
        return RenderResult(content: result.text, templatesUsed: result.includes)
    }

}
