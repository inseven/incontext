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

public enum InContextError: Error {
    
    case encodingError
    case internalInconsistency(String)
    case unknownSymbol(String)
    case invalidKey(Any?)
    case unknownFunction(String)
    case evaluationUnsupported(String)
    case invalidMetadata
    case unknownSchemaVersion(Int32)
    case unknownImporter(String)
    case corruptSettings
    case unexpecteArgs
    case notFound
    case unknownQuery(String)
    case invalidQueryDefinition
    case missingKey(Any)
    case interrupted
    case unknownTemplate(String)
    case importError(URL, Error)

    // Function calls.
    case incorrectType(expected: Any.Type, received: Any?)
    case incorrectArguments
    case noMatchingFunction
}

extension InContextError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .unknownTemplate(let name):
            return "Unknown template '\(name)'."
        case .internalInconsistency(let message):
            return message
        case .importError(let fileURL, let error):
            return "Failed to import file '\(fileURL.relativePath)' with error '\(error.localizedDescription)'."
        case .incorrectType(expected: let expected, received: let received):
            guard let received else {
                return "Incorrect type: expected '\(expected)', got nil."
            }
            return "Incorrect type: expected '\(expected)', got '\(received)' ('\(type(of: received))')."
        default:
            return String(describing: self)
        }
    }

}
