//
//  MetalView.swift
//  Lighting
//
//  Created by GH on 11/28/25.
//

import SwiftUI
import MetalKit

struct MetalView: ViewRepresentable {
    // MARK: - Metal Device
    private let device: MTLDevice
    private let renderer: Renderer
    
    init() {
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported")
        }
        
        guard defaultDevice.supportsFamily(.metal4) else {
            fatalError("Metal 4 is not supported on this device")
        }
        self.device = defaultDevice
        
        do {
            self.renderer = try Renderer(device: device)
        } catch {
            print("Failed to create Metal 4 renderer: \(error)")
            fatalError("Failed to create Metal 4 renderer: \(error)")
        }
    }
    
#if os(macOS)
    func makeNSView(context: Context) -> MTKView {
        return makeView()
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {}
#else
    func makeUIView(context: Context) -> MTKView {
        return makeView()
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {}
#endif
    
    private func makeView() -> MTKView {
        let mtkView = MTKView(frame: .zero, device: device)
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.delegate = renderer
        mtkView.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        return mtkView
    }
}

#Preview {
    MetalView()
}
