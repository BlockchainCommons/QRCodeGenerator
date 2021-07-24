//
//  BitBuffer.swift
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

import Foundation

public extension Array where Element == Bool {
    mutating func appendBits<T>(_ val: T, _ len: Int) where T: BinaryInteger {
        precondition((0...31).contains(len) && val >> len == 0)

        guard len > 0 else {
            return
        }
        
        for i in (0...(len - 1)).reversed() {
            append(((val >> i) & 1) != 0) // Append bit by bit
        }
    }
}
