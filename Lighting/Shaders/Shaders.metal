//
//  Shaders.metal
//  Lighting
//
//  Created by GH on 11/28/25.
//

#import "Common.h"

struct VertexIn {
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 normal;
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]], constant Uniforms &uniforms [[buffer(1)]])
{
    VertexOut out;
    
    out.position = uniforms.mvpMatrix * float4(in.position, 1.0);
    out.normal = in.normal;
    
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]]) {
    return float4(in.normal * 0.5 + 0.5, 1.0);
}
