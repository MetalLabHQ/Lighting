//
//  Camera.swift
//  Lighting
//
//  Created by GH on 11/28/25.
//

import simd

struct Camera {
    /// 世界空间下的相机位置（Position）
    var position: SIMD3<Float>
    /// 相机注视点（Target）
    var target: SIMD3<Float>
    /// 上方向（一般为(0, 1, 0)）
    var up: SIMD3<Float>
}
