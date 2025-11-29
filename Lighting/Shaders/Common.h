//
//  Common.h
//  Lighting
//
//  Created by GH on 11/28/25.
//

#import <simd/simd.h>

typedef struct {
    simd_float3 direction; // 方向
    simd_float3 color;     // 颜色
} Light;

typedef struct {
    matrix_float4x4 mvpMatrix;
    simd_float3x3 normalMatrix;
    Light light;
} Uniforms;
