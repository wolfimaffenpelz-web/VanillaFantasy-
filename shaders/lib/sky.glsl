#ifndef WF_SKY_LIB
#define WF_SKY_LIB
uniform int moonPhase;
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
vec3 wfCelestial(vec3 color, vec3 direction) {
#if WF_DIMENSION == 0
    vec3 sunDir = wfSunDir();
    vec3 moonDir = wfMoonDir();
    float sunDot = dot(direction, sunDir);
    float moonDot = dot(direction, moonDir);
    float sunRadius = 0.006;
    float moonRadius = 0.007;
    float sunEdge = cos(sunRadius);
    float aa = max(fwidth(sunDot), 0.0000001);
    float sunDisc = smoothstep(sunEdge - aa, sunEdge + aa, sunDot);
    color = mix(color, vec3(1.5, 1.18, 0.76), sunDisc * (1.0 - rainStrength));
    vec3 right = wfNormalize(cross(moonDir, vec3(0.0, 1.0, 0.0)));
    if (dot(right, right) < 0.1) right = vec3(1.0, 0.0, 0.0);
    vec3 up = wfNormalize(cross(right, moonDir));
    vec2 disc = vec2(dot(direction, right), dot(direction, up)) / moonRadius;
    float r2 = dot(disc, disc);
    if (r2 < 1.05 && moonDot > 0.0) {
        float phase = float(moonPhase) * 0.7853981634;
        vec3 sphereNormal = vec3(disc, sqrt(max(1.0 - r2, 0.0)));
        float light = dot(sphereNormal, vec3(sin(phase), 0.0, cos(phase)));
        float lit = smoothstep(-0.025, 0.025, light);
        float edge = 1.0 - smoothstep(1.0 - max(fwidth(r2), 0.001), 1.0, r2);
        vec3 moon = mix(vec3(0.016, 0.021, 0.034), vec3(0.47, 0.57, 0.75), lit);
        color = mix(color, moon, edge * (1.0 - rainStrength));
    }
    color += CELESTIAL_GLOW * (vec3(0.08, 0.045, 0.015) * pow(max(sunDot, 0.0), 1024.0)
            + vec3(0.008, 0.012, 0.025) * pow(max(moonDot, 0.0), 1024.0)) * (1.0 - rainStrength);
#endif
    return color;
}
#endif
