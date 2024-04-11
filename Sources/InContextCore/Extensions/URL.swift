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

#if canImport(UniformTypeIdentifiers)

import UniformTypeIdentifiers

#endif

import Titlecaser
import RegexBuilder

extension URL {

    var isIndex: Bool {
        return deletingPathExtension().lastPathComponent == "index"
    }

    var relevantURL: URL {
        return isIndex ? deletingLastPathComponent() : deletingPathExtension()
    }

    var relevantRelativePath: String {
        return relevantURL.relativePath
    }

    // TODO: Rename this.
    var siteURL: String {
        let relevantRelativePath = relevantRelativePath
        // TODO: This feels broken!
        if relevantRelativePath.hasPrefix(".") {
            return "/"
        }
        return relevantRelativePath.ensuringLeadingSlash().ensuringTrailingSlash()
    }

    var parentURL: String {
        // TODO: Should be nullable.
        let relevantParentPath = relevantURL.deletingLastPathComponent().relativePath
        if relevantParentPath == ".." || relevantParentPath == "." {
            return "/"
        }
        return relevantParentPath.ensuringLeadingSlash().ensuringTrailingSlash()
    }

    func basenameDetails() -> BasenameDetails {
        if relevantURL.relativePath == "." {
            return BasenameDetails(date: nil, title: nil, scale: nil)
        }
        let relevantBasename = relevantURL.deletingPathExtension().lastPathComponent
        return BasenameDetails(basename: relevantBasename)
    }

    var type: UTType? {
        return UTType(filenameExtension: pathExtension)
    }

}

#if os(Linux)

enum DirectoryHint {

    case isDirectory
    case notDirectory

}

extension URL {

    init(filePath: String, directoryHint: DirectoryHint = .notDirectory) {
        self.init(fileURLWithPath: filePath, isDirectory: directoryHint == .isDirectory ? true : false)
    }

    init(filePath: String, relativeTo url: URL?) {
        self.init(fileURLWithPath: filePath, relativeTo: url)
    }

    var pathIncludingTrailingDirectorySeparator: String {
	if hasDirectoryPath {
            return path + "/"
        }
        return path
    }

    func relative(to url: URL) -> URL {
        precondition(isFileURL)
        precondition(url.isFileURL)
	precondition(url.hasDirectoryPath)
        let directoryPath = url.pathIncludingTrailingDirectorySeparator
        let path = pathIncludingTrailingDirectorySeparator
        precondition(path.starts(with: directoryPath))
	let relativePath = String(path.dropFirst(directoryPath.count))
	print(relativePath)

        return URL(filePath: relativePath, relativeTo: url)
    }

}

#endif
