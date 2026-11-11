#include "/lib/options.glsl"
#include "/lib/color.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/math.glsl"
#include "/lib/sky.glsl"
#include "/lib/glare.glsl"
#include "/lib/water_blend.glsl"
uniform sampler2D colortex0;
/* Iris metadata: format names are not GLSL constants.
const int colortex0Format = RGBA16F;
*/
#if WATER_BIOME_BLEND > 0
/* Iris metadata; water tint and response must not be alpha-blended.
const int colortex1Format = RGBA16F;
const int colortex2Format = RGBA16F;
*/
const vec4 colortex1ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const vec4 colortex2ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
#endif
in vec2 wfTex;
void main() {
    vec3 color = wfBlendWaterBiomes(texture(colortex0, wfTex).rgb, wfTex);
#if BLOOM == 1
    vec2 pixel = 1.0 / max(vec2(viewWidth, viewHeight), vec2(1.0));
    vec3 bloom = vec3(0.0);
    for (int i = 0; i < 8; ++i) {
        float angle = float(i) * 0.7853981634;
        vec2 offset = vec2(cos(angle), sin(angle)) * pixel * (4.0 + float(i % 2) * 3.0);
        vec3 sampleColor = texture(colortex0, wfTex + offset).rgb;
        bloom += sampleColor * max(wfLuma(sampleColor) - 0.9, 0.0) / max(wfLuma(sampleColor), 0.001);
    }
    color += bloom * (BLOOM_STRENGTH / 8.0);
#endif
#if WF_DIMENSION != 0
    // Nether/End may not draw a sky dome: replace only untouched background.
    if (texture(depthtex0, wfTex).r >= 0.999999 && isEyeInWater == 0) {
        vec4 ray = gbufferProjectionInverse * vec4(wfTex * 2.0 - 1.0, 1.0, 1.0);
        color = wfSky(wfNormalize(mat3(gbufferModelViewInverse) * ray.xyz));
    }
#endif
    if (isEyeInWater == 1) {
        float depth = texture(depthtex0, wfTex).r;
        vec4 view = gbufferProjectionInverse * vec4(wfTex * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
        float distanceToSurface = min(length(view.xyz / max(abs(view.w), 1e-6)), 96.0);
        vec3 transmission = exp(-vec3(0.060, 0.026, 0.017) * distanceToSurface / UNDERWATER_CLARITY);
        // Retain the camera biome's fog tint; do not turn all water saturated blue.
        vec3 underwaterTint = max(wfLinear(fogColor), vec3(0.015, 0.035, 0.040));
        color = color * transmission + underwaterTint * (1.0 - transmission);
    }
    vec4 viewRay = gbufferProjectionInverse * vec4(wfTex * 2.0 - 1.0, 1.0, 1.0);
    vec3 worldRay = wfNormalize(mat3(gbufferModelViewInverse) * viewRay.xyz);
    color = wfSunGlare(color, worldRay);
    gl_FragColor = vec4(wfDisplay(color), 1.0);
}
