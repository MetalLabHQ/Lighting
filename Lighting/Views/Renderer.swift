//
//  Renderer.swift
//  Lighting
//
//  Created by GH on 11/28/25.
//

import SwiftUI
import MetalKit

class Renderer: NSObject, MTKViewDelegate {
    let device: MTLDevice
    
    // MARK: - Command Queue
    let commandQueue: MTL4CommandQueue
    let commandBuffer: MTL4CommandBuffer
    let commandAllocator: MTL4CommandAllocator
    
    // MARK: - Buffers
    var uniformsBuffer: MTLBuffer
    
    
    // MARK: - State
    let pipelineState: MTLRenderPipelineState
    let argumentTable: MTL4ArgumentTable
    let depthState: MTLDepthStencilState
    
    let light = Light(
        direction: SIMD3<Float>(1, -1, -1),
        color: SIMD3<Float>(1, 1, 1)
    )
    let camera = Camera(
        position: SIMD3<Float>(0, 0, 10),
        target: SIMD3<Float>(0, 0, 0),
        up: SIMD3<Float>(0, 1, 0)
    )
    var entities: [Entity] = []
    var timer: Float = 0
    
    init(device: MTLDevice) throws {
        self.device = device
        
        // MARK: - Command Queue
        self.commandQueue = device.makeMTL4CommandQueue()!
        self.commandBuffer = device.makeCommandBuffer()!
        self.commandAllocator = device.makeCommandAllocator()!
        
        let asset = AssetsLoader.loadAssets(named: "truncated icosahedron", ext: "obj", device: device)!
        for i in 0..<asset.count {
            let object = asset.object(at: i)
            entities.append(Entity(object: object, device: device))
        }
        
        let vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(asset.vertexDescriptor!)!
        
        // MARK: - Buffers
        self.uniformsBuffer = device.makeBuffer(
            length: MemoryLayout<Uniforms>.size
        )!
        
        // 参数表
        let argTableDescriptor = MTL4ArgumentTableDescriptor()
        argTableDescriptor.maxBufferBindCount = 2
        self.argumentTable = try device.makeArgumentTable(descriptor: argTableDescriptor)
        self.argumentTable.setAddress(uniformsBuffer.gpuAddress, index: 1)
        
        
        // MARK: - Load Shaders
        let library = device.makeDefaultLibrary()!
        
        // 顶点着色器
        let vertexFunctionDescriptor       = MTL4LibraryFunctionDescriptor()
        vertexFunctionDescriptor.library   = library
        vertexFunctionDescriptor.name      = "vertex_main"
        
        // 片元着色器
        let fragmentFunctionDescriptor     = MTL4LibraryFunctionDescriptor()
        fragmentFunctionDescriptor.library = library
        fragmentFunctionDescriptor.name    = "fragment_main"
        
        
        // MARK: - Descriptor
        // 渲染管线描述符
        let pipelineDescriptor = MTL4RenderPipelineDescriptor()
        pipelineDescriptor.vertexFunctionDescriptor        = vertexFunctionDescriptor
        pipelineDescriptor.fragmentFunctionDescriptor      = fragmentFunctionDescriptor
        pipelineDescriptor.vertexDescriptor                = vertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        // 深度模板描述符
        let depthStateDescriptor = MTLDepthStencilDescriptor()
        depthStateDescriptor.depthCompareFunction = .less
        depthStateDescriptor.isDepthWriteEnabled = true
        
        
        // MARK: - State
        // 创建渲染管线状态
        self.pipelineState = try device
            .makeCompiler(descriptor: MTL4CompilerDescriptor())
            .makeRenderPipelineState(descriptor: pipelineDescriptor)
        self.depthState = device
            .makeDepthStencilState(descriptor: depthStateDescriptor)!
        
        super.init()
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable else { return }
        timer += 0.005
        
        // MARK: - 更新 Uniforms
        let aspect = view.drawableSize.width / view.drawableSize.height
        updateUniforms(uniformBuffer: uniformsBuffer, aspect: Float(aspect))
        
        
        // MARK: - 开始命令编码 Begin Command Buffer
        self.commandQueue.waitForDrawable(drawable)
        self.commandAllocator.reset()
        self.commandBuffer.beginCommandBuffer(allocator: commandAllocator)
        
        
        // MARK: - Render Pass
        let mtl4RenderPassDescriptor = MTL4RenderPassDescriptor()
        mtl4RenderPassDescriptor.colorAttachments[0].texture = drawable.texture
        mtl4RenderPassDescriptor.colorAttachments[0].loadAction = .clear
        mtl4RenderPassDescriptor.colorAttachments[0].clearColor  = MTLClearColor(red: 0.2, green: 0.2, blue: 0.25, alpha: 1.0)
        
        
        // MARK: - Begin Render Encoder
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(
            descriptor: mtl4RenderPassDescriptor,
            options: MTL4RenderEncoderOptions()
        ) else { return }
        
        
        // MARK: - Setup State
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setDepthStencilState(depthState)
        renderEncoder.setArgumentTable(argumentTable, stages: [.vertex, .fragment])
        
        
        // MARK: - Draw
        for entity in entities {
            renderEntity(entity, renderEncoder: renderEncoder)
        }
        
        
        // MARK: - End Render Encoder
        renderEncoder.endEncoding()
        
        
        // MARK: - End Command Buffer
        self.commandBuffer.endCommandBuffer()
        self.commandQueue.commit([commandBuffer], options: nil)
        self.commandQueue.signalDrawable(drawable)
        drawable.present()
    }
    
    func renderEntity(_ entity: Entity, renderEncoder: MTL4RenderCommandEncoder) {
        for mesh in entity.meshes {
            guard !mesh.vertexBuffers.isEmpty else { continue }
            
            argumentTable.setAddress(mesh.vertexBuffers[0].gpuAddress, index: 0)
            
            for submesh in mesh.submeshes {
                renderEncoder.drawIndexedPrimitives(
                    primitiveType: .triangle,
                    indexCount: submesh.indexCount,
                    indexType: submesh.indexType,
                    indexBuffer: submesh.indexBuffer.gpuAddress,
                    indexBufferLength: submesh.indexBuffer.length
                )
            }
        }
    }
    
    func updateUniforms(uniformBuffer: MTLBuffer, aspect: Float) {
        // 准备 MVP 矩阵
        let modelMatrix = float4x4(rotationY: timer)
        
        let viewMatrix = lookAt(
            eye: camera.position,
            target: camera.target,
            up: camera.up
        )
        
        let projectionMatrix = perspective(
            aspect: aspect,
            fovy: .pi / 3,
            near: 0.1,
            far: 100
        )
        
        // 模型坐标 -> 世界坐标 -> 视图坐标 -> 裁剪坐标
        let mvpMatrix = projectionMatrix * viewMatrix * modelMatrix
        let normalMatrix = normalMatrix(modelMatrix: modelMatrix)
        
        var uniforms = Uniforms(
            mvpMatrix: mvpMatrix,
            normalMatrix: normalMatrix,
            light: light
        )
        
        // 复制到 GPU 缓冲区
        memcpy(uniformBuffer.contents(), &uniforms, MemoryLayout<Uniforms>.size)
    }
    
    func normalMatrix(modelMatrix: float4x4) -> float3x3 {
        let inverseTranspose = modelMatrix.inverse.transpose
        let normalMatrix = float3x3(
            SIMD3<Float>(inverseTranspose.columns.0.x, inverseTranspose.columns.0.y, inverseTranspose.columns.0.z),
            SIMD3<Float>(inverseTranspose.columns.1.x, inverseTranspose.columns.1.y, inverseTranspose.columns.1.z),
            SIMD3<Float>(inverseTranspose.columns.2.x, inverseTranspose.columns.2.y, inverseTranspose.columns.2.z)
        )
        
        return normalMatrix
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}

#Preview {
    MetalView()
}

extension float4x4 {
    init(rotationY angle: Float) {
        self = float4x4(
            SIMD4<Float>( cos(angle), 0,  sin(angle), 0),
            SIMD4<Float>( 0,         1,  0,          0),
            SIMD4<Float>(-sin(angle), 0,  cos(angle), 0),
            SIMD4<Float>( 0,         0,  0,          1)
        )
    }
}
