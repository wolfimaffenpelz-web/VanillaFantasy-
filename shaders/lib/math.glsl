#ifndef WF_MATH
#define WF_MATH
vec3 wfNormalize(vec3 v) { return v * inversesqrt(max(dot(v, v), 1e-12)); }
float wfLuma(vec3 v) { return dot(v, vec3(0.2126, 0.7152, 0.0722)); }
vec3 wfSunDir() { return wfNormalize(mat3(gbufferModelViewInverse) * sunPosition); }
vec3 wfMoonDir() { return wfNormalize(mat3(gbufferModelViewInverse) * moonPosition); }
float wfDay() { return smoothstep(-0.08, 0.12, wfSunDir().y); }
float wfBlockLevel(float coord) { return clamp((coord * 16.0 - 0.5) / 15.0, 0.0, 1.0); }
// Level 0 gives exactly zero extra blocklight; every positive level adds light.
float wfBlockCurve(float level) {
    level = clamp(level, 0.0, 1.0);
    return 0.16 * pow(level, 0.65) + 1.15 * pow(level, 1.7);
}
#endif
