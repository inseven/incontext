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

public enum DirectoryHint {

    case isDirectory
    case notDirectory

}

extension URL {

    public init(filePath: String, directoryHint: DirectoryHint = .notDirectory) {
        self.init(fileURLWithPath: filePath, isDirectory: directoryHint == .isDirectory ? true : false)
    }

    public init(filePath: String, relativeTo url: URL?) {
        self.init(fileURLWithPath: filePath, relativeTo: url)
    }

    public var pathIncludingTrailingDirectorySeparator: String {
	if hasDirectoryPath {
            return path + "/"
        }
        return path
    }

    public func relative(to url: URL) -> URL {
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
