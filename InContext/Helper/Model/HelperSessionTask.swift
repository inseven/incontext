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

import InContextCore

class HelperSessionTask: ObservableObject, SessionTask, Identifiable {

    enum State: Equatable {
        case running
        case success(CompletionState)
        case failure(String)
    }

    let id = UUID()
    let description: String
    let startDate: Date

    @MainActor @Published var state: State = .running
    @MainActor @Published var events: [Event] = []

    init(description: String) {
        self.description = description
        self.startDate = Date()
    }

    func log(level: InContextCore.LogLevel, _ message: String) {
        let event = Event(date: Date(), level: level, message: message)
        DispatchQueue.main.async {
            self.events.append(event)
        }
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
