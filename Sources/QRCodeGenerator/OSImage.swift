//
//  OSImage.swift
//  QRCodeGenerator
//
//  Copyright © 2021 by Blockchain Commons, LLC
//  Licensed under the "BSD-2-Clause Plus Patent License"
//
//  Created by Wolf McNally on 12/31/20.
//

#if canImport(UIKit)
import UIKit
public typealias OSImage = UIImage
public typealias OSColor = UIColor
public let blackOSColor = UIColor.black
public let whiteOSColor = UIColor.white
#elseif canImport(AppKit)
import AppKit
public typealias OSImage = NSImage
public typealias OSColor = NSColor
public let blackOSColor = NSColor(red: 0, green: 0, blue: 0, alpha: 1)
public let whiteOSColor = NSColor(red: 1, green: 1, blue: 1, alpha: 1)
#endif
