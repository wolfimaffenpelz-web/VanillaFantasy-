#ifndef WF_GLARE_LIB
#define WF_GLARE_LIB
flat in float wfSunVisibility;
vec3 wfSunGlare(vec3 color, vec3 viewRay) {
#if SUN_GLARE == 1 && WF_DIMENSION == 0
    float alignment = max(dot(viewRay, wfSunDir()), 0.0);
    float veil = 0.45 * pow(alignment, 32.0) + 1.30 * pow(alignment, 192.0);
    color += vec3(1.0, 0.78, 0.45) * veil * wfSunVisibility * SUN_GLARE_STRENGTH;
#endif
    return color;
}
#endif
