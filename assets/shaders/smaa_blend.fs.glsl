uniform sampler2D edge_tex; 
uniform sampler2D area_tex; 
uniform sampler2D search_tex; 

in vec2 texcoord; 
in vec2 pixcoord; 
in vec4 offset[3]; 

vec2 SMAAArea(sampler2D areaTex, vec2 dist, float e1, float e2, float offset) {
    vec2 texcoord = fma(vec2(16, 16), round(4.0 * vec2(e1, e2)), dist);
    texcoord = fma((1.0 / vec2(160.0, 560.0)), texcoord, 0.5 * (1.0 / vec2(160.0, 560.0)));
    texcoord.y = fma((1.0 / 7.0), offset, texcoord.y);
    return textureLod(areaTex, texcoord, 0.0).rg;
}

vec2 SMAADecodeDiagBilinearAccess(vec2 e) {
    e.r = e.r * abs(5.0 * e.r - 5.0 * 0.75);
    return round(e);
}

vec4 SMAADecodeDiagBilinearAccess(vec4 e) {
    e.rb = e.rb * abs(5.0 * e.rb - 5.0 * 0.75);
    return round(e);
}

vec2 SMAASearchDiag1(sampler2D edgesTex, vec2 texcoord, vec2 dir, out vec2 e) {
    vec4 coord = vec4(texcoord, -1.0, 1.0);
    vec3 t = vec3(SMAA_RT_METRICS.xy, 1.0);
    while (coord.z < float(16 - 1) &&
           coord.w > 0.9) {
        coord.xyz = fma(t, vec3(dir, 1.0), coord.xyz);
        e = textureLod(edgesTex, coord.xy, 0.0).rg;
        coord.w = dot(e, vec2(0.5, 0.5));
    }
    return coord.zw;
}


vec2 SMAASearchDiag2(sampler2D edgesTex, vec2 texcoord, vec2 dir, out vec2 e) {
    vec4 coord = vec4(texcoord, -1.0, 1.0);
    coord.x += 0.25 * SMAA_RT_METRICS.x;
    vec3 t = vec3(SMAA_RT_METRICS.xy, 1.0);
    while (coord.z < float(16 - 1) &&
           coord.w > 0.9) {
        coord.xyz = fma(t, vec3(dir, 1.0), coord.xyz);
        e = textureLod(edgesTex, coord.xy, 0.0).rg;
        e = SMAADecodeDiagBilinearAccess(e);
        coord.w = dot(e, vec2(0.5, 0.5));
    }
    return coord.zw;
}

vec2 SMAAAreaDiag(sampler2D areaTex, vec2 dist, vec2 e, float offset) {
    vec2 texcoord = fma(vec2(20, 20), e, dist);
    texcoord = fma((1.0 / vec2(160.0, 560.0)), texcoord, 0.5 * (1.0 / vec2(160.0, 560.0)));
    texcoord.x += 0.5;
    texcoord.y += (1.0 / 7.0) * offset;
    return textureLod(areaTex, texcoord, 0.0).rg;
}

vec2 SMAACalculateDiagWeights(sampler2D edgesTex, sampler2D areaTex, vec2 texcoord, vec2 e, vec4 subsampleIndices) {
    vec2 weights = vec2(0.0, 0.0);
    vec4 d;
    vec2 end;
    if (e.r > 0.0) {
        d.xz = SMAASearchDiag1(edgesTex, texcoord, vec2(-1.0, 1.0), end);
        d.x += float(end.y > 0.9);
    } else
        d.xz = vec2(0.0, 0.0);
    d.yw = SMAASearchDiag1(edgesTex, texcoord, vec2(1.0, -1.0), end);
   
    if (d.x + d.y > 2.0) {
        vec4 coords = fma(vec4(-d.x + 0.25, d.x, d.y, -d.y - 0.25), SMAA_RT_METRICS.xyxy, texcoord.xyxy);
        vec4 c;
        c.xy = textureLodOffset(edgesTex, coords.xy, 0.0, ivec2(-1, 0)).rg;
        c.zw = textureLodOffset(edgesTex, coords.zw, 0.0, ivec2( 1, 0)).rg;
        c.yxwz = SMAADecodeDiagBilinearAccess(c.xyzw);

        vec2 cc = fma(vec2(2.0, 2.0), c.xz, c.yw);
        SMAAMovc(bvec2(step(0.9, d.zw)), cc, vec2(0.0, 0.0));
        weights += SMAAAreaDiag(areaTex, d.xy, cc, subsampleIndices.z);
    }
    d.xz = SMAASearchDiag2(edgesTex, texcoord, vec2(-1.0, -1.0), end);
    if (textureLodOffset(edgesTex, texcoord, 0.0, ivec2(1, 0)).r > 0.0) {
        d.yw = SMAASearchDiag2(edgesTex, texcoord, vec2(1.0, 1.0), end);
        d.y += float(end.y > 0.9);
    } else
        d.yw = vec2(0.0, 0.0);
   
    if (d.x + d.y > 2.0) {
        vec4 coords = fma(vec4(-d.x, -d.x, d.y, d.y), SMAA_RT_METRICS.xyxy, texcoord.xyxy);
        vec4 c;
        c.x = textureLodOffset(edgesTex, coords.xy, 0.0, ivec2(-1, 0)).g;
        c.y = textureLodOffset(edgesTex, coords.xy, 0.0, ivec2( 0, -1)).r;
        c.zw = textureLodOffset(edgesTex, coords.zw, 0.0, ivec2( 1, 0)).gr;
        vec2 cc = fma(vec2(2.0, 2.0), c.xz, c.yw);
        SMAAMovc(bvec2(step(0.9, d.zw)), cc, vec2(0.0, 0.0));
        weights += SMAAAreaDiag(areaTex, d.xy, cc, subsampleIndices.w).gr;
    }
    return weights;
}


float SMAASearchLength(sampler2D searchTex, vec2 e, float offset) {
    vec2 scale = vec2(66.0, 33.0) * vec2(0.5, -1.0);
    vec2 bias = vec2(66.0, 33.0) * vec2(offset, 1.0);
    scale += vec2(-1.0, 1.0);
    bias += vec2( 0.5, -0.5);
    scale *= 1.0 / vec2(64.0, 16.0);
    bias *= 1.0 / vec2(64.0, 16.0);
    return textureLod(searchTex, fma(scale, e, bias), 0.0).r;
}


float SMAASearchXLeft(sampler2D edgesTex, sampler2D searchTex, vec2 texcoord, float end) {
    vec2 e = vec2(0.0, 1.0);
    while (texcoord.x > end &&
           e.g > 0.8281 &&
           e.r == 0.0) {
        e = textureLod(edgesTex, texcoord, 0.0).rg;
        texcoord = fma(-vec2(2.0, 0.0), SMAA_RT_METRICS.xy, texcoord);
    }
    float offset = fma(-(255.0 / 127.0), SMAASearchLength(searchTex, e, 0.0), 3.25);
    return fma(SMAA_RT_METRICS.x, offset, texcoord.x);
}


float SMAASearchXRight(sampler2D edgesTex, sampler2D searchTex, vec2 texcoord, float end) {
    vec2 e = vec2(0.0, 1.0);
    while (texcoord.x < end &&
           e.g > 0.8281 &&
           e.r == 0.0) {
        e = textureLod(edgesTex, texcoord, 0.0).rg;
        texcoord = fma(vec2(2.0, 0.0), SMAA_RT_METRICS.xy, texcoord);
    }
    float offset = fma(-(255.0 / 127.0), SMAASearchLength(searchTex, e, 0.5), 3.25);
    return fma(-SMAA_RT_METRICS.x, offset, texcoord.x);
}

float SMAASearchYUp(sampler2D edgesTex, sampler2D searchTex, vec2 texcoord, float end) {
    vec2 e = vec2(1.0, 0.0);
    while (texcoord.y > end &&
           e.r > 0.8281 &&
           e.g == 0.0) {
        e = textureLod(edgesTex, texcoord, 0.0).rg;
        texcoord = fma(-vec2(0.0, 2.0), SMAA_RT_METRICS.xy, texcoord);
    }
    float offset = fma(-(255.0 / 127.0), SMAASearchLength(searchTex, e.gr, 0.0), 3.25);
    return fma(SMAA_RT_METRICS.y, offset, texcoord.y);
}

float SMAASearchYDown(sampler2D edgesTex, sampler2D searchTex, vec2 texcoord, float end) {
    vec2 e = vec2(1.0, 0.0);
    while (texcoord.y < end &&
           e.r > 0.8281 &&
           e.g == 0.0) {
        e = textureLod(edgesTex, texcoord, 0.0).rg;
        texcoord = fma(vec2(0.0, 2.0), SMAA_RT_METRICS.xy, texcoord);
    }
    float offset = fma(-(255.0 / 127.0), SMAASearchLength(searchTex, e.gr, 0.5), 3.25);
    return fma(-SMAA_RT_METRICS.y, offset, texcoord.y);
}


void SMAADetectHorizontalCornerPattern(sampler2D edgesTex, inout vec2 weights, vec4 texcoord, vec2 d) {
    vec2 leftRight = step(d.xy, d.yx);
    vec2 rounding = (1.0 - (float(25) / 100.0)) * leftRight;
    rounding /= leftRight.x + leftRight.y;
    vec2 factor = vec2(1.0, 1.0);
    factor.x -= rounding.x * textureLodOffset(edgesTex, texcoord.xy, 0.0, ivec2(0, 1)).r;
    factor.x -= rounding.y * textureLodOffset(edgesTex, texcoord.zw, 0.0, ivec2(1, 1)).r;
    factor.y -= rounding.x * textureLodOffset(edgesTex, texcoord.xy, 0.0, ivec2(0, -2)).r;
    factor.y -= rounding.y * textureLodOffset(edgesTex, texcoord.zw, 0.0, ivec2(1, -2)).r;
    weights *= clamp(factor, 0.0, 1.0);
}

void SMAADetectVerticalCornerPattern(sampler2D edgesTex, inout vec2 weights, vec4 texcoord, vec2 d) {
    vec2 leftRight = step(d.xy, d.yx);
    vec2 rounding = (1.0 - (float(25) / 100.0)) * leftRight;
    rounding /= leftRight.x + leftRight.y;
    vec2 factor = vec2(1.0, 1.0);
    factor.x -= rounding.x * textureLodOffset(edgesTex, texcoord.xy, 0.0, ivec2( 1, 0)).g;
    factor.x -= rounding.y * textureLodOffset(edgesTex, texcoord.zw, 0.0, ivec2( 1, 1)).g;
    factor.y -= rounding.x * textureLodOffset(edgesTex, texcoord.xy, 0.0, ivec2(-2, 0)).g;
    factor.y -= rounding.y * textureLodOffset(edgesTex, texcoord.zw, 0.0, ivec2(-2, 1)).g;
    weights *= clamp(factor, 0.0, 1.0);
}


vec4 SMAABlendingWeightCalculationPS(vec2 texcoord, vec2 pixcoord, vec4 offset[3], sampler2D edgesTex, sampler2D areaTex, sampler2D searchTex, vec4 subsampleIndices) {
    vec4 weights = vec4(0.0, 0.0, 0.0, 0.0);
    vec2 e = texture(edgesTex, texcoord).rg;

    if (e.g > 0.0) {
        weights.rg = SMAACalculateDiagWeights(edgesTex, areaTex, texcoord, e, subsampleIndices);
       
        if (weights.r == -weights.g) {
            vec2 d;

            vec3 coords;
            coords.x = SMAASearchXLeft(edgesTex, searchTex, offset[0].xy, offset[2].x);
            coords.y = offset[1].y;
            d.x = coords.x;

            float e1 = textureLod(edgesTex, coords.xy, 0.0).r;

            coords.z = SMAASearchXRight(edgesTex, searchTex, offset[0].zw, offset[2].y);
            d.y = coords.z;

            d = abs(round(fma(SMAA_RT_METRICS.zz, d, -pixcoord.xx)));

            vec2 sqrt_d = sqrt(d);

            float e2 = textureLodOffset(edgesTex, coords.zy, 0.0, ivec2(1, 0)).r;
            weights.rg = SMAAArea(areaTex, sqrt_d, e1, e2, subsampleIndices.y);
            coords.y = texcoord.y;
            SMAADetectHorizontalCornerPattern(edgesTex, weights.rg, coords.xyzy, d);
        } else e.r = 0.0;
    }

   
    if (e.r > 0.0) {
        vec2 d;

        vec3 coords;
        coords.y = SMAASearchYUp(edgesTex, searchTex, offset[1].xy, offset[2].z);
        coords.x = offset[0].x;
        d.x = coords.y;

        float e1 = textureLod(edgesTex, coords.xy, 0.0).g;

        coords.z = SMAASearchYDown(edgesTex, searchTex, offset[1].zw, offset[2].w);
        d.y = coords.z;

        d = abs(round(fma(SMAA_RT_METRICS.ww, d, -pixcoord.yy)));

        vec2 sqrt_d = sqrt(d);

        float e2 = textureLodOffset(edgesTex, coords.xz, 0.0, ivec2(0, 1)).g;

        weights.ba = SMAAArea(areaTex, sqrt_d, e1, e2, subsampleIndices.x);

        coords.x = texcoord.x;
        SMAADetectVerticalCornerPattern(edgesTex, weights.ba, coords.xyxz, d);
    }

    return weights;
}


void main() 
{ 
	gl_FragColor = SMAABlendingWeightCalculationPS(texcoord, pixcoord, offset, edge_tex, area_tex, search_tex, ivec4(0)); 
} 