//
//  KYSIG.swift
//  KYCodablePlugin
//
//  Created by keyon on 2022/9/5.
//

import Foundation

enum KYSIGError: Swift.Error {
    case notSwiftLanguage
    case noSelection
    case invalidSelection
    case parseError
}

func generate(selection: [String], indentation: String, leadingIndent: String) throws -> [String] {
    var variables = [(String, String)]()

    for line in selection {
        let scanner = Scanner(string: line)

        guard scanner.scanString("let") != nil || scanner.scanString("var") != nil || scanner.scanString("dynamic var") != nil else {
            continue
        }

        guard let variableName = scanner.scanUpToString(":"),
              scanner.scanString(":") != nil,
            let variableType = scanner.scanUpToString("\n") else {
                throw KYSIGError.parseError
        }
        variables.append((variableName, variableType))
    }
    
    let codingkeyExpressions = "\(leadingIndent)case" + variables.enumerated().flatMap{ (index, element) in " \(element.0)\(index == variables.count - 1 ? "" : ",")" }
    let codingkey = (["private enum CodingKeys : String, CodingKey {"] + [codingkeyExpressions] + ["}"]).map{ "\(leadingIndent)\($0)" }

    let decoderExpressions = ["\(leadingIndent)let values = try decoder.container(keyedBy: CodingKeys.self)\n"] + variables.map{ "\(leadingIndent)\($0.0) = try values.decode(\($0.1).self, forKey: .\($0.0)) \n"}
    let decoderString = (["init(from decoder: Decoder) throws {"] + decoderExpressions + ["}"]).map{ "\(leadingIndent)\($0)" }

    let encodeExpressions = ["\(leadingIndent)var container = encoder.container(keyedBy: CodingKeys.self)"] + variables.map{ "\(leadingIndent)try container.encode(\($0.0), forKey: .\($0.0))\n"}
    let encodeString = (["func encode(to encoder: Encoder) throws {"] + encodeExpressions + ["}"]).map{ "\(leadingIndent)\($0)" }

    return codingkey + [""] + decoderString + [""] + encodeString
}
