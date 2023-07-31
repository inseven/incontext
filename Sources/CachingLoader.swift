//
//  File 2.swift
//  
//
//  Created by Jason Barrie Morley on 26/07/2023.
//

import Foundation

import Stencil

class CachingLoader: Loader {

    let templateCache: TemplateCache
    var cache: [String: Template] = [:]

    init(templateCache: TemplateCache) {
        self.templateCache = templateCache
    }

    func loadTemplate(name: String, environment: Stencil.Environment) throws -> Template {
        if let template = cache[name] {
            return template
        }
        guard let details = templateCache.details(language: .stencil, name: name) else {
            throw InContextError.unknownTemplate(name)
        }
        let template = try Template(templateString: details.contents, environment: environment, name: name)
        cache[name] = template
        return template
    }

}
