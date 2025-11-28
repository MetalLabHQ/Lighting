//
//  Entity.swift
//  Lighting
//
//  Created by GH on 11/28/25.
//

import MetalKit

class Entity {
    var name: String = "Untitled"
    var meshes: [Mesh]
    
    init(object: MDLObject, device: MTLDevice) {
        self.name = object.name
        let mdlMeshes = Self.findAllMeshes(object)
        let mtkMeshes = mdlMeshes.compactMap { try? MTKMesh(mesh: $0, device: device) }
        self.meshes = mtkMeshes.map(Mesh.init)
    }
    
    static func findAllMeshes(_ object: MDLObject) -> [MDLMesh] {
        var meshes: [MDLMesh] = []
        if let mesh = object as? MDLMesh {
            meshes.append(mesh)
        }
        for child in object.children.objects {
            meshes.append(contentsOf: findAllMeshes(child))
        }
        return meshes
    }
}
