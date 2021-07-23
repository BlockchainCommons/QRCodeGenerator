//
//  QRError.swift
//  QRCodeGenerator
//
//  Copyright © 2021 by Blockchain Commons, LLC
//  Licensed under the "BSD-2-Clause Plus Patent License"
//
//  Created by Wolf McNally on 7/20/21.
//

//
// This code is based on the Project Nayuki QR Code generator library (C++)
//

/*
 * QR Code generator library (C++)
 *
 * Copyright (c) Project Nayuki. (MIT License)
 * https://www.nayuki.io/page/qr-code-generator-library
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 * - The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 * - The Software is provided "as is", without warranty of any kind, express or
 *   implied, including but not limited to the warranties of merchantability,
 *   fitness for a particular purpose and noninfringement. In no event shall the
 *   authors or copyright holders be liable for any claim, damages or other
 *   liability, whether in an action of contract, tort or otherwise, arising from,
 *   out of or in connection with the Software or the use or other dealings in the
 *   Software.
 */

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
