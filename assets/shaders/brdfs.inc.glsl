vec3 F_Schlick(vec3 f0, float VdotH) {
    return f0 + (1.0 - f0) * pow(1.0 - VdotH, 5.0);
}

float F_Cook_Torrance(float f0, float VdotH) {
    float sqrtf0 = sqrt(f0);
    float eta = (1.0 + sqrtf0) / (1.0 - sqrtf0);
    float g = sqrt(eta * eta + VdotH * VdotH - 1.0);
    float a = (g - VdotH) / (g + VdotH);
    float b = ((g + VdotH) * VdotH - 1.0) / ((g - VdotH) * VdotH + 1.0);
    return a * a * (1.0 + b * b) / 2.0;
}


float G_GGX(float d, float alpha) {
    float a2 = alpha * alpha;
    return 2.0 * d / (d + sqrt(a2 + (1 - a2) * d * d));
}

float G_Smith_GGX(float NdotL, float NdotV, float alpha) {
    return G_GGX(NdotL, alpha) * G_GGX(NdotV, alpha);
}

float G_Neumann(float NdotL, float NdotV) {
    return NdotL * NdotV / max(NdotL, NdotV);
}

float G_Cook_Torrance(float NdotL, float NdotV, float NdotH, float VdotH) {
    float x = 2.0 * NdotH / VdotH;
    return min(1.0, min(x * NdotV, x * NdotL));
}

float V_Kelemen(float LdotH) {
    return 1.0 / (LdotH * LdotH);
}

float D_Beckmann(float NdotH, float alpha) {
    if (alpha < 1e-3) {
        return 0;
    }
    float a2 = alpha * alpha;
    float nh2 = NdotH * NdotH;
    float nh4 = nh2 * nh2;
    return exp((nh2 - 1.0) / (a2 * nh2)) / (PI * a2 * nh4);
}

float D_GGX_Trowbridge_Reitz(float NdotH, float alpha) {
    float a2 = alpha * alpha;
    float x = NdotH * NdotH * (a2 - 1) + 1;
    return a2 / (PI * x * x);
}

float D_Blinn(float NdotH, float alpha) {
    float a2 = alpha * alpha;
    return pow(NdotH, (2.0/a2 - 2.0)) / (PI * a2);
}


vec3 Shade_Cook_Torrance(vec3 l, vec3 p, vec3 n, vec3 albedo, float metalness, float roughness) {
    float NdotL = clamp(dot(n, l), 0.0, 1.0);
    if (NdotL < 1e-5) {
        return vec3(0.0);
    }

    vec3 v = normalize(eye - p);
    vec3 h = normalize(l + v);
    float NdotH = clamp(dot(n, h), 0.0, 1.0);
    if (NdotH < 1e-5) {
        return vec3(0.0);
    }

    vec3 f0 = mix(vec3(0.03), albedo, metalness);

    float NdotV = abs(dot(n, v)) + 1e-5;
    float LdotH = clamp(dot(l, h), 0.0, 1.0);
    float VdotH = clamp(dot(v, h), 0.0, 1.0);

    vec3 F = F_Schlick(f0, VdotH);
    float G = G_Smith_GGX(NdotL, NdotV, roughness);
    float D = D_GGX_Trowbridge_Reitz(NdotH, roughness);

    vec3 specular = vec3(D * G / (4 * NdotL * NdotV));
    vec3 diffuse = albedo;

    return lightColor * mix(diffuse, specular, F) * NdotL;
}
