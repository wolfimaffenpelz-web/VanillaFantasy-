#ifndef WF_WATER_BLEND_LIB
#define WF_WATER_BLEND_LIB
uniform sampler2D depthtex0;
#if WATER_BIOME_BLEND > 0
uniform sampler2D colortex1; // linear water tint, linear view depth
uniform sampler2D colortex2; // diffuse color response, face orientation
vec3 wfWaterWorldPosition(vec2 uv, float viewDepth) {
    vec4 ray = gbufferProjectionInverse * vec4(uv * 2.0 - 1.0, 0.0, 1.0);
    vec3 viewPosition = ray.xyz * (viewDepth / max(-ray.z, 1e-6));
    return (gbufferModelViewInverse * vec4(viewPosition, 1.0)).xyz;
}
#endif
vec3 wfBlendWaterBiomes(vec3 color, vec2 uv) {
#if WATER_BIOME_BLEND > 0
    ivec2 size = textureSize(colortex1, 0);
    ivec2 pixel = clamp(ivec2(uv * vec2(size)), ivec2(0), size - 1);
    vec4 tint = texelFetch(colortex1, pixel, 0);
    if (tint.a <= 0.0) return color;
    vec4 response = texelFetch(colortex2, pixel, 0);
    if (response.a < 0.5) return color;
    vec3 position = wfWaterWorldPosition(uv, tint.a);
    vec3 axis1 = vec3(1.0, 0.0, 0.0);
    vec3 axis2 = vec3(0.0, 0.0, 1.0);
    vec3 planeNormal = vec3(0.0, 1.0, 0.0);
    if (response.a > 1.5 && response.a < 2.5) {
        axis1 = vec3(0.0, 1.0, 0.0);
        planeNormal = vec3(1.0, 0.0, 0.0);
    } else if (response.a > 2.5) {
        axis2 = vec3(0.0, 1.0, 0.0);
        planeNormal = vec3(0.0, 0.0, 1.0);
    }
    float radius = float(WATER_BIOME_BLEND);
    vec3 tintSum = tint.rgb * 0.25;
    float weightSum = 0.25;
    for (int i = 0; i < 8; ++i) {
        // Paired non-axial taps avoid leaving a strong central seam. Different
        // radii distribute the transition over the requested world-space area.
        vec2 stepXY = vec2(0.25, 0.15);
        if (i % 4 == 1) stepXY = vec2(0.60, -0.30);
        if (i % 4 == 2) stepXY = vec2(0.40, 0.80);
        if (i % 4 == 3) stepXY = vec2(0.95, 0.10);
        if (i >= 4) stepXY = -stepXY;
        vec3 target = position + (axis1 * stepXY.x + axis2 * stepXY.y) * radius;
        vec4 clip = gbufferProjection * gbufferModelView * vec4(target, 1.0);
        if (clip.w <= 0.001) continue;
        vec2 sampleUV = clip.xy / clip.w * 0.5 + 0.5;
        if (any(lessThan(sampleUV, vec2(0.0))) || any(greaterThanEqual(sampleUV, vec2(1.0)))) continue;
        ivec2 samplePixel = clamp(ivec2(sampleUV * vec2(size)), ivec2(0), size - 1);
        vec4 neighbor = texelFetch(colortex1, samplePixel, 0);
        if (neighbor.a <= 0.0) continue;
        float face = texelFetch(colortex2, samplePixel, 0).a;
        if (abs(face - response.a) > 0.1) continue;
        // Reject non-water samples, occluders and different surface planes.
        vec3 sampled = wfWaterWorldPosition(sampleUV, neighbor.a);
        vec3 delta = sampled - position;
        float distanceSquared = dot(delta, delta);
        if (abs(dot(delta, planeNormal)) > 0.20 || distanceSquared > radius * radius * 3.1) continue;
        float weight = exp(-distanceSquared / max(radius * radius, 0.01));
        tintSum += neighbor.rgb * weight;
        weightSum += weight;
    }
    // Recolor only the diffuse water contribution. Do not blur geometry,
    // transmitted terrain, animated flow detail, shadows or specular highlights.
    color += response.rgb * (tintSum / weightSum - tint.rgb);
    return max(color, vec3(0.0));
#else
    return color;
#endif
}
#endif
