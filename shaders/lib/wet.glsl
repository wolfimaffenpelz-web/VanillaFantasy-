#ifndef WF_WET_LIB
#define WF_WET_LIB
vec3 wfWet(vec3 color, vec3 position, vec3 normal, float skyLight) {
#if WET_SURFACES == 1 && WF_DIMENSION == 0
    float amount = wetness * smoothstep(0.65, 0.95, skyLight) * smoothstep(0.7, 0.98, normal.y);
    vec3 reflected = reflect(wfNormalize(position), normal);
    float glint = pow(max(dot(reflected, wfSunDir()), 0.0), 64.0) * wfDay();
    // Uniform wet sheen on exposed upward faces; no claimed puddle geometry.
    color = color * (1.0 - 0.08 * amount) + (wfSky(reflected) * 0.10 + glint * 0.2) * amount;
#endif
    return color;
}
#endif
