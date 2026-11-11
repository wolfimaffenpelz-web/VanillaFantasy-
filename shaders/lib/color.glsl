#ifndef WF_COLOR
#define WF_COLOR
vec3 wfLinear(vec3 c) {
    return pow(max(c, vec3(0.0)), vec3(2.2));
}
vec3 wfDisplay(vec3 c) {
    c = max(c * BRIGHTNESS, vec3(0.0));
    float luma = dot(c, vec3(0.2126, 0.7152, 0.0722));
    c = max(mix(vec3(luma), c, SATURATION), vec3(0.0));
    // Exponential shoulder approaches white without clipping ordinary HDR
    // highlights. Apply saturation first so it cannot push the result over one.
    c = vec3(1.0) - exp(-1.15 * c);
    return pow(clamp(c, 0.0, 1.0), vec3(1.0 / 2.2));
}
#endif
