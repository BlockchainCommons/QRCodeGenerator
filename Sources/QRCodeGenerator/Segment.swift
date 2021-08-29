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
    public let mode: Mode
    
    /** The length of this segment's unencoded data. Measured in characters for
     * numeric/alphanumeric/kanji mode, bytes for byte mode, and 0 for ECI mode.
     * Always zero or positive. Not the same as the data's bit length.
     */
    public let characterCount: Int
    
    /// The data bits of this segment.
    public let data: [Bool]

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
            guard isNumeric(c) else {
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
    
    static func isNumeric<I>(_ c: I) -> Bool where I: BinaryInteger {
        guard c <= UInt8.max else {
            return false
        }
        return (ascii0...ascii9).contains(UInt8(c))
    }
    
    static let alphanumericCharset: [UInt8] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:".utf8)
    
    static func alphanumericIndex<I>(of c: I) -> Int? where I: BinaryInteger {
        guard c <= UInt8.max else {
            return nil
        }
        return Self.alphanumericCharset.firstIndex(of: UInt8(c))
    }
    
    static func isAlphanumeric<I>(_ c: I) -> Bool where I: BinaryInteger {
        alphanumericIndex(of: c) != nil
    }
    
    static func isAlphanumeric(_ c: UnicodeScalar) -> Bool {
        isAlphanumeric(c.value)
    }
    
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
            guard let index = alphanumericIndex(of: c) else {
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
     * Returns a segment representing the specified text string encoded in kanji mode. Throws if the string contains any non-kanji-mode characters.
     *
     * Broadly speaking, the set of encodable characters are {kanji used in Japan,
     * hiragana, katakana, East Asian punctuation, full-width ASCII, Greek, Cyrillic}.
     * Examples of non-encodable characters include {ordinary ASCII, half-width katakana,
     * more extensive Chinese hanzi}.
     */
    public static func makeKanji(text: String) throws -> Segment {
        var bb: [Bool] = []
        try text.forEach {
            guard let val = toKanji($0) else {
                throw QRError.invalidKanjiString
            }
            bb.appendBits(val, 13)
        }
        return try Segment(mode: .kanji, characterCount: text.count, data: bb)
    }
    
    public static func isEncodableAsKanji(_ s: String) -> Bool {
        s.allSatisfy(isKanji)
    }
    
    public static func toKanji(_ c: Character) -> Int? {
        let scalars = c.unicodeScalars
        guard scalars.count == 1 else {
            return nil
        }
        let value = Int(scalars.first!.value)
        return toKanji(value)
    }
    
    static func toKanji(_ value: Int) -> Int? {
        guard value < (1 << 16) else {
            return nil
        }
        guard value < unicodeToQRKanji.count && unicodeToQRKanji[value] != -1 else {
            return nil
        }
        let result = Int(unicodeToQRKanji[value])
        guard result != -1 else {
            return nil
        }
        return result
    }
    
    public static func isKanji(_ c: Character) -> Bool {
        toKanji(c) != nil
    }
    
    public static func isKanji<I>(_ c: I) -> Bool where I: BinaryInteger {
        toKanji(Int(c)) != nil
    }
    
    public static func isKanji(_ c: UnicodeScalar) -> Bool {
        isKanji(c.value)
    }
    
    static let unicodeToQRKanji: [Int16] = {
        var result = [Int16](repeating: -1, count: 1 << 16)
        let bytes = Data(base64Encoded: packedQRKangiToUnicode)!
        for i in stride(from: 0, to: bytes.count, by: 2) {
            let c = ((UInt16(bytes[i]) & 0xff) << 8) | (UInt16(bytes[i + 1]) & 0xff)
            guard c != 0xffff else {
                continue
            }
            precondition(result[Int(c)] == -1)
            result[Int(c)] = Int16(i / 2)
        }
        return result
    }()

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
        text.utf8.allSatisfy { isNumeric($0) }
    }
    
    public static func isNumeric(_ c: UnicodeScalar) -> Bool {
        isNumeric(c.value)
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
    
    /**
     * Returns a list of zero or more segments to represent the specified Unicode text string.
     * The resulting list optimally minimizes the total encoded bit length, subjected to the constraints
     * in the specified {error correction level, minimum version number, maximum version number}.
     *
     * This function can utilize all four text encoding modes: numeric, alphanumeric, byte (UTF-8),
     * and kanji. This can be considered as a sophisticated but slower replacement for
     * `makeSegments()`. This requires more input parameters because it searches a
     * range of versions, like `QRCode.encode(segments:correctionLevel:minVersion:maxVersion:mask:booscEcl:)`.
     */
    public static func makeSegmentsOptimally(text: String, correctionLevel: CorrectionLevel = .medium, minVersion: Int = 1, maxVersion: Int = 40) throws -> [Segment] {
        try QRCode.checkVersion(minVersion: minVersion, maxVersion: maxVersion)
        
        // Iterate through version numbers, and make tentative segments
        var segs: [Segment]!
        let codePoints = Array(text.unicodeScalars)
        var version = minVersion
        repeat {
            defer {
                version += 1
            }
            if version == minVersion || version == 10 || version == 27 {
                segs = makeSegmentsOptimally(codePoints: codePoints, version: version)
            }
            precondition(segs != nil)
            
            // Check if the segments fit
            let dataCapacityBits = QRCode.getNumDataCodewords(version, correctionLevel) * 8
            let dataUsedBits = Segment.getTotalBits(segs, version)
            if dataUsedBits != -1 && dataUsedBits <= dataCapacityBits {
                return segs  // This version number is found to be suitable
            }
            if version >= maxVersion {  // All versions in the range could not fit the given text
                throw QRError.dataTooLong(dataUsedBits, dataCapacityBits)
            }
        } while true
    }

    /// Returns a new list of segments that is optimal for the given text at the given version number.
    static func makeSegmentsOptimally(codePoints: [UnicodeScalar], version: Int) -> [Segment] {
        guard !codePoints.isEmpty else {
            return []
        }
        let charModes = computeCharacterModes(codePoints: codePoints, version: version)
        return splitIntoSegments(codePoints: codePoints, charModes: charModes)
    }
    
    /// Returns a new array representing the optimal mode per code point based on the given text and version.
    static func computeCharacterModes(codePoints: [UnicodeScalar], version: Int) -> [Mode] {
        precondition(!codePoints.isEmpty)
        let modeTypes: [Segment.Mode] = [.byte, .alphanumeric, .numeric, .kanji] // Do not change
        let modesCount = modeTypes.count
        
        // Segment header sizes, measured in 1/6 bits
        let headCosts = modeTypes.map {
            (4 + $0.numCharCountBits(version)) * 6
        }
        
        // charModes[i][j] represents the mode to encode the code point at
        // index i such that the final segment ends in modeTypes[j] and the
        // total number of bits is minimized over all possible choices
        var charModes: [[Segment.Mode?]] =
            Array(repeating:
                    Array(repeating: nil, count: modesCount),
                  count: codePoints.count)

        // At the beginning of each iteration of the loop below,
        // prevCosts[j] is the exact minimum number of 1/6 bits needed to
        // encode the entire string prefix of length i, and end in modeTypes[j]
        var prevCosts = headCosts
        
        // Calculate costs using dynamic programming
        for (i, c) in codePoints.enumerated() {
            var curCosts = [Int](repeating: 0, count: modesCount)
            do {  // Always extend a byte mode segment
                curCosts[0] = prevCosts[0] + countUTF8Bytes(c) * 8 * 6
                charModes[i][0] = modeTypes[0]
            }
            // Extend a segment if possible
            if isAlphanumeric(c) {  // Is alphanumeric
                curCosts[1] = prevCosts[1] + 33  // 5.5 bits per alphanumeric char
                charModes[i][1] = modeTypes[1]
            }
            if isNumeric(c) {  // Is numeric
                curCosts[2] = prevCosts[2] + 20  // 3.33 bits per digit
                charModes[i][2] = modeTypes[2]
            }
            if isKanji(c) {
                curCosts[3] = prevCosts[3] + 78  // 13 bits per Shift JIS char
                charModes[i][3] = modeTypes[3]
            }
            
            // Start new segment at the end to switch modes
            for j in 0 ..< modesCount { // To mode
                for k in 0 ..< modesCount { // From mode
                    let newCost = (curCosts[k] + 5) / 6 * 6 + headCosts[j]
                    if charModes[i][k] != nil && (charModes[i][j] == nil || newCost < curCosts[j]) {
                        curCosts[j] = newCost
                        charModes[i][j] = modeTypes[k]
                    }
                }
            }
            
            prevCosts = curCosts
        }

        // Find optimal ending mode
        var curMode: Mode?
        var minCost = 0
        for i in 0 ..< modesCount {
            if curMode == nil || prevCosts[i] < minCost {
                minCost = prevCosts[i]
                curMode = modeTypes[i]
            }
        }
        
        // Get optimal mode for each code point by tracing backwards
        var r = [Mode?](repeating: nil, count: charModes.count)
        for i in (0 ..< charModes.count).reversed() {
            for j in 0 ..< modesCount {
                if modeTypes[j] == curMode {
                    curMode = charModes[i][j]
                    r[i] = curMode
                    break
                }
            }
        }
        
        let result = r.compactMap { $0 }
        precondition(result.count == r.count)
        
        return result
    }
    
    // Returns a new list of segments based on the given text and modes, such that
    // consecutive code points in the same mode are put into the same segment.
    static func splitIntoSegments(codePoints: [UnicodeScalar], charModes: [Mode]) -> [Segment] {
        precondition(!codePoints.isEmpty)
        var result: [Segment] = []
        
        // Accumulate run of modes
        var curMode = charModes.first!
        var start = 0
        var i = 1
        repeat {
            defer {
                i += 1
            }
            if i < codePoints.count && charModes[i] == curMode {
                continue
            }
            let s = String(String.UnicodeScalarView(codePoints[start ..< i]))
            switch curMode {
            case .byte:
                try! result.append(makeBytes(data: Array(s.utf8)))
            case .numeric:
                try! result.append(makeNumeric(digits: s))
            case .alphanumeric:
                try! result.append(makeAlphanumeric(text: s))
            case .kanji:
                try! result.append(makeKanji(text: s))
            default:
                preconditionFailure()
            }

            if i >= codePoints.count {
                return result
            }
            curMode = charModes[i]
            start = i
        } while true
    }

    /// Returns the number of UTF-8 bytes needed to encode the given Unicode code point.
    static func countUTF8Bytes(_ cp: UnicodeScalar) -> Int {
        let v = cp.value
             if v <     0x80 { return 1 }
        else if v <    0x800 { return 2 }
        else if v <  0x10000 { return 3 }
        else if v < 0x110000 { return 4 }
        preconditionFailure()
    }
}

extension Segment: CustomStringConvertible {
    public var description: String {
        "Segment(mode: \(mode), characterCount: \(characterCount), data: <\(data.count) bits>)"
    }
}
