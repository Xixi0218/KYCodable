//
//  SourceEditorCommand.swift
//  KYCodablePlugin
//
//  Created by keyon on 2022/9/5.
//

import Foundation
import XcodeKit

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        do {
            try generateCodabe(invocation: invocation)
            completionHandler(nil)
        } catch {
            completionHandler(error)
        }
    }

    private func generateCodabe(invocation: XCSourceEditorCommandInvocation) throws {
        guard ["public.swift-source", "com.apple.dt.playground"].contains(invocation.buffer.contentUTI) else { throw KYSIGError.notSwiftLanguage }
        guard let selection = invocation.buffer.selections.firstObject as? XCSourceTextRange else { throw KYSIGError.noSelection }
        debugPrint(selection.start.line, selection.start.column)
        debugPrint(selection.end.line, selection.end.column)

        let selectedText: [String]
        guard let invocationBufferText = invocation.buffer.lines as? [String] else { throw KYSIGError.noSelection }
        if selection.start.line == selection.end.line {
            selectedText = [String(invocationBufferText[selection.start.line].utf8.prefix(selection.end.column).dropFirst(selection.start.column))!]
        } else {
            selectedText = [String(invocationBufferText[selection.start.line].utf8.dropFirst(selection.start.column))!]
                + ((selection.start.line+1)..<selection.end.line).map { invocationBufferText[$0] }
                + [String(invocationBufferText[selection.end.line].utf8.prefix(selection.end.column))!]
        }

        var initializer = try generate(selection: selectedText, indentation: indentSequence(for: invocation.buffer), leadingIndent: leadingIndentation(from: selection, in: invocation.buffer))

        initializer.insert("", at: 0)

        let targetRange = selection.end.line + 1..<selection.end.line + 1 + initializer.count
        invocation.buffer.lines.insert(initializer, at: IndexSet(integersIn: targetRange))
    }

    private func indentSequence(for buffer: XCSourceTextBuffer) -> String {
        return buffer.usesTabsForIndentation ? "\t" : String(repeating: " ", count: buffer.indentationWidth)
    }

    private func leadingIndentation(from selection: XCSourceTextRange, in buffer: XCSourceTextBuffer) -> String {
        guard let firstLineOfSelection = buffer.lines[selection.start.line] as? String else { return "" }
        if let nonWithteSpace = firstLineOfSelection.rangeOfCharacter(from: CharacterSet.whitespaces.inverted) {
            return String(firstLineOfSelection.prefix(upTo: nonWithteSpace.lowerBound))
        } else {
            return ""
        }
    }

}
