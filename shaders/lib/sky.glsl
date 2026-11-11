#ifndef WF_SKY_LIB
#define WF_SKY_LIB
vec3 wfSky(vec3 direction) {
#if WF_DIMENSION == 0
    float day = wfDay();
    float horizon = pow(1.0 - clamp(direction.y, 0.0, 1.0), 3.0);
    vec3 zenith = mix(vec3(0.012, 0.023, 0.060), vec3(0.13, 0.34, 0.69), day);
    vec3 low = mix(vec3(0.045, 0.066, 0.115), vec3(0.52, 0.66, 0.80), day);
    float sunset = (1.0 - smoothstep(0.03, 0.40, abs(wfSunDir().y))) * horizon;
    float towardsSun = pow(max(dot(direction, wfSunDir()), 0.0), 6.0);
    vec3 color = mix(zenith, low, horizon);
    color = mix(color, vec3(0.80, 0.33, 0.10), sunset * (0.25 + towardsSun * 0.55));
    return mix(color, vec3(wfLuma(color)) * vec3(0.88, 0.94, 1.0), rainStrength * 0.65);
#elif WF_DIMENSION == -1
    return mix(wfLinear(fogColor), vec3(0.13, 0.035, 0.018), 0.25);
#else
    return mix(vec3(0.018, 0.020, 0.045), vec3(0.065, 0.045, 0.10),
               pow(1.0 - abs(direction.y), 2.0));
#endif
}
#endif
