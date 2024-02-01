// MIT License
//
// Copyright (c) 2023 Jason Morley
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

import InContextCore

class HelperSession: ObservableObject, Session, Identifiable {

    enum State: Equatable {
        case running
        case success(CompletionState)
        case failure(String)
    }

    let id = UUID()
    let type: SessionType
    let name: String
    let startDate: Date

    @MainActor @Published var state: State = .running
    @MainActor @Published var tasks: [HelperSessionTask] = []

    init(type: SessionType, name: String) {
        self.type = type
        self.name = name
        self.startDate = Date()
    }

    func startTask(_ description: String) -> SessionTask {
        let task = HelperSessionTask(description: description)
        DispatchQueue.main.async {
            self.tasks.append(task)
        }
        return task
    }

    func finish(result: Result<CompletionState, Error>) {
        DispatchQueue.main.async {
            switch result {
            case .success(let state):
                self.state = .success(state)
            case .failure(let error):
                self.state = .failure(error.localizedDescription)
            }
        }
    }

}
