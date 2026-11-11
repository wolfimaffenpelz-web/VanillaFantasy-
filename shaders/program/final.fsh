#include "/lib/options.glsl"
#include "/lib/color.glsl"
#include "/lib/uniforms.glsl"
uniform sampler2D depthtex0;
uniform sampler2D colortex0;
const int colortex0Format = RGBA16F;
in vec2 wfTex;
void main() {
    vec3 color = texture(colortex0, wfTex).rgb;
    if (isEyeInWater == 1) {
        float depth = texture(depthtex0, wfTex).r;
        vec4 view = gbufferProjectionInverse * vec4(wfTex * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
        float distanceToSurface = min(length(view.xyz / max(abs(view.w), 1e-6)), 96.0);
        vec3 transmission = exp(-vec3(0.060, 0.026, 0.017) * distanceToSurface / UNDERWATER_CLARITY);
        // Retain the camera biome's fog tint; do not turn all water saturated blue.
        vec3 underwaterTint = max(wfLinear(fogColor), vec3(0.015, 0.035, 0.040));
        color = color * transmission + underwaterTint * (1.0 - transmission);
    }
    gl_FragColor = vec4(wfDisplay(color), 1.0);
}
