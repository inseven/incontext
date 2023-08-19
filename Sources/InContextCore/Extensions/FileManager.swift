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

public extension FileManager {

    var currentDirectoryURL: URL {
        return URL(filePath: currentDirectoryPath, directoryHint: .isDirectory)
    }

    func modificationDateOfItem(at url: URL) throws -> Date {
        let attr = try attributesOfItem(atPath: url.path)
        guard let modificationDate = attr[FileAttributeKey.modificationDate] as? Date else {
            throw InContextError.internalInconsistency("Failed to get modification date for '\(url.relativePath)'")
        }
        return modificationDate
    }

    func fileExists(at url: URL, isDirectory: UnsafeMutablePointer<ObjCBool>) -> Bool {
        precondition(url.isFileURL)
        return fileExists(atPath: url.path, isDirectory: isDirectory)
    }

    func fileExists(at url: URL) -> Bool {
        precondition(url.isFileURL)
        return fileExists(atPath: url.path)
    }

    func directoryExists(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let fileExists = fileExists(at: url, isDirectory: &isDirectory)
        return fileExists && isDirectory.boolValue
    }

}
