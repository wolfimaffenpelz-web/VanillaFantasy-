#ifndef WF_FOG_LIB
#define WF_FOG_LIB
#include "/lib/sky.glsl"
float wfFogAmount(vec3 position) {
    if (isEyeInWater == 1) return 0.0;
    float distanceFromEye = length(position);
    float distanceFog = smoothstep(far * 0.65, far, distanceFromEye);
#if WF_DIMENSION == 0
    float haze = 1.0 - exp(-distanceFromEye * (0.0002 + 0.0012 * rainStrength) * ATMOSPHERE);
#elif WF_DIMENSION == -1
    float haze = 1.0 - exp(-distanceFromEye * 0.0025 * ATMOSPHERE);
#else
    float haze = 1.0 - exp(-distanceFromEye * 0.0007 * ATMOSPHERE);
#endif
    return max(distanceFog, haze);
}
vec3 wfFog(vec3 color, vec3 position) {
#if WF_DIMENSION == 0
    vec3 target = wfSky(wfNormalize(vec3(position.x, 0.01, position.z)));
#elif WF_DIMENSION == -1
    vec3 target = wfLinear(fogColor);
#else
    vec3 target = wfSky(wfNormalize(position));
#endif
    return mix(color, target, wfFogAmount(position));
}
#endif
