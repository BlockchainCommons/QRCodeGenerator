//
//  Segment.swift
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

/**
A segment of character/binary/control data in a QR Code symbol.
Instances of this class are immutable.
The mid-level way to create a segment is to take the payload data
and call a static factory function such as QrSegment::makeNumeric().
The low-level way to create a segment is to custom-make the bit buffer
and call the QrSegment() constructor with appropriate values.
This segment class imposes no length restrictions, but QR Codes have restrictions.
Even in the most favorable conditions, a QR Code can only hold 7089 characters of data.
Any segment longer than this is meaningless for the purpose of generating QR Codes.
*/
public struct Segment {
    // MARK: - Instance fields
    
    /// The mode indicator of this segment.
    let mode: Mode
    
    /** The length of this segment's unencoded data. Measured in characters for
     * numeric/alphanumeric/kanji mode, bytes for byte mode, and 0 for ECI mode.
     * Always zero or positive. Not the same as the data's bit length.
     */
    let characterCount: Int
    
    /// The data bits of this segment.
    let data: [Bool]

    // MARK: - Public helper enumeration
    
    /// Describes how a segment's data bits are interpreted. Immutable.
    public enum Mode: Int {
        case numeric
        case alphanumeric
        case byte
        case kanji
        case eci
        
        /// The mode indicator bits, which is a uint4 value (range 0 to 15).
        public var modeBits: Int {
            Self._modeBits[rawValue]
        }
        
        /// Returns the bit width of the character count field for a segment in this mode in a QR Code at the given version number. The result is in the range [0, 16].
        public func numCharCountBits(_ ver: Int) -> Int {
            Self._numCharCountBits[rawValue][(ver + 7) / 17]
        }
        
        private static let _modeBits = [
            1, // numeric
            2, // alphanumeric
            4, // byte
            8, // kanji
            7  // eci
        ]
        
        private static let _numCharCountBits = [
            [10, 12, 14], // numeric
            [ 9, 11, 13], // alphanumeric
            [ 8, 16, 16], // byte
            [ 8, 10, 12], // kanji
            [ 0,  0,  0]  // eci
        ]
    }
    
    // MARK: - Static factory functions (mid level)
    
    /**
     * Returns a segment representing the given binary data encoded in
     * byte mode. All input byte vectors are acceptable. Any text string
     * can be converted to UTF-8 bytes and encoded as a byte mode segment.
     */
    public static func makeBytes(data: [UInt8]) throws -> Segment {
        guard data.count <= UInt.max else {
            throw QRError.dataTooLong
        }
        var bb: [Bool] = []
        for b in data {
            bb.appendBits(b, 8)
        }
        return try Segment(mode: .byte, characterCount: data.count, data: bb)
    }
    
    public static func makeBytes(data: Data) throws -> Segment {
        return try makeBytes(data: Array(data))
    }
    
    public static func makeBytes(data: String) throws -> Segment {
        return try makeBytes(data: data.data(using: .utf8)!)
    }

    /**
     * Returns a segment representing the given string of decimal digits encoded in numeric mode.
     */
    public static func makeNumeric(digits: String) throws -> Segment {
        var bb: [Bool] = []
        var accumData: UInt = 0
        var accumCount = 0
        for c in digits.utf8 {
            guard (ascii0...ascii9).contains(c) else {
                throw QRError.invalidNumericString
            }
            accumData = accumData * 10 + UInt(c - ascii0)
            accumCount += 1
            if accumCount == 3 {
                bb.appendBits(accumData, 10)
                accumData = 0
                accumCount = 0
            }
        }
        if accumCount > 0 {   // 1 or 2 digits remaining
            bb.appendBits(accumData, accumCount * 3 + 1)
        }
        return try Segment(mode: .numeric, characterCount: digits.count, data: bb)
    }
    
    private static let ascii0 = Character("0").asciiValue!
    private static let ascii9 = Character("9").asciiValue!
    private static let alphanumericCharset: [UInt8] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:".utf8)
    
    /**
     * Returns a segment representing the given text string encoded in alphanumeric mode.
     * The characters allowed are: 0 to 9, A to Z (uppercase only), space,
     * dollar, percent, asterisk, plus, hyphen, period, slash, colon.
     */
    public static func makeAlphanumeric(text: String) throws -> Segment {
        var bb: [Bool] = []
        var accumData: UInt = 0
        var accumCount = 0
        for c in text.utf8 {
            guard let index = Self.alphanumericCharset.firstIndex(of: c) else {
                throw QRError.invalidAlphanumericString
            }
            accumData = accumData * 45 + UInt(index)
            accumCount += 1
            if accumCount == 2 {
                bb.appendBits(accumData, 11)
                accumData = 0
                accumCount = 0
            }
        }
        if accumCount > 0 { // 1 character remaining
            bb.appendBits(accumData, 6)
        }
        return try Segment(mode: .alphanumeric, characterCount: text.count, data: bb)
    }
    
    /**
     * Returns a list of zero or more segments to represent the given text string. The result
     * may use various segment modes and switch modes to optimize the length of the bit stream.
     */
    public static func makeSegments(text: String) throws -> [Segment] {
        var result: [Segment] = []
        if text.isEmpty {
            // Leave result empty
        } else if isNumeric(text: text) {
            try result.append(makeNumeric(digits: text))
        } else if isAlphanumeric(text: text) {
            try result.append(makeAlphanumeric(text: text))
        } else {
            try result.append(makeBytes(data: Array(text.utf8)))
        }
        return result
    }
    
    /**
     * Returns a segment representing an Extended Channel Interpretation
     * (ECI) designator with the given assignment value.
     */
    public static func makeECI(designator: Int) throws -> Segment {
        var bb: [Bool] = []
        if designator < 0 {
            throw QRError.invalidECIDesignator
        } else if designator < (1 << 7) {
            bb.appendBits(UInt32(designator), 8)
        } else if designator < (1 << 14) {
            bb.appendBits(UInt32(designator), 14)
        } else if designator < 1_000_000 {
            bb.appendBits(UInt32(6), 3)
            bb.appendBits(UInt32(designator), 21)
        } else {
            throw QRError.invalidECIDesignator
        }
        return try Segment(mode: .eci, characterCount: 0, data: bb)
    }

    // MARK: - Public static helper functions

    /**
     * Tests whether the given string can be encoded as a segment in alphanumeric mode.
     * A string is encodable iff each character is in the following set: 0 to 9, A to Z
     * (uppercase only), space, dollar, percent, asterisk, plus, hyphen, period, slash, colon.
     */
    public static func isAlphanumeric(text: String) -> Bool {
        text.utf8.allSatisfy { Self.alphanumericCharset.contains($0) }
    }
    
    /**
     * Tests whether the given string can be encoded as a segment in numeric mode.
     * A string is encodable iff each character is in the range 0 to 9.
     */
    public static func isNumeric(text: String) -> Bool {
        text.utf8.allSatisfy { (ascii0...ascii9).contains($0) }
    }

    // MARK: - Constructors (low level)
    
    /**
     * Creates a new QR Code segment with the given attributes and data.
     * The character count (numCh) must agree with the mode and the bit buffer length,
     * but the constraint isn't checked.
     */
    public init(mode: Segment.Mode, characterCount: Int, data: [Bool]) throws {
        guard characterCount >= 0 else {
            throw QRError.invalidCharacterCount
        }
        self.mode = mode
        self.characterCount = characterCount
        self.data = data
    }

    // Calculates the number of bits needed to encode the given segments at
    // the given version. Returns a non-negative number if successful. Otherwise returns -1 if a
    // segment has too many characters to fit its length field, or the total bits exceeds INT_MAX.
    static func getTotalBits(_ segs: [Segment], _ version: Int) -> Int {
        var result = 0
        for seg in segs {
            let ccbits = seg.mode.numCharCountBits(version)
            if seg.characterCount >= (1 << ccbits) {
                return -1 // The segment's length doesn't fit the field's bit width
            } else if 4 + ccbits > Int.max - result {
                return -1 // The sum will overflow an int type
            }
            result += 4 + ccbits
            if seg.data.count > Int.max - result {
                return -1 // The sum will overflow an int type
            }
            result += seg.data.count
        }
        return result
    }
}
