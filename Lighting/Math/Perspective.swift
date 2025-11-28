//
//  Perspective.swift
//  Lighting
//
//  Created by GH on 11/28/25.
//

import simd

/// 透视投影矩阵 Perspective Projection Matrix
/// - Parameters:
///   - aspect: 宽高比（宽度 / 高度）
///   - fovy: 垂直视野角度（弧度制）
///   - near: 近裁剪平面距离
///   - far: 远裁剪平面距离
func perspective(aspect: Float, fovy: Float, near: Float, far: Float) -> float4x4 {
    let fovYHalf = fovy * 0.5
    let cotHalfFovY = 1.0 / tan(fovYHalf)
    
    // 根据宽高比调整水平缩放
    let scaleX = cotHalfFovY / aspect
    let scaleY = cotHalfFovY
    
    // 将 [near, far] 映射到 [0, 1]
    let zRange = far - near
    let scaleZ = far / zRange
    let offsetZ = -(far * near) / zRange
    
    return float4x4(
        SIMD4<Float>(scaleX, 0,      0,        0),
        SIMD4<Float>(0,      scaleY, 0,        0),
        SIMD4<Float>(0,      0,      scaleZ,   1),
        SIMD4<Float>(0,      0,      offsetZ,  0)
    )
}
