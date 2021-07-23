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
#elseif canImport(AppKit)
import AppKit
public typealias OSImage = NSImage
public typealias OSColor = NSColor
#endif
