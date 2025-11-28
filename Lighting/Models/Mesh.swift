//
//  Mesh.swift
//  Lighting
//
//  Created by GH on 11/28/25.
//

import MetalKit

struct Mesh {
    var vertexBuffers: [MTLBuffer]
    var submeshes: [Submesh]
    
    init(mtkMesh: MTKMesh) {
        vertexBuffers = mtkMesh.vertexBuffers.map { $0.buffer }
        submeshes = mtkMesh.submeshes.map { mtkSubmesh in
            Submesh(
                indexCount: mtkSubmesh.indexCount,
                indexType: mtkSubmesh.indexType,
                indexBuffer: mtkSubmesh.indexBuffer.buffer,
                indexBufferOffset: mtkSubmesh.indexBuffer.offset
            )
        }
    }
}

struct Submesh {
    let indexCount: Int
    let indexType: MTLIndexType
    let indexBuffer: MTLBuffer
    let indexBufferOffset: Int
}
