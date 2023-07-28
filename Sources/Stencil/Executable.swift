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


// TODO: This needs to take an operand long-term.
// TODO: Execution??
// This is the perform. It captures the operation to perform, and the operation.
// The recursion is achieved because resultable can be an Executable in the future.
public struct Executable: Equatable, Hashable {
    let operand: Resultable?
    let operation: Operation

    // TODO: Rename to global context.
    func eval(_ context: EvaluationContext) throws -> Any? {
        // TODO: The operand needs to be an evaluation context!
        if let operand {
            let actualOperand = try operand.eval(context)

            // Unfortunately it seems to be insufficient to just conform our types to `EvaluationContext`, we also need
            // to try casting to those conforming types (in some cases at least).
            let operandContext = ((actualOperand as? EvaluationContext) ??
                                  (actualOperand as? [AnyHashable: Any]))
            guard let operandContext else {
                throw InContextError.evaluationUnsupported("\(String(describing: actualOperand)), \(type(of: actualOperand))")
            }
            return try operandContext.perform(operation, globalContext: context)
        } else {
            return try context.perform(operation, globalContext: context)
        }
    }
}


extension Executable {

    func apply(to operand: Resultable) throws -> Executable {
        // Base case.
        if self.operand == nil {
            return Self(operand: operand, operation: operation)
        }
        // Complex case.
        // This is _only_ possible if our inner operand is a callable; otherwise we throw.
        if case .executable(let executable) = self.operand {
            return Self(operand: .executable(try executable.apply(to: operand)), operation: operation)
        }
        // TODO: Invalid function application.
        throw InContextError.unknown
    }

}

extension Executable: CustomStringConvertible {

    public var description: String {
        return "(\(operand?.description ?? "nil"), \(operation.description))"
    }

}