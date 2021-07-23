//
//  OSImage.swift
//  QRCodeGenerator
//
//  Copyright © 2021 by Blockchain Commons, LLC
//  Licensed under the "BSD-2-Clause Plus Patent License"
//
//  Created by Wolf McNally on 7/23/21.
//

import Foundation

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
