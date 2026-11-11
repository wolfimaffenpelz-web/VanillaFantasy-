#ifndef WF_WATER_LIB
#define WF_WATER_LIB
#include "/lib/sky.glsl"
uniform sampler2D depthtex1;
vec3 wfViewPosition(vec2 uv, float depth) {
    vec4 p = gbufferProjectionInverse * vec4(uv * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    return p.xyz / (abs(p.w) > 1e-6 ? p.w : 1e-6);
}
vec3 wfWaterNormal(vec3 normal, vec3 absolutePosition) {
#if WATER_WAVES > 0
    // Normal waves only: no displaced block boundaries, waterfall cracks or gaps.
    vec2 p = absolutePosition.xz;
    float t = frameTimeCounter;
    vec2 slope = vec2(cos(dot(p, vec2(0.71, 0.34)) + t * 0.85),
                      cos(dot(p, vec2(-0.29, 0.83)) - t * 0.65)) * 0.045;
#if WATER_WAVES == 2
    slope += vec2(cos(dot(p, vec2(1.31, -0.69)) - t),
                  sin(dot(p, vec2(0.93, 1.17)) + t * 0.8)) * 0.015;
#endif
    // Side faces stay undistorted, including flowing water/waterfall edges.
    return wfNormalize(normal + vec3(slope.x, 0.0, slope.y) * WAVE_STRENGTH * max(normal.y, 0.0));
#else
    return normal;
#endif
}
vec4 wfWaterSurface(vec3 position, vec3 normal, vec3 biomeTint, vec3 surfaceTexture, vec2 lm,
                    out vec3 tintLinear, out vec3 tintResponse) {
    float horizontal = clamp(abs(normal.y), 0.0, 1.0);
    normal = wfWaterNormal(normal, position + cameraPosition);
    if (isEyeInWater == 1) normal = -normal;
    vec3 viewDirection = wfNormalize(-position);
    vec3 reflected = reflect(-viewDirection, normal);
    float fresnel = 0.02 + 0.98 * pow(1.0 - clamp(dot(normal, viewDirection), 0.0, 1.0), 5.0);
    vec3 waterTint = mix(biomeTint, vec3(0.14, 0.36, 0.54), 0.22);
    float tintLuma = wfLuma(waterTint);
    vec3 tint = clamp(mix(vec3(tintLuma), waterTint, WATER_SATURATION), vec3(0.015), vec3(1.0));
    tintLinear = wfLinear(tint);
    // Keep vanilla animated flow texture visible on waterfalls, without adding
    // procedural white bands. Side faces do not receive mirror-like sky glints.
    float textureDetail = mix(0.60 + 0.65 * wfLuma(surfaceTexture), 0.92 + 0.08 * wfLuma(surfaceTexture), horizontal);
    tintResponse = textureDetail * wfLight(position, normal, lm);
    vec3 color = tintLinear * tintResponse;
    vec3 reflection = wfSky(reflected) * mix(vec3(0.70, 0.80, 0.90), tint, 0.35);
#if WATER_REFLECTIONS > 0 && WF_DIMENSION == 0
    float highlight = pow(max(dot(reflected, wfSunDir()), 0.0), 96.0);
    float nightHighlight = pow(max(dot(reflected, wfMoonDir()), 0.0), 96.0);
    float glintStrength = WATER_REFLECTIONS == 2 ? 0.16 : 0.10;
    color += (tint * vec3(1.0, 0.82, 0.57) * highlight * wfDay()
             + tint * vec3(0.16, 0.24, 0.36) * nightHighlight * (1.0 - wfDay()))
             * glintStrength * horizontal * horizontal
             * smoothstep(0.15, 0.65, wfBlockLevel(lm.y)) * (1.0 - rainStrength);
#endif
    // Reflections fade indoors. Out-of-screen geometry is never fabricated.
    float skyAccess = wfBlockLevel(lm.y);
    float reflectionWeight = 0.28 * fresnel * skyAccess * horizontal * horizontal;
    color = mix(color, reflection, reflectionWeight);
    tintResponse *= 1.0 - reflectionWeight;
    vec2 uv = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
    float depth = texture(depthtex1, uv).r;
    vec3 surfaceView = (gbufferModelView * vec4(position, 1.0)).xyz;
    float thickness = depth >= 0.999999 ? 24.0 : max(length(wfViewPosition(uv, depth)) - length(surfaceView), 0.0);
    // Scalar absorption is compatible with ordinary sorted alpha blending.
    // Per-channel transmission would require an opaque-color snapshot pass.
    float surfaceOpacity = 0.50 + 0.30 * (1.0 - exp(-thickness * 0.18));
    float fallingOpacity = 0.74 + 0.13 * (1.0 - exp(-thickness * 0.20));
    float opacity = clamp(mix(fallingOpacity, surfaceOpacity, horizontal) / WATER_TRANSPARENCY, 0.25, 0.96);
    opacity = mix(opacity, 0.97, fresnel * skyAccess * horizontal * 0.35);
    return vec4(color, opacity);
}
vec4 wfWater(vec3 position, vec3 normal, vec3 biomeTint, vec3 surfaceTexture, vec2 lm) {
    vec3 tintLinear, tintResponse;
    return wfWaterSurface(position, normal, biomeTint, surfaceTexture, lm, tintLinear, tintResponse);
}
#endif
