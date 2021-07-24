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
    case invalidECIDesignator
    case invalidCharacterCount
    case dataTooLong
    case segmentTooLong(Int, Int)
    
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
        case .invalidECIDesignator:
            return "Invalid ECI designator."
        case .invalidCharacterCount:
            return "Invalid number of characters."
        case .dataTooLong:
            return "Data too long."
        case .segmentTooLong(let dataUsedBits, let dataCapacityBits):
            var sb = ""
            if (dataUsedBits == -1) {
                sb += "Segment too long"
            } else {
                sb += "Data length = \(dataUsedBits) bits, "
                sb += "Max capacity = \(dataCapacityBits) bits"
            }
            return sb
        }
    }
}
