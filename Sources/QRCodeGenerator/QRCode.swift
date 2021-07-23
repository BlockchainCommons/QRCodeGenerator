//
//  QRCode.swift
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

/**
 * A QR Code symbol, which is a type of two-dimension barcode.
 * Invented by Denso Wave and described in the ISO/IEC 18004 standard.
 * Instances of this class represent an immutable square grid of black and white cells.
 * The class provides static factory functions to create a QR Code from text or binary data.
 * The class covers the QR Code Model 2 specification, supporting all versions (sizes)
 * from 1 to 40, all 4 error correction levels, and 4 character encoding modes.
 *
 * Ways to create a QR Code object:
 * - High level: Take the payload data and call QRCode.encodeText() or QRCode.encodeBinary().
 * - Mid level: Custom-make the list of segments and call QRCode.encodeSegments().
 * - Low level: Custom-make the array of data codeword bytes (including
 *   segment headers and final padding, excluding error correction codewords),
 *   supply the appropriate version number, and call the QRCode() constructor.
 * (Note that all ways require supplying the desired error correction level.)
 */
public struct QRCode {
    // MARK: - Instance fields
    
    // Immutable scalar parameters:
    
    /** The version number of this QR Code, which is between 1 and 40 (inclusive).
     * This determines the size of this barcode. */
    public let version: Int
    
    /** The width and height of this QR Code, measured in modules, between
     * 21 and 177 (inclusive). This is equal to version * 4 + 17. */
    public let size: Int
    
    /** The error correction level used in this QR Code. */
    public let correctionLevel: CorrectionLevel
    
    /** The index of the mask pattern used in this QR Code, which is between 0 and 7 (inclusive).
     * Even if a QR Code is created with automatic masking requested (mask = -1),
     * the resulting object still has a mask value between 0 and 7. */
    public private(set) var mask: Int
    
    /// The modules of this QR Code (false = white, true = black).
    public subscript(_ x: Int, _ y: Int) -> Bool {
        return 0 <= x && x < size && 0 <= y && y < size && module(x, y)
    }

    // MARK: - Private grids of modules/pixels, with dimensions of size*size
    
    /// The modules of this QR Code (false = white, true = black).
    /// Immutable after constructor finishes. Accessed through subscript(x, y).
    private var modules: [[Bool]]
    
    /// Indicates function modules that are not subjected to masking. Discarded when constructor finishes.
    private var isFunction: [[Bool]]
    
    // MARK: - Output functions
    
    public var emojiString: String {
        var lines: [String] = []
        for y in 0 ..< size {
            var s = ""
            for x in 0 ..< size {
                s.append(self[x, y] ? "⬛️" : "⬜️")
            }
            lines.append(s)
        }
        return lines.joined(separator: "\n")
    }
    
    #if canImport(AppKit) || canImport(UIKit)
    func makeImage(border: Int = 1, moduleSize: Int = 1, foregroundColor: OSColor = .black, backgroundColor: OSColor = .white) -> OSImage {
        let fullSize = size + 2 * border
        let scaledSize = fullSize * moduleSize
        let canvas = Canvas(size: IntSize(width: scaledSize, height: scaledSize))
        for y in 0 ..< fullSize {
            for x in 0 ..< fullSize {
                let color = self[x - border, y - border] ? foregroundColor : backgroundColor
                for py in 0 ..< moduleSize {
                    for px in 0 ..< moduleSize {
                        canvas.setPoint(IntPoint(x: x * moduleSize + px, y: y * moduleSize + py), to: color)
                    }
                }
            }
        }
        return canvas.image
    }
    #endif
    
    // MARK: - Public helper enumeration
    
    public enum CorrectionLevel: Int {
        case low        // The QR Code can tolerate about  7% erroneous codewords
        case medium     // The QR Code can tolerate about 15% erroneous codewords
        case quartile   // The QR Code can tolerate about 25% erroneous codewords
        case high       // The QR Code can tolerate about 30% erroneous codewords
        
        var formatBits: Int {
            Self._formatBits[rawValue]
        }
        
        private static let _formatBits = [1, 0, 3, 2]
    }
    
    // MARK: - Static factory functions (high level)
    
    /**
     * Returns a QR Code representing the given Unicode text string at the given error correction level.
     * As a conservative upper bound, this function is guaranteed to succeed for strings that have 2953 or fewer
     * UTF-8 code units (not Unicode code points) if the low error correction level is used. The smallest possible
     * QR Code version is automatically chosen for the output. The ECC level of the result may be higher than
     * the ecl argument if it can be done without increasing the version.
     */
    public static func encode(text: String, correctionLevel: CorrectionLevel = .medium, minVersion: Int = 1, maxVersion: Int = 40, mask: Int = -1, boostEcl: Bool = true) throws -> QRCode {
        let segs = try Segment.makeSegments(text: text)
        return try encode(segments: segs, correctionLevel: correctionLevel, minVersion: minVersion, maxVersion: maxVersion, mask: mask, boostEcl: boostEcl)
    }
    
    /**
     * Returns a QR Code representing the given binary data at the given error correction level.
     * This function always encodes using the binary segment mode, not any text mode. The maximum number of
     * bytes allowed is 2953. The smallest possible QR Code version is automatically chosen for the output.
     * The ECC level of the result may be higher than the ecl argument if it can be done without increasing the version.
     */
    public static func encode(data: [UInt8], correctionLevel: CorrectionLevel = .medium, minVersion: Int = 1, maxVersion: Int = 40, mask: Int = -1, boostEcl: Bool = true) throws -> QRCode {
        let segs = try Segment.makeBytes(data: data)
        return try encode(segments: [segs], correctionLevel: correctionLevel, minVersion: minVersion, maxVersion: maxVersion, mask: mask, boostEcl: boostEcl)
    }

    // MARK: - Static factory functions (mid level)

    /**
     * Returns a QR Code representing the given segments with the given encoding parameters.
     * The smallest possible QR Code version within the given range is automatically
     * chosen for the output. Iff boostEcl is true, then the ECC level of the result
     * may be higher than the ecl argument if it can be done without increasing the
     * version. The mask number is either between 0 to 7 (inclusive) to force that
     * mask, or -1 to automatically choose an appropriate mask (which may be slow).
     * This function allows the user to create a custom sequence of segments that switches
     * between modes (such as alphanumeric and byte) to encode text in less space.
     * This is a mid-level API; the high-level API is encodeText() and encodeBinary().
     */
    public static func encode(segments: [Segment], correctionLevel: CorrectionLevel = .medium, minVersion: Int = 1, maxVersion: Int = 40, mask: Int = -1, boostEcl: Bool = true) throws -> QRCode {
        guard [minVersion, maxVersion].allSatisfy({ (Self.minVersion...Self.maxVersion).contains($0) }) else {
            throw QRError.invalidVersion
        }
        // Find the minimal version number to use
        var version = minVersion
        var dataUsedBits = -1
        while true {
            let dataCapacityBits = Self.getNumDataCodewords(version, correctionLevel) * 8  // Number of data bits available
            dataUsedBits = Segment.getTotalBits(segments, version)
            if dataUsedBits != -1 && dataUsedBits <= dataCapacityBits {
                break  // This version number is found to be suitable
            }
            if version >= maxVersion {  // All versions in the range could not fit the given data
                throw QRError.segmentTooLong(dataUsedBits, dataCapacityBits)
            }
            
            version += 1
        }
        precondition(dataUsedBits != -1)
        
        // Increase the error correction level while the data still fits in the current version number
        var ecl = correctionLevel
        for newEcl in [CorrectionLevel.medium, CorrectionLevel.quartile, CorrectionLevel.high] { // From low to high
            if boostEcl && dataUsedBits <= getNumDataCodewords(version, newEcl) * 8 {
                ecl = newEcl
            }
        }
        
        // Concatenate all segments to create the data bit string
        var bb: [Bool] = []
        for seg in segments {
            bb.appendBits(seg.mode.modeBits, 4)
            bb.appendBits(seg.characterCount, seg.mode.numCharCountBits(version))
            bb.append(contentsOf: seg.data)
        }
        precondition(bb.count == dataUsedBits)
        
        // Add terminator and pad up to a byte if applicable
        let dataCapacityBits = getNumDataCodewords(version, ecl) * 8
        precondition(bb.count <= dataCapacityBits)
        bb.appendBits(0, min(4, dataCapacityBits - bb.count))
        bb.appendBits(0, (8 - bb.count % 8) % 8)
        precondition(bb.count % 8 == 0)
        
        // Pad with alternating bytes until data capacity is reached
        var padByte = 0xEC
        while bb.count < dataCapacityBits {
            bb.appendBits(padByte, 8)
            padByte ^= 0xEC ^ 0x11
        }
        
        // Pack bits into bytes in big endian
        var dataCodewords = [UInt8](repeating: 0, count: bb.count / 8)
        for i in 0 ..< bb.count {
            dataCodewords[i >> 3] |= (bb[i] ? 1 : 0) << (7 - (i & 7))
        }
        
        // Create the QR Code object
        return try QRCode(version: version, correctionLevel: ecl, dataCodewords: dataCodewords, msk: mask)
    }
    
    // MARK: - Constructor (low level)
    
    /**
     * Creates a new QR Code with the given version number,
     * error correction level, data codeword bytes, and mask number.
     * This is a low-level API that most users should not use directly.
     * A mid-level API is the encodeSegments() function.
     */
    public init(version: Int, correctionLevel: CorrectionLevel = .medium, dataCodewords: [UInt8], msk: Int) throws {
        self.version = version
        self.correctionLevel = correctionLevel
        self.mask = -1
        
        guard (Self.minVersion...Self.maxVersion).contains(version) else {
            throw QRError.invalidVersion
        }
        guard (-1...7).contains(msk) else {
            throw QRError.invalidMask
        }
        self.size = version * 4 + 17;
        self.modules = [[Bool]](repeating: [Bool](repeating: false, count: size), count: size)  // Initially all white
        self.isFunction = [[Bool]](repeating: [Bool](repeating: false, count: size), count: size)
        
        // Compute ECC, draw modules
        drawFunctionPatterns()
        let allCodewords = addEccAndInterleave(dataCodewords)
        drawCodewords(allCodewords)
        
        // Do masking
        var msk = msk
        if msk == -1 {  // Automatically choose best mask
            var minPenalty = Int.max;
            for i in 0 ..< 8 {
                applyMask(i)
                drawFormatBits(i)
                let penalty = getPenaltyScore()
                if penalty < minPenalty {
                    msk = i
                    minPenalty = penalty
                }
                applyMask(i)  // Undoes the mask due to XOR
            }
        }
        precondition((0...7).contains(msk))
        self.mask = msk
        applyMask(msk)  // Apply the final choice of mask
        drawFormatBits(msk)  // Overwrite old format bits
        
        isFunction.removeAll()
    }

    // MARK: - Private helper methods for constructor: Drawing function modules
    
    /// Reads this object's version field, and draws and marks all function modules.
    private mutating func drawFunctionPatterns() {
        // Draw horizontal and vertical timing patterns
        for i in 0 ..< size {
            setFunctionModule(6, i, i % 2 == 0);
            setFunctionModule(i, 6, i % 2 == 0);
        }
        
        // Draw 3 finder patterns (all corners except bottom right; overwrites some timing modules)
        drawFinderPattern(3, 3);
        drawFinderPattern(size - 4, 3);
        drawFinderPattern(3, size - 4);
        
        // Draw numerous alignment patterns
        let alignPatPos = getAlignmentPatternPositions()
        let numAlign = alignPatPos.count
        for i in 0 ..< numAlign {
            for j in 0 ..< numAlign {
                // Don't draw on the three finder corners
                if (!((i == 0 && j == 0) || (i == 0 && j == numAlign - 1) || (i == numAlign - 1 && j == 0))) {
                    drawAlignmentPattern(alignPatPos[i], alignPatPos[j]);
                }
            }
        }
        
        // Draw configuration data
        drawFormatBits(0);  // Dummy mask value; overwritten later in the constructor
        drawVersion();
    }
    
    /// Draws two copies of the format bits (with its own error correction code)
    /// based on the given mask and this object's error correction level field.
    private mutating func drawFormatBits(_ msk: Int) {
        // Calculate error correction code and pack bits
        let data = correctionLevel.formatBits << 3 | msk   // errCorrLvl is uint2, msk is uint3
        var rem = data
        for _ in 0 ..< 10 {
            rem = (rem << 1) ^ ((rem >> 9) * 0x537)
        }
        let bits = (data << 10 | rem) ^ 0x5412  // uint15
        precondition(bits >> 15 == 0)
        
        // Draw first copy
        for i in 0...5 {
            setFunctionModule(8, i, Self.getBit(bits, i))
        }
        setFunctionModule(8, 7, Self.getBit(bits, 6))
        setFunctionModule(8, 8, Self.getBit(bits, 7))
        setFunctionModule(7, 8, Self.getBit(bits, 8))
        for i in 9..<15 {
            setFunctionModule(14 - i, 8, Self.getBit(bits, i))
        }
        
        // Draw second copy
        for i in 0 ..< 8 {
            setFunctionModule(size - 1 - i, 8, Self.getBit(bits, i))
        }
        for i in 8 ..< 15 {
            setFunctionModule(8, size - 15 + i, Self.getBit(bits, i))
        }
        setFunctionModule(8, size - 8, true);  // Always black
    }
    
    
    /// Draws two copies of the version bits (with its own error correction code),
    /// based on this object's version field, iff 7 <= version <= 40.
    private mutating func drawVersion() {
        guard version >= 7 else {
            return
        }
        
        // Calculate error correction code and pack bits
        var rem = version  // version is uint6, in the range [7, 40]
        for _ in 0 ..< 12 {
            rem = (rem << 1) ^ ((rem >> 11) * 0x1F25)
        }
        let bits = version << 12 | rem;  // uint18
        precondition(bits >> 18 == 0)
        
        // Draw two copies
        for i in 0 ..< 18 {
            let bit = Self.getBit(bits, i)
            let a = size - 11 + i % 3
            let b = i / 3
            setFunctionModule(a, b, bit);
            setFunctionModule(b, a, bit);
        }
    }
    
    /// Draws a 9*9 finder pattern including the border separator,
    /// with the center module at (x, y). Modules can be out of bounds.
    private mutating func drawFinderPattern(_ x: Int, _ y: Int) {
        for dy in -4...4 {
            for dx in -4...4 {
                let dist = max(abs(dx), abs(dy))  // Chebyshev/infinity norm
                let xx = x + dx
                let yy = y + dy
                if 0 <= xx && xx < size && 0 <= yy && yy < size {
                    setFunctionModule(xx, yy, dist != 2 && dist != 4)
                }
            }
        }
    }
    
    /// Draws a 5*5 alignment pattern, with the center module
    /// at (x, y). All modules must be in bounds.
    private mutating func drawAlignmentPattern(_ x: Int, _ y: Int) {
        for dy in -2...2 {
            for dx in -2...2 {
                setFunctionModule(x + dx, y + dy, max(abs(dx), abs(dy)) != 1)
            }
        }
    }
    
    /// Sets the color of a module and marks it as a function module.
    /// Only used by the constructor. Coordinates must be in bounds.
    private mutating func setFunctionModule(_ x: Int, _ y: Int, _ isBlack: Bool) {
        modules[y][x] = isBlack
        isFunction[y][x] = true
    }
    
    /// Returns the color of the module at the given coordinates, which must be in range.
    private func module(_ x: Int, _ y: Int) -> Bool {
        modules[y][x]
    }
    
    // MARK: - Private helper methods for constructor: Codewords and masking
    
    /// Returns a new byte string representing the given data with the appropriate error correction
    /// codewords appended to it, based on this object's version and error correction level.
    private func addEccAndInterleave(_ data: [UInt8]) -> [UInt8] {
        let codeWords = Self.getNumDataCodewords(version, correctionLevel)
        precondition(data.count == codeWords)
        
        // Calculate parameter numbers
        let numBlocks = Self.numErrorCorrectionBlocks[correctionLevel.rawValue][version]
        let blockEccLen = Self.eccCodewordsPerBlock[correctionLevel.rawValue][version]
        let rawCodewords = Self.getNumRawDataModules(version) / 8
        let numShortBlocks = numBlocks - rawCodewords % numBlocks
        let shortBlockLen = rawCodewords / numBlocks
        
        // Split data into blocks and append ECC to each block
        var blocks = [[UInt8]]()
        let rsDiv = Self.reedSolomonComputeDivisor(blockEccLen)
        var k = 0
        for i in 0 ..< numBlocks {
            var dat = Array(data[k..<(k + shortBlockLen - blockEccLen + (i < numShortBlocks ? 0 : 1))])
            k += dat.count
            let ecc = Self.reedSolomonComputeRemainder(dat, rsDiv)
            if i < numShortBlocks {
                dat.append(0)
            }
            dat.append(contentsOf: ecc)
            blocks.append(dat)
        }
        
        // Interleave (not concatenate) the bytes from every block into a single sequence
        var result: [UInt8] = []
        for i in 0 ..< blocks[0].count {
            for j in 0 ..< blocks.count {
                // Skip the padding byte in short blocks
                if i != (shortBlockLen - blockEccLen) || j >= numShortBlocks {
                    result.append(blocks[j][i])
                }
            }
        }
        precondition(result.count == rawCodewords)
        return result
    }
    
    /// Draws the given sequence of 8-bit codewords (data and error correction) onto the entire
    /// data area of this QR Code. Function modules need to be marked off before this is called.
    private mutating func drawCodewords(_ data: [UInt8]) {
        precondition(data.count == Self.getNumRawDataModules(version) / 8)
        
        var i = 0  // Bit index into the data
        // Do the funny zigzag scan
        var right = size - 1
        while right >= 1 { // Index of right column in each column pair}
            if right == 6 {
                right = 5
            }
            for vert in 0 ..< size {  // Vertical counter
                for j in 0 ..< 2 {
                    let x = right - j  // Actual x coordinate
                    let upward = ((right + 1) & 2) == 0;
                    let y = upward ? size - 1 - vert : vert  // Actual y coordinate
                    if !isFunction[y][x] && i < data.count * 8 {
                        modules[y][x] = Self.getBit(Int(data[i >> 3]), 7 - (i & 7))
                        i += 1
                    }
                    // If this QR Code has any remainder bits (0 to 7), they were assigned as
                    // 0/false/white by the constructor and are left unchanged by this method
                }
            }
            right -= 2
        }
        precondition(i == data.count * 8)
    }
    
    /// XORs the codeword modules in this QR Code with the given mask pattern.
    /// The function modules must be marked and the codeword bits must be drawn
    /// before masking. Due to the arithmetic of XOR, calling applyMask() with
    /// the same mask value a second time will undo the mask. A final well-formed
    /// QR Code needs exactly one (not zero, two, etc.) mask applied.
    private mutating func applyMask(_ msk: Int) {
        precondition((0...7).contains(msk))
        for y in 0 ..< size {
            for x in 0 ..< size {
                var invert: Bool
                switch msk {
                    case 0:
                        invert = (x + y) % 2 == 0
                    case 1:
                        invert = y % 2 == 0
                    case 2:
                        invert = x % 3 == 0
                    case 3:
                        invert = (x + y) % 3 == 0
                    case 4:
                        invert = (x / 3 + y / 2) % 2 == 0
                    case 5:
                        invert = x * y % 2 + x * y % 3 == 0
                    case 6:
                        invert = (x * y % 2 + x * y % 3) % 2 == 0
                    case 7:
                        invert = ((x + y) % 2 + x * y % 3) % 2 == 0
                    default:
                        fatalError()
                }
                modules[y][x] = modules[y][x] != (invert && !isFunction[y][x])
            }
        }
    }
    
    /// Calculates and returns the penalty score based on state of this QR Code's current modules.
    /// This is used by the automatic mask choice algorithm to find the mask pattern that yields the lowest score.
    private func getPenaltyScore() -> Int {
        var result = 0
        
        // Adjacent modules in row having same color, and finder-like patterns
        for y in 0 ..< size {
            var runColor = false
            var runX = 0
            var runHistory = [Int](repeating: 0, count: 7)
            for x in 0 ..< size {
                if module(x, y) == runColor {
                    runX += 1
                    if runX == 5 {
                        result += Self.penaltyN1
                    } else if runX > 5 {
                        result += 1;
                    }
                } else {
                    finderPenaltyAddHistory(runX, &runHistory)
                    if !runColor {
                        result += finderPenaltyCountPatterns(&runHistory) * Self.penaltyN3
                    }
                    runColor = module(x, y)
                    runX = 1
                }
            }
            result += finderPenaltyTerminateAndCount(runColor, runX, &runHistory) * Self.penaltyN3
        }
        // Adjacent modules in column having same color, and finder-like patterns
        for x in 0 ..< size {
            var runColor = false
            var runY = 0
            var runHistory = [Int](repeating: 0, count: 7)
            for y in 0 ..< size {
                if module(x, y) == runColor {
                    runY += 1
                    if runY == 5 {
                        result += Self.penaltyN1;
                    } else if runY > 5 {
                        result += 1
                    }
                } else {
                    finderPenaltyAddHistory(runY, &runHistory);
                    if !runColor {
                        result += finderPenaltyCountPatterns(&runHistory) * Self.penaltyN3;
                    }
                    runColor = module(x, y)
                    runY = 1
                }
            }
            result += finderPenaltyTerminateAndCount(runColor, runY, &runHistory) * Self.penaltyN3;
        }
        
        // 2*2 blocks of modules having same color
        for y in 0 ..< size - 1 {
            for x in 0 ..< size - 1 {
                let color = module(x, y)
                if color == module(x + 1, y) &&
                    color == module(x, y + 1) &&
                    color == module(x + 1, y + 1) {
                    result += Self.penaltyN2
                }
            }
        }
        
        // Balance of black and white modules
        var black = 0
        for row in modules {
            for color in row {
                if color {
                    black += 1
                }
            }
        }
        let total = size * size;  // Note that size is odd, so black/total != 1/2
        // Compute the smallest integer k >= 0 such that (45-5k)% <= black/total <= (55+5k)%
        let k = ((abs(black * 20 - total * 10) + total - 1) / total) - 1
        result += k * Self.penaltyN4
        return result
    }

    // MARK: - Private helper functions
    
    /// Returns an ascending list of positions of alignment patterns for this version number.
    /// Each position is in the range [0,177), and are used on both the x and y axes.
    /// This could be implemented as lookup table of 40 variable-length lists of unsigned bytes.
    private func getAlignmentPatternPositions() -> [Int] {
        guard version > 1 else {
            return []
        }
        
        let numAlign = version / 7 + 2;
        let step = (version == 32) ? 26 :
            (version * 4 + numAlign * 2 + 1) / (numAlign * 2 - 2) * 2;
        var result: [Int] = []
        var pos = size - 7
        for _ in 0 ..< (numAlign - 1) {
            result.insert(pos, at: 0)
            pos -= step
        }
        result.insert(6, at: 0)
        return result
    }
    
    /// Returns the number of data bits that can be stored in a QR Code of the given version number, after
    /// all function modules are excluded. This includes remainder bits, so it might not be a multiple of 8.
    /// The result is in the range [208, 29648]. This could be implemented as a 40-entry lookup table.
    private static func getNumRawDataModules(_ ver: Int) -> Int {
        precondition((minVersion...maxVersion).contains(ver))
        var result = (16 * ver + 128) * ver + 64
        if ver >= 2 {
            let numAlign = ver / 7 + 2
            result -= (25 * numAlign - 10) * numAlign - 55
            if ver >= 7 {
                result -= 36
            }
        }
        precondition((208...29648).contains(result))
        return result;
    }
    
    /// Returns the number of 8-bit data (i.e. not error correction) codewords contained in any
    /// QR Code of the given version number and error correction level, with remainder bits discarded.
    /// This stateless pure function could be implemented as a (40*4)-cell lookup table.
    private static func getNumDataCodewords(_ ver: Int, _ ecl: CorrectionLevel) -> Int {
        getNumRawDataModules(ver) / 8
            - eccCodewordsPerBlock[ecl.rawValue][ver]
            * numErrorCorrectionBlocks[ecl.rawValue][ver];
    }
    
    /// Returns a Reed-Solomon ECC generator polynomial for the given degree. This could be
    /// implemented as a lookup table over all possible parameter values, instead of as an algorithm.
    private static func reedSolomonComputeDivisor(_ degree: Int) -> [UInt8] {
        precondition((1...255).contains(degree))
        // Polynomial coefficients are stored from highest to lowest power, excluding the leading term which is always 1.
        // For example the polynomial x^3 + 255x^2 + 8x + 93 is stored as the uint8 array {255, 8, 93}.
        var result = [UInt8](repeating: 0, count: degree)
        result[result.count - 1] = 1  // Start off with the monomial x^0
        
        // Compute the product polynomial (x - r^0) * (x - r^1) * (x - r^2) * ... * (x - r^{degree-1}),
        // and drop the highest monomial term which is always 1x^degree.
        // Note that r = 0x02, which is a generator element of this field GF(2^8/0x11D).
        var root: UInt8 = 1
        for _ in 0 ..< degree {
            // Multiply the current product by (x - r^i)
            for j in 0..<result.count {
                result[j] = reedSolomonMultiply(result[j], root)
                if j + 1 < result.count {
                    result[j] ^= result[j + 1]
                }
            }
            root = reedSolomonMultiply(root, 0x02)
        }
        return result;
    }
    
    /// Returns the Reed-Solomon error correction codeword for the given data and divisor polynomials.
    private static func reedSolomonComputeRemainder(_ data: [UInt8], _ divisor: [UInt8]) -> [UInt8] {
        var result = [UInt8](repeating: 0, count: divisor.count)
        for b in data { // Polynomial division
            let factor = b ^ result[0]
            result.removeFirst()
            result.append(0)
            for i in 0..<result.count {
                result[i] ^= reedSolomonMultiply(divisor[i], factor)
            }
        }
        return result
    }
    
    /// Returns the product of the two given field elements modulo GF(2^8/0x11D).
    /// All inputs are valid. This could be implemented as a 256*256 lookup table.
    private static func reedSolomonMultiply(_ x: UInt8, _ y: UInt8) -> UInt8 {
        // Russian peasant multiplication
        var z = 0;
        for i in (0...7).reversed() {
            z = (z << 1) ^ ((z >> 7) * 0x11D)
            z ^= ((Int(y) >> i) & 1) * Int(x)
        }
        precondition(z >> 8 == 0)
        return UInt8(z);
    }
    
    /// Can only be called immediately after a white run is added, and
    /// returns either 0, 1, or 2. A helper function for getPenaltyScore().
    private func finderPenaltyCountPatterns(_ runHistory: inout [Int]) -> Int {
        let n = runHistory[1]
        precondition(n <= size * 3)
        let core = n > 0 && runHistory[2] == n && runHistory[3] == n * 3 && runHistory[4] == n && runHistory[5] == n
        return (core && runHistory[0] >= n * 4 && runHistory[6] >= n ? 1 : 0)
             + (core && runHistory[6] >= n * 4 && runHistory[0] >= n ? 1 : 0)
    }
    
    /// Must be called at the end of a line (row or column) of modules. A helper function for getPenaltyScore().
    private func finderPenaltyTerminateAndCount(_ currentRunColor: Bool, _ currentRunLength: Int, _ runHistory: inout [Int]) -> Int {
        var currentRunLength = currentRunLength
        if currentRunColor {  // Terminate black run
            finderPenaltyAddHistory(currentRunLength, &runHistory)
            currentRunLength = 0
        }
        currentRunLength += size  // Add white border to final run
        finderPenaltyAddHistory(currentRunLength, &runHistory)
        return finderPenaltyCountPatterns(&runHistory)
    }
    
    /// Pushes the given value to the front and drops the last value. A helper function for getPenaltyScore().
    private func finderPenaltyAddHistory(_ currentRunLength: Int, _ runHistory: inout [Int]) {
        var currentRunLength = currentRunLength
        if runHistory[0] == 0 {
            currentRunLength += size  // Add white border to initial run
        }
        
        // runHistory.insert(currentRunLength, at: 0)
        // runHistory.removeLast()
        
        for i in (0..<runHistory.count - 1).reversed() {
            runHistory[i + 1] = runHistory[i]
        }
        runHistory[0] = currentRunLength
    }
    
    /// Returns true iff the i'th bit of x is set to 1.
    private static func getBit(_ x: Int, _ i: Int) -> Bool {
        ((x >> i) & 1) != 0
    }

    // MARK: - Constants and tables
    
    // The minimum version number supported in the QR Code Model 2 standard.
    public static let minVersion = 1
    
    // The maximum version number supported in the QR Code Model 2 standard.
    public static let maxVersion = 40

    private static let penaltyN1 =  3
    private static let penaltyN2 =  3
    private static let penaltyN3 = 40
    private static let penaltyN4 = 10

    private static let eccCodewordsPerBlock = [
        // Version: (note that index 0 is for padding, and is set to an illegal value)
        //0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40    Error correction level
        [-1,  7, 10, 15, 20, 26, 18, 20, 24, 30, 18, 20, 24, 26, 30, 22, 24, 28, 30, 28, 28, 28, 28, 30, 30, 26, 28, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30],  // Low
        [-1, 10, 16, 26, 18, 24, 16, 18, 22, 22, 26, 30, 22, 22, 24, 24, 28, 28, 26, 26, 26, 26, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28],  // Medium
        [-1, 13, 22, 18, 26, 18, 24, 18, 22, 20, 24, 28, 26, 24, 20, 30, 24, 28, 28, 26, 30, 28, 30, 30, 30, 30, 28, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30],  // Quartile
        [-1, 17, 28, 22, 16, 22, 28, 26, 26, 24, 28, 24, 28, 22, 24, 24, 30, 28, 28, 26, 28, 30, 24, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30],  // High
    ]
    
    private static let numErrorCorrectionBlocks = [
        // Version: (note that index 0 is for padding, and is set to an illegal value)
        //0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40    Error correction level
        [-1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 4,  4,  4,  4,  4,  6,  6,  6,  6,  7,  8,  8,  9,  9, 10, 12, 12, 12, 13, 14, 15, 16, 17, 18, 19, 19, 20, 21, 22, 24, 25],  // Low
        [-1, 1, 1, 1, 2, 2, 4, 4, 4, 5, 5,  5,  8,  9,  9, 10, 10, 11, 13, 14, 16, 17, 17, 18, 20, 21, 23, 25, 26, 28, 29, 31, 33, 35, 37, 38, 40, 43, 45, 47, 49],  // Medium
        [-1, 1, 1, 2, 2, 4, 4, 6, 6, 8, 8,  8, 10, 12, 16, 12, 17, 16, 18, 21, 20, 23, 23, 25, 27, 29, 34, 34, 35, 38, 40, 43, 45, 48, 51, 53, 56, 59, 62, 65, 68],  // Quartile
        [-1, 1, 1, 2, 4, 4, 4, 5, 6, 8, 8, 11, 11, 16, 16, 18, 16, 19, 21, 25, 25, 25, 34, 30, 32, 35, 37, 40, 42, 45, 48, 51, 54, 57, 60, 63, 66, 70, 74, 77, 81],  // High
    ]
}
