#ifndef WF_SHADOW
#define WF_SHADOW
#if SHADOWS == 1 && WF_DIMENSION == 0
uniform sampler2D shadowtex0;
const bool shadowtex0Nearest = true;
const float shadowIntervalSize = 2.0;
float wfShadow(vec3 position, vec3 normal, vec3 lightDir) {
    float fade = 1.0 - smoothstep(shadowDistance * 0.80, shadowDistance, length(position.xz));
    if (fade <= 0.0) return 1.0;
    // Offset in world units before projection; depth bias is intentionally small.
    vec3 offset = normal * (0.018 + 0.035 * (1.0 - max(dot(normal, lightDir), 0.0)));
    vec4 clip = shadowProjection * shadowModelView * vec4(position + offset, 1.0);
    vec3 uvz = clip.xyz / max(abs(clip.w), 1e-6) * 0.5 + 0.5;
    float border = 3.0 / float(shadowMapResolution);
    if (any(lessThan(uvz, vec3(border))) || any(greaterThan(uvz, vec3(1.0 - border)))) return 1.0;
    float reference = uvz.z - 0.00008;
    float visibility = 0.0;
    float texel = SHADOW_SOFTNESS / float(shadowMapResolution);
#if SHADOW_FILTER == 0
    visibility = step(reference, texture(shadowtex0, uvz.xy).r);
#elif SHADOW_FILTER == 1
    for (int i = 0; i < 4; ++i) {
        vec2 offsetUV = vec2(float(i % 2), float(i / 2)) - 0.5;
        visibility += step(reference, texture(shadowtex0, uvz.xy + offsetUV * texel).r) * 0.25;
    }
#else
    for (int i = 0; i < 9; ++i) {
        vec2 offsetUV = vec2(float(i % 3), float(i / 3)) - 1.0;
        visibility += step(reference, texture(shadowtex0, uvz.xy + offsetUV * texel).r) / 9.0;
    }
#endif
    return mix(1.0, visibility, fade * SHADOW_STRENGTH);
}
#else
float wfShadow(vec3 position, vec3 normal, vec3 lightDir) { return 1.0; }
#endif
#endif
