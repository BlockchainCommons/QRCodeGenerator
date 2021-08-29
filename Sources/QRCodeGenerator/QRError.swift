//
//  QRError.swift
//  QRCodeGenerator
//
//  Copyright © 2021 by Blockchain Commons, LLC
//  Licensed under the "BSD-2-Clause Plus Patent License"
//
//  Created by Wolf McNally on 7/20/21.
//
//  Based on: QR Code generator library (C++)
//  Copyright (c) Project Nayuki. (MIT License)
//  https://www.nayuki.io/page/qr-code-generator-library
//

import Foundation

public enum QRError: LocalizedError {
    case invalidVersion
    case invalidMask
    case invalidNumericString
    case invalidAlphanumericString
    case invalidKanjiString
    case invalidECIDesignator
    case invalidCharacterCount
    case dataTooLong(Int, Int)
    
    public var errorDescription: String? {
        switch self {
        case .invalidVersion:
            return "Invalid version."
        case .invalidMask:
            return "Invalid mask."
        case .invalidNumericString:
            return "String contains non-numeric characters."
        case .invalidAlphanumericString:
            return "String contains unencodable characters in alphanumeric mode."
        case .invalidKanjiString:
            return "String contains non-kanji-mode characters."
        case .invalidECIDesignator:
            return "Invalid ECI designator."
        case .invalidCharacterCount:
            return "Invalid number of characters."
        case .dataTooLong(let dataUsedBits, let dataCapacityBits):
            var sb = "Data too long."
            if dataUsedBits != -1 {
                sb += " Data length = \(dataUsedBits) bits, Max capacity = \(dataCapacityBits) bits."
            }
            return sb
        }
    }
}
