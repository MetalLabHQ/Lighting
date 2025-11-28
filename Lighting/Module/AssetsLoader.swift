//
//  AssetsLoader.swift
//  Lighting
//
//  Created by GH on 11/28/25.
//

import MetalKit

enum AssetsLoader {
    static func loadAssets(named filename: String, ext: String, device: MTLDevice) -> MDLAsset? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: ext) else {
            print("Cannot find file: \(filename).\(ext)")
            return nil
        }
        
        if !MDLAsset.canImportFileExtension(ext) {
            print("File extension .\(ext) is not supported for import")
        }
        
        let asset = MDLAsset(
            url: url,
            vertexDescriptor: nil,
            bufferAllocator: MTKMeshBufferAllocator(device: device)
        )
        
        return asset
    }
    
    static func printAssetInfo(asset: MDLAsset) {
        print("\n========== Asset Info ==========")
        let bbox = asset.boundingBox
        print("  bounding_box:")
        let formatVec = { (v: SIMD3<Float>) in String(format: "%.6f, %.6f, %.6f", v.x, v.y, v.z) }
        print("    min: [\(formatVec(bbox.minBounds))]")
        print("    max: [\(formatVec(bbox.maxBounds))]")
        print("    extent: [\(formatVec(bbox.maxBounds - bbox.minBounds))]")
        print("\nobjects:")
        
        for index in 0..<asset.count {
            printObjectInfo(object: asset.object(at: index), depth: 0, isFirstInList: index == 0)
        }
    }
    
    private static func printObjectInfo(object: MDLObject, depth: Int, isFirstInList: Bool = false) {
        let i = String(repeating: "    ", count: depth)
        let type = String(describing: type(of: object))
        
        if !isFirstInList { print() }
        
        print("\(i)> name: \"\(object.name)\"")
        print("\(i)  type: \(type)")
        
        if let transform = object.transform {
            let matrix = transform.matrix
            let pos = SIMD3<Float>(matrix.columns.3.x, matrix.columns.3.y, matrix.columns.3.z)
            let scale = SIMD3<Float>(
                length(SIMD3<Float>(matrix.columns.0.x, matrix.columns.0.y, matrix.columns.0.z)),
                length(SIMD3<Float>(matrix.columns.1.x, matrix.columns.1.y, matrix.columns.1.z)),
                length(SIMD3<Float>(matrix.columns.2.x, matrix.columns.2.y, matrix.columns.2.z))
            )
            
            let eps: Float = 0.0001
            let isDefault = abs(pos.x) < eps && abs(pos.y) < eps && abs(pos.z) < eps &&
            abs(scale.x - 1.0) < eps && abs(scale.y - 1.0) < eps && abs(scale.z - 1.0) < eps
            
            if !isDefault {
                print("\(i)  transform:")
                let formatVec = { (v: SIMD3<Float>) in String(format: "%.6f, %.6f, %.6f", v.x, v.y, v.z) }
                print("\(i)    position: [\(formatVec(pos))]")
                print("\(i)    scale: [\(formatVec(scale))]")
            }
        }
        
        if let mesh = object as? MDLMesh {
            print("\(i)  mesh:")
            print("\(i)    vertex_count: \(mesh.vertexCount)")
            print("\(i)    submesh_count: \(mesh.submeshes?.count ?? 0)")
            
            let bbox = mesh.boundingBox
            print("\(i)    bounding_box:")
            let formatVec = { (v: SIMD3<Float>) in String(format: "%.6f, %.6f, %.6f", v.x, v.y, v.z) }
            print("\(i)      min: [\(formatVec(bbox.minBounds))]")
            print("\(i)      max: [\(formatVec(bbox.maxBounds))]")
            
            let attrs = mesh.vertexDescriptor.attributes.compactMap { $0 as? MDLVertexAttribute }
                .filter { $0.format != .invalid }
            
            if !attrs.isEmpty {
                print("\(i)    vertex_attributes:")
                let attrsByBuffer = Dictionary(grouping: attrs) { $0.bufferIndex }
                for bufferIndex in attrsByBuffer.keys.sorted() {
                    guard let bufferAttrs = attrsByBuffer[bufferIndex] else { continue }
                    var stride = 0
                    if bufferIndex < mesh.vertexDescriptor.layouts.count,
                       let layout = mesh.vertexDescriptor.layouts[bufferIndex] as? MDLVertexBufferLayout {
                        stride = layout.stride
                    }
                    print("\(i)      buffer[\(bufferIndex)] (stride: \(stride) bytes):")
                    for attr in bufferAttrs.sorted(by: { $0.offset < $1.offset }) {
                        print("\(i)        - name: \"\(attr.name)\"")
                        print("\(i)          format: \"\(attr.format.displayName)\"")
                        print("\(i)          offset: \(attr.offset)")
                    }
                }
            }
        }
        
        let children = object.children.objects
        if !children.isEmpty {
            print("\(i)  children: [")
            for (index, child) in children.enumerated() {
                printObjectInfo(object: child, depth: depth + 1, isFirstInList: index == 0)
            }
            print("\(i)  ]")
        }
    }
}

extension MDLVertexFormat {
    var displayName: String {
        switch self {
        case .invalid: return "Invalid"
        case .float4: return "Float4"
        case .float3: return "Float3"
        case .float2: return "Float2"
        case .float: return "Float"
        case .int4: return "Int4"
        case .int3: return "Int3"
        case .int2: return "Int2"
        case .int: return "Int"
        case .uChar4: return "UnsignedChar4"
        case .uChar3: return "UnsignedChar3"
        case .uChar2: return "UnsignedChar2"
        case .uChar: return "UnsignedChar"
        case .uChar4Normalized: return "UnsignedChar4Normalized"
        case .uChar3Normalized: return "UnsignedChar3Normalized"
        case .uChar2Normalized: return "UnsignedChar2Normalized"
        case .uCharNormalized: return "UnsignedCharNormalized"
        case .char4: return "Char4"
        case .char3: return "Char3"
        case .char2: return "Char2"
        case .char: return "Char"
        case .char4Normalized: return "Char4Normalized"
        case .char3Normalized: return "Char3Normalized"
        case .char2Normalized: return "Char2Normalized"
        case .charNormalized: return "CharNormalized"
        case .uShort4: return "UnsignedShort4"
        case .uShort3: return "UnsignedShort3"
        case .uShort2: return "UnsignedShort2"
        case .uShort: return "UnsignedShort"
        case .uShort4Normalized: return "UnsignedShort4Normalized"
        case .uShort3Normalized: return "UnsignedShort3Normalized"
        case .uShort2Normalized: return "UnsignedShort2Normalized"
        case .uShortNormalized: return "UnsignedShortNormalized"
        case .short4: return "Short4"
        case .short3: return "Short3"
        case .short2: return "Short2"
        case .short: return "Short"
        case .short4Normalized: return "Short4Normalized"
        case .short3Normalized: return "Short3Normalized"
        case .short2Normalized: return "Short2Normalized"
        case .shortNormalized: return "ShortNormalized"
        case .half4: return "Half4"
        case .half3: return "Half3"
        case .half2: return "Half2"
        case .half: return "Half"
        default: return "Format(\(self.rawValue))"
        }
    }
}
