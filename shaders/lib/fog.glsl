#ifndef WF_FOG_LIB
#define WF_FOG_LIB
#include "/lib/sky.glsl"
vec3 wfFog(vec3 color, vec3 position) {
    if (isEyeInWater == 1) return color; // absorption once, in final
    float distanceFromEye = length(position);
    float distanceFog = smoothstep(far * 0.65, far, distanceFromEye);
#if WF_DIMENSION == 0
    float haze = 1.0 - exp(-distanceFromEye * (0.0002 + 0.0012 * rainStrength) * ATMOSPHERE);
    vec3 target = wfSky(wfNormalize(vec3(position.x, 0.01, position.z)));
#elif WF_DIMENSION == -1
    float haze = 1.0 - exp(-distanceFromEye * 0.0025 * ATMOSPHERE);
    vec3 target = wfLinear(fogColor);
#else
    float haze = 1.0 - exp(-distanceFromEye * 0.0007 * ATMOSPHERE);
    vec3 target = wfSky(wfNormalize(position));
#endif
    return mix(color, target, max(distanceFog, haze));
}
#endif
