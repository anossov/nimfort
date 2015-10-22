uniform sampler2D albedo_tex; 
uniform sampler2D blend_tex; 

in vec2 texcoord; 
in vec4 offset; 

vec4 SMAANeighborhoodBlendingPS(vec2 texcoord, vec4 offset, sampler2D colorTex, sampler2D blendTex) {
    vec4 a;
    a.x = texture(blendTex, offset.xy).a;
    a.y = texture(blendTex, offset.zw).g;
    a.wz = texture(blendTex, texcoord).xz;
    
    if (dot(a, vec4(1.0, 1.0, 1.0, 1.0)) < 1e-5) {
        vec4 color = textureLod(colorTex, texcoord, 0.0);
        return color;
    } else {
        bool h = max(a.x, a.z) > max(a.y, a.w);

        vec4 blendingOffset = vec4(0.0, a.y, 0.0, a.w);
        vec2 blendingWeight = a.yw;
        SMAAMovc(bvec4(h, h, h, h), blendingOffset, vec4(a.x, 0.0, a.z, 0.0));
        SMAAMovc(bvec2(h, h), blendingWeight, a.xz);
        blendingWeight /= dot(blendingWeight, vec2(1.0, 1.0));

        vec4 blendingCoord = fma(blendingOffset, vec4(SMAA_RT_METRICS.xy, -SMAA_RT_METRICS.xy), texcoord.xyxy);
        vec4 color = blendingWeight.x * textureLod(colorTex, blendingCoord.xy, 0.0);
        color += blendingWeight.y * textureLod(colorTex, blendingCoord.zw, 0.0);
        return color;
    }
}

void main() 
{ 
    gl_FragColor = SMAANeighborhoodBlendingPS(texcoord, offset, albedo_tex, blend_tex);     
}