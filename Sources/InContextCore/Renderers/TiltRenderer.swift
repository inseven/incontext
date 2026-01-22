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
          let template = try? templateCache.details(for: name) else {
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

struct Extension {

    let name: String
    let content: String

}

struct Module {

    let table: String
    let env: LuaValue
    let mt: LuaValue

}

// Note that while methods in this class are annotated with `@available(*, noasync)`, this doesn't appear to be
// transitive (in Swift 5 at least), meaning it doesn't offer the hard compile-time guarnatees we might want.
class TiltRenderer {

    static let version = 1

    let templateCache: TemplateCache
    let extensions: [Extension]
    let modules: [Module]

    let env: TiltEnvironment

    @available(*, noasync)
    init(templateCache: TemplateCache, extensions: [Extension]) {
        self.templateCache = templateCache
        self.extensions = extensions
        env = TiltEnvironment()
        let L = env.L

        let incontextModuleEnv: LuaValue = .newtable(L)
        let incontextModuleMt: LuaValue = .newtable(L)
        incontextModuleMt["__index"] = L.globals // for now
        incontextModuleEnv.metatable = incontextModuleMt
        try! L.load(data: lua_sources["incontext"]!, name: "@incontext.lua", mode: .binary) // 1: moduleFn
        L.push(incontextModuleEnv)
        lua_setupvalue(L, 1, 1) // moduleFn->_ENV = incontextModuleEnv
        try! L.pcall(nargs: 0, nret: 0) // moduleFn()

        let incontextModule = Module(table: "incontext", env: incontextModuleEnv, mt: incontextModuleMt)

        var modules = [incontextModule]

        // Load the extensions.
        for ext in extensions {
            let moduleEnv: LuaValue = .newtable(L)
            let moduleMt: LuaValue = .newtable(L)
            moduleMt["__index"] = L.globals // for now
            moduleEnv.metatable = moduleMt
            try! L.load(string: ext.content, name: "@" + ext.name + ".lua") // 1: moduleFn
            L.push(moduleEnv)
            lua_setupvalue(L, 1, 1) // moduleFn->_ENV = moduleEnv
            try! L.pcall(nargs: 0, nret: 0) // moduleFn()
            let module = Module(table: "extensions", env: moduleEnv, mt: moduleMt)
            modules.append(module)
        }

        self.modules = modules

        L.register(Metatable<TemplateCache>())
        L.register(DefaultMetatable(
            index: .closure { L in
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
            call: .closure { L in
                guard let function: Callable = L.touserdata(1) else {
                    throw InContextError.internalInconsistency("Object does not support Callable")
                }
                let result = try function.call(with: LuaStateArgumentProvider(L: L))
                L.push(any: result)
                return 1
            }
        ))

        L.pushglobals()

        L.push(userdata: templateCache)
        lua_pushcclosure(L, readFile, 1)
        lua_setfield(L, -2, "readFile")

        lua_pushcfunction(L, warning)
        lua_setfield(L, -2, "printWarning")

        L.pop() // globals
    }

    @available(*, noasync)
    func render(string: String,
                filename: String,
                context: [String: Any]) throws -> RenderResult {
        let renderEnv = env.makeSandbox()
        // Add everything in context to renderEnv
        for (k, v) in context {
            try! renderEnv.set(k, v)
        }
        try! renderEnv.set("extensions", [:])

        // Add the extensions to the environment.
        for module in modules {
            let table = renderEnv[module.table]
            for (k, v) in try! module.env.pairs() {
                table[k] = v
            }
            // Give all the functions access to the current sandbox env.
            module.mt["__index"] = renderEnv
        }

        let result = try env.render(filename: filename, contents: string, env: renderEnv)
        return RenderResult(content: result.text, templatesUsed: result.includes)
    }

    @available(*, noasync)
    func render(name: String, context: [String : Any]) throws -> RenderResult {
        guard let template = try templateCache.details(for: name) else {
            throw InContextError.unknownTemplate(name)
        }
        return try render(string: template.contents, filename: name, context: context)
    }

}
