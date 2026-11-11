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
                      cos(dot(p, vec2(-0.29, 0.83)) - t * 0.65)) * 0.075;
#if WATER_WAVES == 2
    slope += vec2(cos(dot(p, vec2(1.31, -0.69)) - t),
                  sin(dot(p, vec2(0.93, 1.17)) + t * 0.8)) * 0.025;
#endif
    // Side faces stay undistorted, including flowing water/waterfall edges.
    return wfNormalize(normal + vec3(slope.x, 0.0, slope.y) * WAVE_STRENGTH * max(normal.y, 0.0));
#else
    return normal;
#endif
}
vec4 wfWater(vec3 position, vec3 normal, vec3 biomeTint, vec3 surfaceTexture, vec2 lm) {
    normal = wfWaterNormal(normal, position + cameraPosition);
    if (isEyeInWater == 1) normal = -normal;
    vec3 viewDirection = wfNormalize(-position);
    vec3 reflected = reflect(-viewDirection, normal);
    float fresnel = 0.02 + 0.98 * pow(1.0 - clamp(dot(normal, viewDirection), 0.0, 1.0), 5.0);
    float tintLuma = wfLuma(biomeTint);
    vec3 tint = max(mix(vec3(tintLuma), biomeTint, WATER_SATURATION), vec3(0.01));
    vec3 base = wfLinear(tint) * (0.85 + 0.15 * surfaceTexture);
    vec3 color = base * wfLight(position, normal, lm);
    vec3 reflection = wfSky(reflected);
#if WATER_REFLECTIONS > 0 && WF_DIMENSION == 0
    float highlight = pow(max(dot(reflected, wfSunDir()), 0.0), 128.0);
    float nightHighlight = pow(max(dot(reflected, wfMoonDir()), 0.0), 128.0);
    reflection += (vec3(1.0, 0.82, 0.57) * highlight * wfDay()
                 + vec3(0.32, 0.48, 0.72) * nightHighlight * (1.0 - wfDay()))
                 * smoothstep(0.15, 0.65, wfBlockLevel(lm.y)) * (1.0 - rainStrength);
#if WATER_REFLECTIONS == 2
    reflection += vec3(0.12, 0.10, 0.07) * pow(max(dot(reflected, wfSunDir()), 0.0), 32.0)
                  * wfDay() * wfBlockLevel(lm.y) * (1.0 - rainStrength);
#endif
#endif
    // Reflections fade indoors. Out-of-screen geometry is never fabricated.
    float skyAccess = wfBlockLevel(lm.y);
    color = mix(color, reflection, fresnel * skyAccess);
    vec2 uv = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
    float depth = texture(depthtex1, uv).r;
    vec3 surfaceView = (gbufferModelView * vec4(position, 1.0)).xyz;
    float thickness = depth >= 0.999999 ? 24.0 : max(length(wfViewPosition(uv, depth)) - length(surfaceView), 0.0);
    // Scalar absorption is compatible with ordinary sorted alpha blending.
    // Per-channel transmission would require an opaque-color snapshot pass.
    float opacity = clamp((0.13 + 0.58 * (1.0 - exp(-thickness * 0.10))) / WATER_TRANSPARENCY, 0.10, 0.85);
    opacity = mix(opacity, 0.95, fresnel * skyAccess);
    return vec4(color, opacity);
}
#endif
