#ifndef WF_LIGHTING
#define WF_LIGHTING
#include "/lib/shadow.glsl"
vec3 wfLight(vec3 position, vec3 normal, vec2 lm) {
    float block = wfBlockCurve(wfBlockLevel(lm.x)) * BLOCK_INTENSITY;
    float sky = wfBlockLevel(lm.y);
    vec3 blockColor = mix(vec3(1.0), vec3(1.0, 0.67, 0.36), LIGHT_WARMTH * 0.65);
    vec3 ambient = vec3(0.035, 0.040, 0.050) * CAVE_BRIGHTNESS;
#if WF_DIMENSION == 0
    vec3 sunDir = wfSunDir();
    vec3 moonDir = wfMoonDir();
    float day = wfDay();
    float sunset = 1.0 - smoothstep(0.06, 0.5, sunDir.y);
    vec3 sunColor = mix(vec3(1.0, 0.96, 0.86), vec3(1.0, 0.66, 0.34), sunset * LIGHT_WARMTH * 0.65);
    ambient += mix(vec3(0.075, 0.105, 0.17) * NIGHT_BRIGHTNESS,
                   vec3(0.26, 0.32, 0.40), day) * sky;
    vec3 lightDir = wfNormalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
    float visibility = wfShadow(position, normal, lightDir);
    float skyAccess = smoothstep(0.05, 0.45, sky);
    float sunlight = max(dot(normal, sunDir), 0.0) * smoothstep(-0.02, 0.10, sunDir.y);
    float moonlight = max(dot(normal, moonDir), 0.0) * smoothstep(-0.02, 0.10, moonDir.y);
    vec3 direct = sunColor * sunlight * SUN_INTENSITY * 0.90
                + vec3(0.34, 0.48, 0.78) * moonlight * MOON_INTENSITY * 0.19;
    ambient += direct * visibility * skyAccess * (1.0 - 0.65 * rainStrength);
#elif WF_DIMENSION == -1
    ambient += vec3(0.14, 0.073, 0.047);
#else
    ambient += vec3(0.105, 0.115, 0.19);
#endif
    // The floor is independent of blocklight; positive levels retain contrast.
    return ambient * AMBIENT_BRIGHTNESS + block * blockColor + vec3(0.35 * nightVision);
}
#endif
