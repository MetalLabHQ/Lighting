//
//  LookAt.swift
//  Lighting
//
//  Created by GH on 11/28/25.
//

import simd

/// 视图矩阵 View Matrix
/// - Parameters:
///   - eye: 相机位置
///   - target: 目标点
///   - up: 参考上方向向量
func lookAt(eye: SIMD3<Float>, target: SIMD3<Float>, up: SIMD3<Float>) -> float4x4 {
    let zAxis = normalize(target - eye)
    let xAxis = normalize(cross(zAxis, up))
    let yAxis = cross(xAxis, zAxis)
    
    let X = SIMD4<Float>(xAxis.x, yAxis.x, zAxis.x, 0)
    let Y = SIMD4<Float>(xAxis.y, yAxis.y, zAxis.y, 0)
    let Z = SIMD4<Float>(xAxis.z, yAxis.z, zAxis.z, 0)
    let W = SIMD4<Float>(-dot(xAxis, eye), -dot(yAxis, eye), -dot(zAxis, eye), 1)
    
    return float4x4(X, Y, Z, W)
}
