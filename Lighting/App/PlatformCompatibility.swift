//
//  PlatformCompatibility.swift
//  Lighting
//
//  Created by GH on 11/28/25.
//

import SwiftUI

#if os(macOS)
typealias ViewRepresentable = NSViewRepresentable
typealias PlatformView = NSView
typealias PlatformViewController = NSViewController
typealias PlatformColor = NSColor
#else
typealias ViewRepresentable = UIViewRepresentable
typealias PlatformView = UIView
typealias PlatformViewController = UIViewController
typealias PlatformColor = UIColor
#endif
