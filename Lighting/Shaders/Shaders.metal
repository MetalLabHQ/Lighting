//
//  Shaders.metal
//  Lighting
//
//  Created by GH on 11/28/25.
//

#import "Common.h"
using namespace metal;

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
    out.normal = normalize(uniforms.normalMatrix * in.normal); // 归一化法线
    
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]], constant Uniforms &uniforms [[buffer(1)]])
{
    float3 normal = in.normal;
    float3 lightDirection = normalize(-uniforms.light.direction);
    float NdotL = max(dot(normal, lightDirection), 0.0);
    
    float3 diffuse = NdotL * uniforms.light.color;
    float3 color = diffuse;
    
    return float4(color, 1.0);
}
